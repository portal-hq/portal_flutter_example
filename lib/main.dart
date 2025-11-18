import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'portal_wallet_viewmodel.dart';
import 'ui_components.dart';
import 'theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portal Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: PortalTheme.lightTheme,
      home: PortalHackathonKit(),
    );
  }
}

class PortalHackathonKit extends StatefulWidget {
  @override
  _PortalHackathonKitState createState() => _PortalHackathonKitState();
}

class _PortalHackathonKitState extends State<PortalHackathonKit> {
  // PortalWalletViewModel handles all the Portal Logic
  late PortalWalletViewModel portalWalletViewModel;

  // MARK: - properties
  // Removed recipientController and amountController as Send PYUSD functionality is removed

  @override
  void initState() {
    super.initState();
    portalWalletViewModel = PortalWalletViewModel();
  }

  @override
  void dispose() {
    portalWalletViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PortalColors.portalGrayLight,
      appBar: AppBar(
        title: const Text(
          "Portal Flutter Example",
          style: TextStyle(
            color: PortalColors.portalWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: PortalColors.portalBlue,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: portalWalletViewModel,
        builder: (context, child) {
          switch (portalWalletViewModel.state) {
            case WalletUIState.loading:
              // Loader
              return Column(
                children: [
                  // Portal Logo at the top
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/Portal-logo.svg',
                        width: 120,
                        height: 120,
                      ),
                    ),
                  ),
                  // Loading content
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading...'),
                        ],
                      ),
                    ),
                  ),
                ],
              );

            case WalletUIState.portalInitialized:
              // Generate or Recover Wallet View
              return Column(
                children: [
                  // Portal Logo at the top
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/Portal-logo.svg',
                        width: 120,
                        height: 120,
                      ),
                    ),
                  ),
                  // Portal Initialized View
                  Expanded(
                    child: PortalInitializedView(
                      isRecoverAvailable: portalWalletViewModel.isPasswordRecoverAvailable,
                      onGenerateWalletClicked: () {
                        portalWalletViewModel.generateWallet();
                      },
                      onRecoverWalletClicked: (password) {
                        portalWalletViewModel.recoverWallet(password);
                      },
                    ),
                  ),
                ],
              );

            case WalletUIState.generated:
              // Wallet Data View
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      // Portal Logo at the top
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/Portal-logo.svg',
                            width: 120,
                            height: 120,
                          ),
                        ),
                      ),
                      
                      PortalWalletView(
                        solanaAddress: portalWalletViewModel.solanaAddress ?? '',
                        ethereumAddress: portalWalletViewModel.ethereumAddress,
                        onCopyAddressClick: () {
                          portalWalletViewModel.copyAddress();
                        },
                        onCopyEthereumAddressClick: () {
                          portalWalletViewModel.copyEthereumAddress();
                        },
                        onBackupWalletClick: (password) {
                          portalWalletViewModel.backupWallet(password);
                        },
                          onEjectWalletClick: (password) async {
                          try {
                            final privateKeysString = await portalWalletViewModel.eject(password);
                            
                            String displayKey = privateKeysString;
                            
                            if (privateKeysString.contains("eip155")) {
                              final parts = privateKeysString.split(",");
                              for (final part in parts) {
                                if (part.contains("eip155")) {
                                  final keyPart = part.split(":")[1].trim();
                                  // Remove potential braces
                                  displayKey = keyPart.replaceAll("}", "").replaceAll("{", "").trim();
                                  break;
                                }
                              }
                            }
                            
                            // Append 0x if missing
                            if (!displayKey.startsWith("0x")) {
                              displayKey = "0x$displayKey";
                            }

                            if (context.mounted) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Private Key"),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "WARNING: Do not share this key with anyone!",
                                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text("Private Key (EIP-155):", style: TextStyle(fontWeight: FontWeight.bold)),
                                      Row(
                                        children: [
                                          Expanded(child: SelectableText(displayKey)),
                                          IconButton(
                                            icon: const Icon(Icons.copy),
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(text: displayKey));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Private key copied to clipboard")),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      const Text("Verify Address:", style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      const SelectableText(
                                        "https://toolkit.abdk.consulting/ethereum#recover-address,key-to-address",
                                        style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Close"),
                                    ),
                                  ],
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Eject failed: $e")),
                              );
                            }
                          }
                        },
                        onSwapClick: (buyToken, sellToken, amount) {
                          portalWalletViewModel.swap(buyToken, sellToken, amount);
                        },
                        isSwapLoading: portalWalletViewModel.isSwapLoading,
                      ),

                      const SizedBox(height: 30),

                      // The Sent transaction hash
                      if (portalWalletViewModel.transactionHash != null)
                        PortalTransactionHashView(
                          transactionHash: portalWalletViewModel.transactionHash!,
                          onCopyTransactionHashClick: () {
                            portalWalletViewModel.copyTransactionHash();
                          },
                        ),

                      // Bottom space
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );

            case WalletUIState.error:
              // Label to show the error
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      portalWalletViewModel.errorMessage ?? 'Unknown error',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        portalWalletViewModel.initializePortal();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
          }
        },
      ),
    );
  }
}
