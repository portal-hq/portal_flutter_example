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
import io.portalhq.android.mpc.data.BackupMethods
import io.portalhq.android.mpc.data.BackupConfigs
import io.portalhq.android.mpc.data.PasswordStorageConfig
import io.portalhq.android.utils.errors.MpcError
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {
    private lateinit var portal: Portal
    private var isPasswordRecoverAvailable: Boolean = false
    private var backupConfigs: BackupConfigs? = null
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
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
            Constants.METHOD_INITIALIZE_PORTAL -> initializePortal(call.arguments, result)
            Constants.METHOD_CREATE_WALLET -> createWallet(result)
            Constants.METHOD_IS_PASSWORD_RECOVER_AVAILABLE -> isPasswordRecoverAvailable(result)
            Constants.METHOD_SET_PASSWORD -> setPassword(call.arguments, result)
            Constants.METHOD_BACKUP_WALLET -> backupWallet(call.arguments, result)
            Constants.METHOD_RECOVER_WALLET -> recoverWallet(call.arguments, result)
        }
    }

    private fun initializePortal(arguments: Any?, result: MethodChannel.Result) {
        if (arguments == null || arguments !is Map<*, *>) {
            result.error("FAILED", "Missing or invalid arguments", null)
            return
        }

        val args = arguments as Map<String, Any>
        val apiKey = args["apiKey"] as? String ?: ""
        val autoApprove = args["autoApprove"] as? Boolean ?: true

        if (apiKey.isBlank()) {
            result.error("FAILED", "Missing apiKey", null)
            return
        }

        lifecycleScope.launch {
            try {
                portal = Portal(
                    apiKey = apiKey,
                    featureFlags = FeatureFlags(isMultiBackupEnabled = true)
                )
                
                result.success(mapOf(
                    "success" to true,
                    "message" to "Portal initialized"
                ))
            } catch (e: Exception) {
                result.error("FAILED", "Error registering portal with exception: ${e.message}", null)
            }
        }
    }

    private fun createWallet(result: MethodChannel.Result) {
        if (!this::portal.isInitialized) {
            result.error("FAILED", "Portal not initialized", null)
            return
        }

        lifecycleScope.launch {
            try {
                val createWalletResult = withContext(Dispatchers.IO) {
                    if (portal.isWalletOnDevice()) {
                        // Wallet exists locally, return existing addresses
                        Result.success(
                            CreateWalletsResponse(
                                ethereumAddress = portal.requireAddress(PortalNamespace.EIP155),
                                solanaAddress = portal.requireAddress(PortalNamespace.SOLANA)
                            )
                        )
                    } else {
                        // Try to create new wallet, but handle existing wallet case
                        try {
                            portal.createWallet()
                        } catch (e: Exception) {
                            if (e.message?.contains("Wallet Already Exists") == true) {
                                // Wallet exists on server but not locally, try to recover it
                                // For now, return error suggesting to use recover instead
                                throw Exception("Wallet already exists on server. Please use recover wallet instead.")
                            } else {
                                throw e
                            }
                        }
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
            } catch (e: Exception) {
                result.error("FAILED", e.message ?: "Unknown error occurred", null)
            }
        }
    }

    // MARK: - Portal SDK Methods

    private fun isPasswordRecoverAvailable(result: MethodChannel.Result) {
        if (!this::portal.isInitialized) {
            result.error("UNAVAILABLE", "Portal is not initialized", null)
            return
        }

        lifecycleScope.launch {
            try {
                isPasswordRecoverAvailable = withContext(Dispatchers.IO) {
                    portal.isWalletOnDevice()
                }
                result.success(isPasswordRecoverAvailable)
            } catch (e: Exception) {
                result.error("FAILED", "Error checking wallet backup status: ${e.message}", null)
            }
        }
    }

    private fun setPassword(arguments: Any?, result: MethodChannel.Result) {
        if (!this::portal.isInitialized) {
            result.error("UNAVAILABLE", "Portal is not initialized", null)
            return
        }

        if (arguments == null || arguments !is String) {
            result.error("FAILED", "Missing or invalid password", null)
            return
        }

        lifecycleScope.launch {
            try {
                
                // Create and store backup configs for later use
                backupConfigs = BackupConfigs(PasswordStorageConfig(password = arguments))
                
                result.success(true)
            } catch (e: Exception) {
                result.error("FAILED", "Error setting password: ${e.message}", null)
            }
        }
    }

    private fun backupWallet(arguments: Any?, result: MethodChannel.Result) {
        if (!this::portal.isInitialized) {
            result.error("UNAVAILABLE", "Portal is not initialized", null)
            return
        }

        if (arguments == null || arguments !is String) {
            result.error("FAILED", "Missing or invalid backup method", null)
            return
        }

        if (backupConfigs == null) {
            result.error("FAILED", "Password not set. Please call setPassword first.", null)
            return
        }

        lifecycleScope.launch {
            try {

                val (cipherText, _) = portal.backupWallet(
                    backupMethod = BackupMethods.Password,
                    backupConfigs = backupConfigs!!,
                ) { status ->
                    android.util.Log.println(
                        android.util.Log.INFO,
                        "[PortalFlutter]",
                        "Backup status: ${status.status} is done: ${status.done}",
                    )
                }

                if (cipherText.isEmpty()) {
                    throw Exception("No cipherText found.")
                }
                
                result.success(true)
            } catch (e: Exception) {
                result.error("FAILED", "Error backing up wallet: ${e.message}", null)
            }
        }
    }

    private fun recoverWallet(arguments: Any?, result: MethodChannel.Result) {
        if (!this::portal.isInitialized) {
            result.error("UNAVAILABLE", "Portal is not initialized", null)
            return
        }

        if (arguments == null || arguments !is String) {
            result.error("FAILED", "Missing or invalid recovery method", null)
            return
        }

        if (backupConfigs == null) {
            result.error("FAILED", "Password not set. Please call setPassword first.", null)
            return
        }

        lifecycleScope.launch {
            try {
                withContext(Dispatchers.IO) {
                    portal.recoverWallet(
                        null,
                        BackupMethods.Password,
                        backupConfigs = backupConfigs!!,
                    ) { status ->
                        android.util.Log.println(
                            android.util.Log.INFO,
                            "[PortalFlutter]",
                            "Recover status: ${status.status} is done: ${status.done}",
                        )
                    }
                }
                
                // After successful recovery, get the wallet addresses
                if (portal.isWalletOnDevice()) {
                    val ethereumAddress = portal.requireAddress(PortalNamespace.EIP155)
                    val solanaAddress = portal.requireAddress(PortalNamespace.SOLANA)
                    
                    val addressesMap = mapOf<String, String>(
                        "ethereum" to ethereumAddress,
                        "solana" to solanaAddress
                    )
                    
                    result.success(mapOf<String, Any>(
                        "success" to true,
                        "addresses" to addressesMap
                    ))
                } else {
                    result.error("FAILED", "Wallet not found after recovery", null)
                }
            } catch (e: Exception) {
                result.error("FAILED", "Error recovering wallet: ${e.message}", null)
            }
        }
    }
}
