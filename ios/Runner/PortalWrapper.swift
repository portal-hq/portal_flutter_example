//
//  PortalWrapper.swift
//  Runner
//
//  Created by Ahmed Ragab on 26/11/2024.
//

import Flutter
import PortalSwift

class PortalWrapper {
    static var portal: Portal?
    static var isPasswordRecoverAvailable: Bool = false
    
    // MARK: - Helper Methods
    
    static func mapBackupMethod(from method: String) -> BackupMethods {
        switch method.uppercased() {
        case "PASSWORD":
            return .Password
        case "GDRIVE":
            return .GoogleDrive
        case "ICLOUD":
            return .iCloud
        case "CUSTOM":
            return .local
        case "PASSKEY":
            return .Passkey
        case "UNKNOWN":
            return .Unknown
        default:
            return .Password
        }
    }
    
    // MARK: - Portal SDK Methods
    
    static func initializePortal(apiKey: String, rpcConfig: [String: String] = [:], autoApprove: Bool = true, result: @escaping FlutterResult) {
        // Initialize portal here using the portal iOS SDK
        Task {
            do {
                portal = try Portal(
                    apiKey,
                    withRpcConfig: rpcConfig,
                    autoApprove: autoApprove
                )
                
                // Check if password recovery is available
                let recoveryMethods = try await portal!.availableRecoveryMethods()
                isPasswordRecoverAvailable = recoveryMethods.contains(.Password)
                
                result([
                    "success": true,
                    "message": "Portal initialized"
                ])
            } catch {
                result(FlutterError(code: "FAILED",
                                    message: "Error registering portal with exception: \(error.localizedDescription)",
                                    details: nil))
            }
        }
    }
    
    static func createWallet(result: @escaping FlutterResult) {
        // Create wallet here using the portal iOS SDK
        guard let portal = portal else {
            result(FlutterError(code: "UNAVAILABLE",
                                message: "Portal is not initialized",
                                details: nil))
            return
        }
        
        Task {
            do {
                let (ethereum, solana) = try await portal.createWallet()
                
                result([
                    "success": true,
                    "addresses": [
                        "ethereum": ethereum,
                        "solana": solana
                    ]
                ])
            } catch {
                result(FlutterError(code: "FAILED",
                                    message: "Error creating portal wallet with exception: \(error.localizedDescription)",
                                    details: nil))
            }
        }
    }
    
    static func isPasswordRecoverAvailable(result: @escaping FlutterResult) {
        guard let portal = portal else {
            result(FlutterError(code: "UNAVAILABLE",
                                message: "Portal is not initialized",
                                details: nil))
            return
        }
        
        Task {
            do {
                let isPasswordRecoverAvailable = try await portal.availableRecoveryMethods().contains(.Password) ?? false
                result(isPasswordRecoverAvailable)
            } catch {
                result(FlutterError(code: "FAILED",
                                    message: "Error getting recovery methods: \(error.localizedDescription)",
                                    details: nil))
            }
        }
    }
    
    static func setPassword(password: String, result: @escaping FlutterResult) {
        guard let portal = portal else {
            result(FlutterError(code: "UNAVAILABLE",
                                message: "Portal is not initialized",
                                details: nil))
            return
        }
        
        Task {
            do {
                try portal.setPassword(password)
                result(["success": true])
            } catch {
                result(FlutterError(code: "FAILED",
                                    message: "Error setting password: \(error.localizedDescription)",
                                    details: nil))
            }
        }
    }
    
    static func backupWallet(method: String, result: @escaping FlutterResult) {
        guard let portal = portal else {
            result(FlutterError(code: "UNAVAILABLE",
                                message: "Portal is not initialized",
                                details: nil))
            return
        }
        
        Task {
            do {
                let backupMethod = mapBackupMethod(from: method)
                _ = try await portal.backupWallet(backupMethod)
                result(["success": true])
            } catch {
                result(FlutterError(code: "FAILED",
                                    message: "Error backing up wallet: \(error.localizedDescription)",
                                    details: nil))
            }
        }
    }
    
    static func recoverWallet(method: String, result: @escaping FlutterResult) {
        guard let portal = portal else {
            result(FlutterError(code: "UNAVAILABLE",
                                message: "Portal is not initialized",
                                details: nil))
            return
        }
        
        Task {
            do {
                let recoverMethod = mapBackupMethod(from: method)
                let wallets = try await portal.recoverWallet(recoverMethod)
                result([
                    "success": true,
                    "addresses": [
                        "ethereum": wallets.ethereum ?? "",
                        "solana": wallets.solana ?? ""
                    ]
                ])
            } catch {
                result(FlutterError(code: "FAILED",
                                    message: "Error recovering wallet: \(error.localizedDescription)",
                                    details: nil))
            }
        }
    }

