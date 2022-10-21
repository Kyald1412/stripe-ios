//
//  FinancialConnectionsAPIClient.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 12/1/21.
//

import Foundation
@_spi(STP) import StripeCore

protocol FinancialConnectionsAPIClient {

    func generateSessionManifest(clientSecret: String, returnURL: String?) -> Promise<FinancialConnectionsSynchronize>

    func fetchFinancialConnectionsAccounts(clientSecret: String,
                                           startingAfterAccountId: String?) -> Promise<StripeAPI.FinancialConnectionsSession.AccountList>

    func fetchFinancialConnectionsSession(clientSecret: String) -> Promise<StripeAPI.FinancialConnectionsSession>
    
    func markConsentAcquired(clientSecret: String) -> Promise<FinancialConnectionsSessionManifest>
    
    func fetchFeaturedInstitutions(clientSecret: String) -> Promise<FinancialConnectionsInstitutionList>
    
    func fetchInstitutions(clientSecret: String, query: String) -> Promise<FinancialConnectionsInstitutionList>
    
    func createAuthorizationSession(clientSecret: String, institutionId: String) -> Promise<FinancialConnectionsAuthorizationSession>
    
    func cancelAuthSession(clientSecret: String, authSessionId: String) -> Promise<FinancialConnectionsAuthorizationSession>
    
    func fetchAuthSessionOAuthResults(clientSecret: String, authSessionId: String) -> Promise<FinancialConnectionsMixedOAuthParams>
    
    func authorizeAuthSession(clientSecret: String,
                              authSessionId: String,
                              publicToken: String?) -> Promise<FinancialConnectionsAuthorizationSession>
    
    func fetchAuthSessionAccounts(
        clientSecret: String,
        authSessionId: String,
        initialPollDelay: TimeInterval
    ) -> Future<FinancialConnectionsAuthorizationSessionAccounts>
    
    func selectAuthSessionAccounts(clientSecret: String,
                                   authSessionId: String,
                                   selectedAccountIds: [String]) -> Promise<FinancialConnectionsAuthorizationSessionAccounts>
    
    func markLinkingMoreAccounts(clientSecret: String) -> Promise<FinancialConnectionsSessionManifest>
    
    func completeFinancialConnectionsSession(clientSecret: String) -> Future<StripeAPI.FinancialConnectionsSession>
    
    func attachBankAccountToLinkAccountSession(
        clientSecret: String,
        accountNumber: String,
        routingNumber: String
    ) -> Future<FinancialConnectionsPaymentAccountResource>
    
    func attachLinkedAccountIdToLinkAccountSession(
        clientSecret: String,
        linkedAccountId: String,
        consumerSessionClientSecret: String?
    ) -> Future<FinancialConnectionsPaymentAccountResource>
}

extension STPAPIClient: FinancialConnectionsAPIClient {

    func fetchFinancialConnectionsAccounts(clientSecret: String,
                                           startingAfterAccountId: String?) -> Promise<StripeAPI.FinancialConnectionsSession.AccountList> {
        var parameters = ["client_secret": clientSecret]
        if let startingAfterAccountId = startingAfterAccountId {
            parameters["starting_after"] = startingAfterAccountId
        }
        return self.get(resource: APIEndpointListAccounts,
                        parameters: parameters)
    }

    func fetchFinancialConnectionsSession(clientSecret: String) -> Promise<StripeAPI.FinancialConnectionsSession> {
        return self.get(resource: APIEndpointSessionReceipt,
                        parameters: ["client_secret": clientSecret])
    }

//    func generateSessionManifest(clientSecret: String, returnURL: String?) -> Promise<FinancialConnectionsSessionManifest> {
//        let body = FinancialConnectionsSessionsGenerateHostedUrlBody(clientSecret: clientSecret, fullscreen: true, hideCloseButton: true, appReturnUrl: returnURL)
//        return self.post(resource: APIEndpointGenerateHostedURL,
//                         object: body)
//    }
    
    func generateSessionManifest(clientSecret: String, returnURL: String?) -> Promise<FinancialConnectionsSynchronize> {
        //        let body = FinancialConnectionsSessionsGenerateHostedUrlBody(clientSecret: clientSecret, fullscreen: true, hideCloseButton: true)
        return self.post(
            resource: "financial_connections/sessions/synchronize",
            parameters: [
                "client_secret": clientSecret,
                "mobile" : [
                    "sdk_type": "ios",
                    "fullscreen": true,
                    "hide_close_button": true,
                    "sdk_version": 1,
                ],
                "locale": "en-us", // Locale.current.identifier,
                // TODO: app return URL
            ]
        )
//        return self.post(resource: APIEndpointGenerateHostedURL,
//                         object: body)
    }
    
