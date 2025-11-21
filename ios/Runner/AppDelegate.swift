import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
          let portalChannel = FlutterMethodChannel(name: "portal_flutter/portal",
                                                    binaryMessenger: controller.binaryMessenger)
          
          setCallHandler(channel: portalChannel)
      
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

    private func setCallHandler(
        channel: FlutterMethodChannel
    ) {
        channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            Task {
                switch call.method {
                case "initializePortal":
                    print(call.arguments)
                    if let args = call.arguments as? [String: Any],
                       let apiKey = args["apiKey"] as? String {
                        PortalWrapper.initializePortal(apiKey: apiKey, rpcConfig: args["rpcConfig"] as? [String: String] ?? [:], autoApprove: args["autoApprove"] as? Bool ?? true, result: result)
                    } else {
                        result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected proper arguments for initializePortal", details: nil))
                    }
                    
                case "createWallet":
                    PortalWrapper.createWallet(result: result)
                    
                case "isPasswordRecoverAvailable":
                    PortalWrapper.isPasswordRecoverAvailable(result: result)
                    
                case "setPassword":
                    print("✅ setPassword invoked: \(call.arguments)")
                    if let password = call.arguments as? String {
                        PortalWrapper.setPassword(password: password, result: result)
                    } else {
                        result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected a String for password", details: nil))
                    }
                    
                case "backupWallet":
                    if let method = call.arguments as? String {
                        PortalWrapper.backupWallet(method: method, result: result)
                    } else {
                        result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected a String for backup method", details: nil))
                    }
                    
                case "recoverWallet":
                    if let method = call.arguments as? String {
                        PortalWrapper.recoverWallet(method: method, result: result)
                    } else {
                        result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected a String for recovery method", details: nil))
                    }


                case "swap":
                    if let args = call.arguments as? [String: Any],
                       let swapsApiKey = args["swapsApiKey"] as? String,
                       let chainId = args["chainId"] as? String,
                       let buyToken = args["buyToken"] as? String,
                       let sellToken = args["sellToken"] as? String,
                       let amount = args["amount"] as? String {
                        PortalWrapper.swap(swapsApiKey: swapsApiKey, chainId: chainId, buyToken: buyToken, sellToken: sellToken, amount: amount, result: result)
                    } else {
                        result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected proper arguments for swap", details:   nil))
                    }

                case "eject":
                    if let args = call.arguments as? [String: Any],
                       let method = args["backupMethod"] as? String,
                       let custodianApiKey = args["custodianApiKey"] as? String {
                        PortalWrapper.eject(backupMethod: method, custodianApiKey: custodianApiKey, result: result)
                    } else {
                        result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected proper arguments for eject", details: nil))
                    }

                case "sendAsset":
                    if let args = call.arguments as? [String: Any],
                       let chainId = args["chainId"] as? String,
                       let to = args["to"] as? String,
                       let amount = args["amount"] as? String {
                        let token = args["token"] as? String ?? "NATIVE"
                        let signatureApprovalMemo = args["signatureApprovalMemo"] as? String
                        PortalWrapper.sendAsset(chainId: chainId, to: to, amount: amount, token: token, signatureApprovalMemo: signatureApprovalMemo, result: result)
                    } else {
                        result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected proper arguments for sendAsset", details: nil))
                    }

                case "receiveTestnetAsset":
                    if let args = call.arguments as? [String: Any],
                       let chainId = args["chainId"] as? String {
                        let amount = args["amount"] as? String ?? "0.001" // Default amount
                        let token = args["token"] as? String ?? "ETH" // Default token
                        PortalWrapper.receiveTestnetAsset(chainId: chainId, amount: amount, token: token, result: result)
                    } else {
                        result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected proper arguments for receiveTestnetAsset", details: nil))
                    }

                default:
                    result(FlutterMethodNotImplemented)
                }
            }
        }
    }
}
