import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
          let portalChannel = FlutterMethodChannel(name: "your.bundle.identifier/portal",
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
                    if let apiKey = call.arguments as? String {
                        PortalWrapper.initializePortal(apiKey: apiKey, result: result)
                    } else {
                        result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected a String for apiKey, \(call.arguments)", details: nil))
                    }
                    
                case "createWallet":
                    PortalWrapper.createWallet(result: result)
                    
                // TODO: - Handle all the messages here.

                default:
                    result(FlutterMethodNotImplemented)
                }
            }
        }
    }
}