    func markConsentAcquired(clientSecret: String) -> Promise<FinancialConnectionsSessionManifest> {
        let body = FinancialConnectionsSessionsClientSecretBody(clientSecret: clientSecret)
        return self.post(resource: APIEndpointConsentAcquired, object: body)
    }

    func fetchFeaturedInstitutions(clientSecret: String) -> Promise<FinancialConnectionsInstitutionList> {
        let parameters = [
            "client_secret": clientSecret,
            "limit": "10"
        ]
        return self.get(resource: APIEndpointFeaturedInstitutions,
                        parameters: parameters)
    }
    
    func fetchInstitutions(clientSecret: String, query: String) -> Promise<FinancialConnectionsInstitutionList> {
        let parameters = [
            "client_secret": clientSecret,
            "query": query,
            "limit": "20"
        ]
        return self.get(resource: APIEndpointSearchInstitutions,
                        parameters: parameters)
    }
    
    func createAuthorizationSession(clientSecret: String, institutionId: String) -> Promise<FinancialConnectionsAuthorizationSession> {
        let body = [
            "client_secret": clientSecret,
            "institution": institutionId,
            "use_mobile_handoff": "false"
        ]
        return self.post(resource: APIEndpointAuthorizationSessions, object: body)
    }
    
    func cancelAuthSession(clientSecret: String, authSessionId: String) -> Promise<FinancialConnectionsAuthorizationSession> {
        let body = [
            "client_secret": clientSecret,
            "id": authSessionId,
        ]
        return self.post(resource: APIEndpointAuthorizationSessionsCancel, object: body)
    }
    
    func fetchAuthSessionOAuthResults(clientSecret: String, authSessionId: String) -> Promise<FinancialConnectionsMixedOAuthParams> {
        let body = [
            "client_secret": clientSecret,
            "id": authSessionId,
        ]
        return self.post(resource: APIEndpointAuthorizationSessionsOAuthResults, object: body)
    }
    
    func authorizeAuthSession(clientSecret: String,
                              authSessionId: String,
                              publicToken: String? = nil) -> Promise<FinancialConnectionsAuthorizationSession> {
        var body = [
            "client_secret": clientSecret,
            "id": authSessionId,
        ]
        body["public_token"] = publicToken // not all integrations require public_token
        return self.post(resource: APIEndpointAuthorizationSessionsAuthorized, object: body)
    }
    
    func fetchAuthSessionAccounts(
        clientSecret: String,
        authSessionId: String,
        initialPollDelay: TimeInterval
    ) -> Future<FinancialConnectionsAuthorizationSessionAccounts> {
        let body = [
            "client_secret": clientSecret,
            "id": authSessionId,
        ]
        let pollingHelper = APIPollingHelper(
            apiCall: { [weak self] in
                guard let self = self else {
                    return Promise(error: FinancialConnectionsSheetError.unknown(debugDescription: "STPAPIClient deallocated."))
                }
                return self.post(resource: APIEndpointAuthorizationSessionsAccounts, object: body)
            },
            pollTimingOptions: APIPollingHelper<FinancialConnectionsAuthorizationSessionAccounts>.PollTimingOptions(
                initialPollDelay: initialPollDelay
            )
        )
        return pollingHelper.startPollingApiCall()
    }
    
    func selectAuthSessionAccounts(clientSecret: String,
                                   authSessionId: String,
                                   selectedAccountIds: [String]) -> Promise<FinancialConnectionsAuthorizationSessionAccounts> {
        let body: [String: Any] = [
            "client_secret": clientSecret,
            "id": authSessionId,
            "selected_accounts": selectedAccountIds,
        ]
        return self.post(resource: APIEndpointAuthorizationSessionsSelectedAccounts, parameters: body)
    }
    
    func markLinkingMoreAccounts(clientSecret: String) -> Promise<FinancialConnectionsSessionManifest> {
        let body = [
            "client_secret": clientSecret,
        ]
        return self.post(resource: APIEndpointLinkMoreAccounts, object: body)
    }
    