    static func swap(swapsApiKey: String, chainId: String, buyToken: String, sellToken: String, amount: String, result: @escaping FlutterResult) {
        guard let portal = portal else {
            result(FlutterError(code: "UNAVAILABLE",
                                message: "Portal is not initialized",
                                details: nil))
            return
        }

        let swaps: PortalSwapsProtocol = PortalSwaps(apiKey: swapsApiKey, portal: portal)

        Task {

            let quoteArgs = QuoteArgs(
                buyToken: buyToken,
                sellToken: sellToken,
                sellAmount: amount
            )

            let quoteResult: Quote
            do {
                quoteResult = try await swaps.getQuote(args: quoteArgs, forChainId: chainId)
            } catch {
                result(FlutterError(code: "FAILED",
                                    message: "Unable to get quote with error: \(error.localizedDescription)",
                                    details: nil))
                return
            }

            do {
                let sendTransactionResponse = try await portal.request(
                    chainId,
                    withMethod: .eth_sendTransaction,
                    andParams: [quoteResult.transaction]
                )

                guard let transactionHash = sendTransactionResponse.result as? String else {
                    result(FlutterError(code: "FAILED",
                                        message: "Swap failed: Invalid response type for request",
                                        details: nil))
                    return
                }

                result([
                    "success": true,
                    "transactionHash": transactionHash
                ])
            } catch {
                result(FlutterError(code: "FAILED",
                                    message: "Swap failed: \(error.localizedDescription)",
                                    details: nil))
            }
        }
    }
    static func eject(backupMethod: String, custodianApiKey: String, result: @escaping FlutterResult) {
        guard let portal = portal else {
            result(FlutterError(code: "UNAVAILABLE",
                                message: "Portal is not initialized",
                                details: nil))
            return
        }
        
        Task {
            do {
                let method = mapBackupMethod(from: backupMethod)
                
                // 1. Get Wallet ID
                guard let walletId = try await getWalletId(for: method) else {
                    result(FlutterError(code: "FAILED",
                                        message: "Could not find wallet for backup method: \(backupMethod)",
                                        details: nil))
                    return
                }
                
                // 2. Prepare Eject (Call Portal API)
                try await prepareEject(walletId: walletId, custodianApiKey: custodianApiKey)
                
                // 3. Eject
                print("Attempting to eject private keys...")
                let privateKeys = try await portal.ejectPrivateKeys(method)
                print("Eject successful. Private Keys: \(privateKeys)")
                
                var mappedKeys: [String: String] = [:]

                if let keysDict = privateKeys as? [PortalNamespace: String] {
                    for (namespace, key) in keysDict {
                        mappedKeys[namespace.rawValue] = key
                    }
                    result(mappedKeys)
                } else {
                    let description = String(describing: privateKeys)
                    result(description)
                }
            } catch {
                print("Eject failed with error: \(error)")
                result(FlutterError(code: "FAILED",
                                    message: "Error ejecting wallet: \(error.localizedDescription)",
                                    details: nil))
            }
        }
    }
    
    private static func getWalletId(for method: BackupMethods) async throws -> String? {
        guard let portal = portal else { return nil }
        guard let client = try await portal.client else { return nil }
        
        for wallet in client.wallets {
            if wallet.curve == .SECP256K1 {
                for backupSharePair in wallet.backupSharePairs {
                    if backupSharePair.status == .completed, backupSharePair.backupMethod == method {
                        return wallet.id
                    }
                }
            }
        }
        return nil
    }

    private static func prepareEject(walletId: String, custodianApiKey: String) async throws {
        guard let portal = portal else { return }
        guard let client = try await portal.client else {
            throw NSError(domain: "PortalWrapper", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not get Client"])
        }
        let clientId = client.id
        
        let urlString = "https://api.portalhq.io/api/v3/custodians/me/clients/\(clientId)/prepare-eject"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "PortalWrapper", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(custodianApiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["walletId": walletId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            let responseBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "PortalWrapper", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Prepare Eject Failed: \(responseBody)"])
        }
    }
    static func sendAsset(chainId: String, to: String, amount: String, token: String, signatureApprovalMemo: String?, result: @escaping FlutterResult) {
        guard let portal = portal else {
            result(FlutterError(code: "UNAVAILABLE",
                                message: "Portal is not initialized",
                                details: nil))
            return
        }
        
        Task {
            do {
                let params = SendAssetParams(
                    to: to,
                    amount: amount,
                    token: token,
                    signatureApprovalMemo: signatureApprovalMemo
                )
                
                let response = try await portal.sendAsset(chainId: chainId, params: params)
                
                result([
                    "success": true,
                    "transactionHash": response.txHash
                ])
            } catch {
                result(FlutterError(code: "FAILED",
                                    message: "Error sending asset: \(error.localizedDescription)",
                                    details: nil))
            }
        }
    }
    
    static func receiveTestnetAsset(chainId: String, amount: String, token: String, result: @escaping FlutterResult) {
        guard let portal = portal else {
            result(FlutterError(code: "UNAVAILABLE",
                                message: "Portal is not initialized",
                                details: nil))
            return
        }
        
        Task {
            do {
                let params = FundParams(amount: amount, token: token)
                let response = try await portal.receiveTestnetAsset(chainId: chainId, params: params)
                
                if let data = response.data {
                    result([
                        "success": true,
                        "transactionHash": data.txHash
                    ])
                } else {
                    result(FlutterError(code: "FAILED",
                                        message: "Error receiving testnet asset: \(response.error?.message ?? "Unknown error")",
                                        details: nil))
                }
            } catch {
                result(FlutterError(code: "FAILED",
                                    message: "Error receiving testnet asset: \(error.localizedDescription)",
                                    details: nil))
            }
        }
    }
}
