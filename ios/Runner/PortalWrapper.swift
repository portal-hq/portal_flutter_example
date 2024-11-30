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
    
    static func initializePortal(apiKey: String, result: @escaping FlutterResult) {
        // Initialize portal here using the portal iOS SDK
        Task {
            do {
                portal = try Portal(
                    apiKey,
                    withRpcConfig: [
                        "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp" : "https://api.mainnet-beta.solana.com",
                        "solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1": "https://api.devnet.solana.com"
                    ]
                )
                
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
}
