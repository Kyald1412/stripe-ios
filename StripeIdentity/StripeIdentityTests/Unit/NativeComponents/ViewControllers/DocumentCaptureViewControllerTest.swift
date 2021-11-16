//
//  DocumentCaptureViewControllerTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 11/11/21.
//

import Foundation
import XCTest
import AVKit
@_spi(STP) import StripeCore
@testable import StripeIdentity

final class DocumentCaptureViewControllerTest: XCTestCase {

    let mockCameraFeed = MockIdentityDocumentCameraFeed(
        imageFiles: CapturedImageMock.frontDriversLicense.url
    )

    var dataStore: VerificationSessionDataStore!
    var mockFlowController: VerificationSheetFlowControllerMock!
    var mockSheetController: VerificationSheetControllerMock!
    var mockDocumentScanner = DocumentScannerMock()

    static var mockPixelBuffer: CVPixelBuffer!

    override class func setUp() {
        super.setUp()
        mockPixelBuffer = CapturedImageMock.frontDriversLicense.image.convertToBuffer()
    }

    override func setUp() {
        super.setUp()
        dataStore = .init()
        mockFlowController = .init()
        mockSheetController = .init(
            flowController: mockFlowController,
            dataStore: dataStore
        )
    }

    func testInitialStateIDCard() {
        let vc = makeViewController(documentType: .idCard)
        verify(
            vc,
            expectedState: .interstitial(.idCardFront),
            isButtonDisabled: false,
            isScanning: false
        )
    }

    func testInitialStateLicense() {
        let vc = makeViewController(documentType: .drivingLicense)
        verify(
            vc,
            expectedState: .interstitial(.idCardFront),
            isButtonDisabled: false,
            isScanning: false
        )
    }

    func testTransitionFromInterstitialCardFront() {
        let vc = makeViewController(state: .interstitial(.idCardFront))
        vc.didTapButton()
        verify(
            vc,
            expectedState: .scanning(.idCardFront),
            isButtonDisabled: true,
            isScanning: true
        )
    }

    func testTransitionFromScanningCardFront() {
        let vc = makeViewController(state: .scanning(.idCardFront))
        // Mock that scanner is scanning
        vc.startScanning(for: .idCardFront)
        // Mock that scanner found something
        mockDocumentScanner.scanImagePromise.resolve(with: DocumentCaptureViewControllerTest.mockPixelBuffer)
        verify(
            vc,
            expectedState: .scanned(.idCardFront, UIImage()),
            isButtonDisabled: false
        )
        // Verify image started uploading
        XCTAssertNotNil(vc.frontUploadFuture)
    }

    func testTransitionFromScannedCardFront() {
        let vc = makeViewController(state: .scanned(.idCardFront, UIImage()))
        vc.didTapButton()
        verify(
            vc,
            expectedState: .interstitial(.idCardBack),
            isButtonDisabled: false,
            isScanning: false
        )
    }

    func testTransitionFromInterstitialCardBack() {
        let vc = makeViewController(state: .interstitial(.idCardBack))
        vc.didTapButton()
        verify(
            vc,
            expectedState: .scanning(.idCardBack),
            isButtonDisabled: true,
            isScanning: true
        )
    }

    func testTransitionFromScanningCardBack() {
        let vc = makeViewController(state: .scanning(.idCardBack))
        // Mock that scanner is scanning
        vc.startScanning(for: .idCardBack)
        // Mock that scanner found something
        mockDocumentScanner.scanImagePromise.resolve(with: DocumentCaptureViewControllerTest.mockPixelBuffer)
        verify(
            vc,
            expectedState: .scanned(.idCardBack, UIImage()),
            isButtonDisabled: false
        )
        // Verify image started uploading
        XCTAssertNotNil(vc.backUploadFuture)
    }

    func testTransitionFromScannedCardBack() {
        // NOTE: Setting mock upload promises so that we can test the VC state
        // before `saveDataAndTransition` finishes and the state is reset to
        // `scanned`, otherwise the promises will resolve immediately
        let mockFrontUploadFuture = Promise<VerificationSessionDataStore.DocumentImage?>()
        let mockBackUploadFuture = Promise<VerificationSessionDataStore.DocumentImage?>()

        let vc = makeViewController(state: .scanned(.idCardBack, UIImage()))
        vc.frontUploadFuture = mockFrontUploadFuture
        vc.backUploadFuture = mockBackUploadFuture
        vc.didTapButton()
        verify(
            vc,
            expectedState: .saving(lastImage: UIImage()),
            isButtonDisabled: true
        )
        // Mock that upload finishes
        mockFrontUploadFuture.resolve(with: nil)
        mockBackUploadFuture.resolve(with: nil)

        wait(for: [mockSheetController.didFinishSaveDataExp], timeout: 1)
        XCTAssertTrue(mockSheetController.didRequestSaveData)
    }

