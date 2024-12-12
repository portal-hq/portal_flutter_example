package com.example.portal_flutter

import android.os.Bundle
import android.util.Log
import androidx.lifecycle.lifecycleScope
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.portalhq.android.Portal
import io.portalhq.android.data.CreateWalletsResponse
import io.portalhq.android.mpc.data.FeatureFlags
import io.portalhq.android.storage.mobile.PortalNamespace
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {
    private lateinit var portal: Portal
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, Constants.FLUTTER_CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                Log.d("Flutter", "Method call: ${call.method}")
                println("Flutter: Method call: ${call.method}")
                handleFlutterMethodCall(call, result)
            }
    }

    private fun handleFlutterMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            Constants.METHOD_INITIALIZE_PORTAL -> initializePortal(call.arguments, result)

            Constants.METHOD_CREATE_WALLET -> createWallet(result)
        }
    }

    private fun initializePortal(arguments: Any?, result: MethodChannel.Result) {
        if (arguments == null || arguments !is String || arguments.isBlank()) {
            result.error("FAILED", "Missing argument apiKey", null)
            return
        }

        try {
            portal = Portal(
                apiKey = arguments,
                featureFlags = FeatureFlags(isMultiBackupEnabled = true)
            )
            result.success("Portal initialized")
        } catch (e: Exception) {
            result.error("FAILED", e.message, null)
        }
    }

    private fun createWallet(result: MethodChannel.Result) {
        if (!this::portal.isInitialized) {
            result.error("FAILED", "Portal not initialized", null)
            return
        }

        lifecycleScope.launch {
            val createWalletResult = withContext(Dispatchers.IO) {
                if (portal.isWalletOnDevice()) {
                    Result.success(
                        CreateWalletsResponse(
                            ethereumAddress = portal.requireAddress(PortalNamespace.EIP155),
                            solanaAddress = portal.requireAddress(PortalNamespace.SOLANA)
                        )
                    )
                } else {
                    portal.createWallet()
                }
            }
            if (createWalletResult.isSuccess) {
                val wallet = createWalletResult.getOrThrow()
                val addressesMap = mapOf(
                    "ethereum" to wallet.ethereumAddress,
                    "solana" to wallet.solanaAddress
                )
                result.success(mapOf("addresses" to addressesMap))
            } else {
                result.error("FAILED", createWalletResult.exceptionOrNull()?.message, null)
            }
        }
    }
}
