import io.flutter.plugin.common.MethodChannel
import io.portalhq.android.Portal
import io.portalhq.android.data.CreateWalletsResponse
import io.portalhq.android.mpc.data.FeatureFlags
import io.portalhq.android.storage.mobile.PortalNamespace
import io.portalhq.android.mpc.data.BackupMethods
import io.portalhq.android.mpc.data.BackupConfigs
import io.portalhq.android.mpc.data.PasswordStorageConfig
import io.portalhq.android.utils.errors.MpcError
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext


object PortalWrapper {
    private lateinit var portal: Portal
    private var isPasswordRecoverAvailable: Boolean = false
    private var backupConfigs: BackupConfigs? = null

    private var coroutineScope = CoroutineScope(Job())

    fun initializePortal(arguments: Any?, result: MethodChannel.Result) {
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


        try {
            portal = Portal(
                apiKey = apiKey,
                featureFlags = FeatureFlags(isMultiBackupEnabled = true)
            )

            result.success(
                mapOf(
                    "success" to true,
                    "message" to "Portal initialized"
                )
            )
        } catch (e: Exception) {
            result.error("FAILED", "Error registering portal with exception: ${e.message}", null)
        }

    }

    fun createWallet(result: MethodChannel.Result) {
        if (!this::portal.isInitialized) {
            result.error("FAILED", "Portal not initialized", null)
            return
        }

        coroutineScope.launch {
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

    fun isPasswordRecoverAvailable(result: MethodChannel.Result) {
        if (!this::portal.isInitialized) {
            result.error("UNAVAILABLE", "Portal is not initialized", null)
            return
        }

        coroutineScope.launch {
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

    fun setPassword(arguments: Any?, result: MethodChannel.Result) {
        if (!this::portal.isInitialized) {
            result.error("UNAVAILABLE", "Portal is not initialized", null)
            return
        }

        if (arguments == null || arguments !is String) {
            result.error("FAILED", "Missing or invalid password", null)
            return
        }

        coroutineScope.launch {
            try {

                // Create and store backup configs for later use
                backupConfigs = BackupConfigs(PasswordStorageConfig(password = arguments))

                result.success(true)
            } catch (e: Exception) {
                result.error("FAILED", "Error setting password: ${e.message}", null)
            }
        }
    }

    fun backupWallet(arguments: Any?, result: MethodChannel.Result) {
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

        coroutineScope.launch {
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

    fun recoverWallet(arguments: Any?, result: MethodChannel.Result) {
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
        coroutineScope.launch {
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

                    result.success(
                        mapOf<String, Any>(
                            "success" to true,
                            "addresses" to addressesMap
                        )
                    )
                } else {
                    result.error("FAILED", "Wallet not found after recovery", null)
                }
            } catch (e: Exception) {
                result.error("FAILED", "Error recovering wallet: ${e.message}", null)
            }
        }
    }

    fun swap(arguments: Any?, result: MethodChannel.Result) {
        if (!this::portal.isInitialized) {
            result.error("UNAVAILABLE", "Portal is not initialized", null)
            return
        }

        if (arguments == null || arguments !is Map<*, *>) {
            result.error("FAILED", "Missing or invalid swap arguments", null)
            return
        }

        val args = arguments as Map<String, Any>
        val swapsApiKey = args["swapsApiKey"] as? String
        val chainId = args["chainId"] as? String
        val buyToken = args["buyToken"] as? String
        val sellToken = args["sellToken"] as? String
        val amount = args["amount"] as? String

        if (swapsApiKey.isNullOrBlank() || chainId.isNullOrBlank() || 
            buyToken.isNullOrBlank() || sellToken.isNullOrBlank() || amount.isNullOrBlank()) {
            result.error("FAILED", "Missing required swap parameters", null)
            return
        }

        // Dummy implementation that always fails immediately
        result.error("SWAP_NOT_SUPPORTED", "Swap functionality is not implemented on Android yet", null)
    }

    fun close() {
        coroutineScope.cancel()
    }
}