    func completeFinancialConnectionsSession(clientSecret: String) -> Future<StripeAPI.FinancialConnectionsSession> {
        let body = [
            "client_secret": clientSecret,
        ]
        return self.post(resource: APIEndpointComplete, object: body)
            .chained { (session: StripeAPI.FinancialConnectionsSession) in
                if session.accounts.hasMore {
                    // de-paginate the accounts we get from the session because
                    // we want to give the clients a full picture of the number
                    // of accounts that were linked
                    let accountAPIFetcher = FinancialConnectionsAccountAPIFetcher(
                        api: self,
                        clientSecret: clientSecret
                    )
                    return accountAPIFetcher
                        .fetchAccounts(initial: session.accounts.data)
                        .chained { [accountAPIFetcher] accounts in
                            _ = accountAPIFetcher // retain `accountAPIFetcher` for the duration of the network call
                            return Promise(
                                value: StripeAPI.FinancialConnectionsSession(
                                    clientSecret: session.clientSecret,
                                    id: session.id,
                                    accounts: StripeAPI.FinancialConnectionsSession.AccountList(
                                        data: accounts,
                                        hasMore: false
                                    ),
                                    livemode: session.livemode,
                                    paymentAccount: session.paymentAccount,
                                    bankAccountToken: session.bankAccountToken
                                )
                            )
                        }
                } else {
                    return Promise(value: session)
                }
            }
    }
    
    func attachBankAccountToLinkAccountSession(
        clientSecret: String,
        accountNumber: String,
        routingNumber: String
    ) -> Future<FinancialConnectionsPaymentAccountResource> {
        return attachPaymentAccountToLinkAccountSession(
            clientSecret: clientSecret,
            accountNumber: accountNumber,
            routingNumber: routingNumber
        )
    }
    
    func attachLinkedAccountIdToLinkAccountSession(
        clientSecret: String,
        linkedAccountId: String,
        consumerSessionClientSecret: String?
    ) -> Future<FinancialConnectionsPaymentAccountResource> {
        return attachPaymentAccountToLinkAccountSession(
            clientSecret: clientSecret,
            linkedAccountId: linkedAccountId,
            consumerSessionClientSecret: consumerSessionClientSecret
        )
    }
    
    private func attachPaymentAccountToLinkAccountSession(
        clientSecret: String,
        accountNumber: String? = nil,
        routingNumber: String? = nil,
        linkedAccountId: String? = nil,
        consumerSessionClientSecret: String? = nil
    ) -> Future<FinancialConnectionsPaymentAccountResource> {
        var body: [String:Any] = [
            "client_secret": clientSecret,
        ]
        if let accountNumber = accountNumber, let routingNumber = routingNumber {
            body["type"] = "bank_account"
            body["bank_account"] = [
                "routing_number": routingNumber,
                "account_number": accountNumber,
            ]
        } else if let linkedAccountId = linkedAccountId {
            body["type"] = "linked_account"
            body["linked_account"] = [
                "id": linkedAccountId,
            ]
            body["consumer_session_client_secret"] = consumerSessionClientSecret // optional for Link
        } else {
            assertionFailure()
            return Promise(
                error: FinancialConnectionsSheetError
                    .unknown(debugDescription: "Invalid usage of \(#function).")
            )
        }
        
        let pollingHelper = APIPollingHelper(
            apiCall: { [weak self] in
                guard let self = self else {
                    return Promise(error: FinancialConnectionsSheetError.unknown(debugDescription: "STPAPIClient deallocated."))
                }
                return self.post(resource: APIEndpointAttachPaymentAccount, parameters: body)
            },
            pollTimingOptions: APIPollingHelper<FinancialConnectionsPaymentAccountResource>.PollTimingOptions(
                initialPollDelay: 1.0
            )
        )
        return pollingHelper.startPollingApiCall()
    }
}

private let APIEndpointListAccounts = "link_account_sessions/list_accounts"
private let APIEndpointAttachPaymentAccount = "link_account_sessions/attach_payment_account"
private let APIEndpointSessionReceipt = "link_account_sessions/session_receipt"
private let APIEndpointGenerateHostedURL = "link_account_sessions/generate_hosted_url"
private let APIEndpointConsentAcquired = "link_account_sessions/consent_acquired"
private let APIEndpointLinkMoreAccounts = "link_account_sessions/link_more_accounts"
private let APIEndpointComplete = "link_account_sessions/complete"
private let APIEndpointFeaturedInstitutions = "connections/featured_institutions"
private let APIEndpointSearchInstitutions = "connections/institutions"
private let APIEndpointAuthorizationSessions = "connections/auth_sessions"
private let APIEndpointAuthorizationSessionsCancel = "connections/auth_sessions/cancel"
private let APIEndpointAuthorizationSessionsOAuthResults = "connections/auth_sessions/oauth_results"
private let APIEndpointAuthorizationSessionsAuthorized = "connections/auth_sessions/authorized"
private let APIEndpointAuthorizationSessionsAccounts = "connections/auth_sessions/accounts"
private let APIEndpointAuthorizationSessionsSelectedAccounts = "connections/auth_sessions/selected_accounts"
