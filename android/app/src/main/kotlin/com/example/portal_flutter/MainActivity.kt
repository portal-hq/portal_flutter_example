package com.example.portal_flutter

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel


class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun onDestroy() {
        super.onDestroy()
        PortalWrapper.close()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, Constants.FLUTTER_CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                println("Flutter: Method call: ${call.method}")
                handleFlutterMethodCall(call, result)
            }
    }

    private fun handleFlutterMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            Constants.METHOD_INITIALIZE_PORTAL -> PortalWrapper.initializePortal(
                call.arguments,
                result
            )

            Constants.METHOD_CREATE_WALLET -> PortalWrapper.createWallet(result)
            Constants.METHOD_IS_PASSWORD_RECOVER_AVAILABLE -> PortalWrapper.isPasswordRecoverAvailable(
                result
            )

            Constants.METHOD_SET_PASSWORD -> PortalWrapper.setPassword(call.arguments, result)
            Constants.METHOD_BACKUP_WALLET -> PortalWrapper.backupWallet(call.arguments, result)
            Constants.METHOD_RECOVER_WALLET -> PortalWrapper.recoverWallet(call.arguments, result)
        }
    }

}
