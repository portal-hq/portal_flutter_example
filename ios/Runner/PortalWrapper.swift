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
}
