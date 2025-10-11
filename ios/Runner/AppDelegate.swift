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
                        PortalWrapper.initializePortal(apiKey: apiKey, rpcConfig: args["rpcConfig"] as? [String: String], autoApprove: args["autoApprove"] as? Bool ?? true, result: result)
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

                default:
                    result(FlutterMethodNotImplemented)
                }
            }
        }
    }
}
