import 'package:flutter/material.dart';
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