    func testInitialStatePassport() {
        let vc = makeViewController(documentType: .passport)
        verify(
            vc,
            expectedState: .interstitial(.passport),
            isButtonDisabled: false,
            isScanning: false
        )
    }

    func testTransitionFromInterstitialPassport() {
        let vc = makeViewController(state: .interstitial(.passport))
        vc.didTapButton()
        verify(
            vc,
            expectedState: .scanning(.passport),
            isButtonDisabled: true,
            isScanning: true
        )
    }

    func testTransitionFromScanningPassport() {
        let vc = makeViewController(state: .scanning(.passport))
        // Mock that scanner is scanning
        vc.startScanning(for: .passport)
        // Mock that scanner found something
        mockDocumentScanner.scanImagePromise.resolve(with: DocumentCaptureViewControllerTest.mockPixelBuffer)
        verify(
            vc,
            expectedState: .scanned(.passport, UIImage()),
            isButtonDisabled: false
        )
        // Verify image started uploading
        XCTAssertNotNil(vc.frontUploadFuture)
    }

    func testTransitionFromScannedPassport() {
        // NOTE: Setting mock upload promise so that we can test the VC state
        // before `saveDataAndTransition` finishes and the state is reset to
        // `scanned`, otherwise the promises will resolve immediately
        let mockFrontUploadFuture = Promise<VerificationSessionDataStore.DocumentImage?>()

        let vc = makeViewController(state: .scanned(.passport, UIImage()))
        vc.frontUploadFuture = mockFrontUploadFuture
        vc.didTapButton()
        verify(
            vc,
            expectedState: .saving(lastImage: UIImage()),
            isButtonDisabled: true
        )
        // Mock that upload finishes
        mockFrontUploadFuture.resolve(with: nil)

        wait(for: [mockSheetController.didFinishSaveDataExp], timeout: 1)
        XCTAssertTrue(mockSheetController.didRequestSaveData)
    }

    func testSaveDataAndTransition() {
        let mockFrontImage = VerificationSessionDataStore.DocumentImage(image: UIImage(), fileId: "front_id")
        let mockBackImage = VerificationSessionDataStore.DocumentImage(image: UIImage(), fileId: "back_id")
        let mockLastClassification = DocumentScanner.Classification.idCardBack

        // Mock that file has been captured and upload has begun
        let vc = makeViewController(documentType: .drivingLicense)
        vc.frontUploadFuture = Promise(value: mockFrontImage)
        vc.backUploadFuture = Promise(value: mockBackImage)

        // Request to save data
        vc.saveDataAndTransition(lastClassification: mockLastClassification, lastImage: mockBackImage.image)

        // Verify data saved and transitioned to next screen
        wait(for: [mockSheetController.didFinishSaveDataExp, mockFlowController.didTransitionToNextScreenExp], timeout: 1)

        // Verify dataStore updated
        XCTAssertEqual(dataStore.frontDocumentImage, mockFrontImage)
        XCTAssertEqual(dataStore.backDocumentImage, mockBackImage)

        // Verify state
        verify(
            vc,
            expectedState: .scanned(mockLastClassification, mockBackImage.image),
            isButtonDisabled: false,
            isScanning: false
        )
    }
}

private extension DocumentCaptureViewControllerTest {
    func verify(
        _ vc: DocumentCaptureViewController,
        expectedState: DocumentCaptureViewController.State,
        isButtonDisabled: Bool,
        isScanning: Bool? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(vc.state, expectedState, "state", file: file, line: line)
        XCTAssertEqual(vc.isButtonDisabled, isButtonDisabled, "isButtonDisabled", file: file, line: line)
        if let isScanning = isScanning {
            XCTAssertEqual(mockDocumentScanner.isScanning, isScanning, "isScanning", file: file, line: line)
        }
    }

    func makeViewController(
        documentType: DocumentCaptureViewController.DocumentType
    ) -> DocumentCaptureViewController {
        return .init(
            sheetController: mockSheetController,
            cameraFeed: mockCameraFeed,
            documentType: documentType,
            documentScanner: mockDocumentScanner
        )
    }

    func makeViewController(
        state: DocumentCaptureViewController.State
    ) -> DocumentCaptureViewController {
        return .init(
            initialState: state,
            sheetController: mockSheetController,
            cameraFeed: mockCameraFeed,
            documentType: .idCard,
            documentScanner: mockDocumentScanner
        )
    }
}

extension DocumentCaptureViewController.State: Equatable {
    public static func == (lhs: DocumentCaptureViewController.State, rhs: DocumentCaptureViewController.State) -> Bool {
        switch (lhs, rhs) {
        case (.interstitial(let left), .interstitial(let right)),
             (.scanning(let left), .scanning(let right)),
             (.scanned(let left, _), .scanned(let right, _)):
            return left == right
        case (.saving, .saving):
            return true
        default:
            return false
        }
    }
}