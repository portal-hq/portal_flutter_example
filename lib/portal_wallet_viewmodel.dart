import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'constants.dart';

enum WalletUIState {
  loading,
  portalInitialized,
  generated,
  error,
}

class PortalWalletViewModel extends ChangeNotifier {
  // Portal instance
  static const platform = MethodChannel('portal_flutter/portal');
  
  // Properties matching Swift implementation
  String clientAPIKey = Constants.PORTAL_CLIENT_API_KEY;
  String swapsApiKey = Constants.SWAPS_API_KEY;
  String swapsChainId = "eip155:8453"; // Base
  bool isPasswordRecoverAvailable = false;
  String? solanaAddress;
  String? ethereumAddress;
  String? transactionHash;
  String? error;

  // UI State
  WalletUIState _state = WalletUIState.loading;
  String? _errorMessage;
  bool _isSwapLoading = false;

  WalletUIState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isSwapLoading => _isSwapLoading;

  PortalWalletViewModel() {
    initializePortal();
  }

  // MARK: - Initialize Portal
  Future<void> initializePortal() async {
    _setState(WalletUIState.loading);
    
    try {

      await platform.invokeMethod('initializePortal', {
        'apiKey': clientAPIKey,
        'autoApprove': true,
      });

      // Check if password recovery is available
      isPasswordRecoverAvailable = await platform.invokeMethod('isPasswordRecoverAvailable') ?? false;

      _setState(WalletUIState.portalInitialized);
      print("✅ Portal initialized.");
    } catch (e) {
      _errorMessage = "❌ Error initializing portal: ${e.toString()}";
      _setState(WalletUIState.error);
      print("❌ Error initializing portal: ${e.toString()}");
    }
  }

  // MARK: - Generate Wallet
  Future<void> generateWallet() async {
    _setState(WalletUIState.loading);

    try {
      final wallets = await platform.invokeMethod('createWallet');
      solanaAddress = wallets['addresses']['solana'];
      ethereumAddress = wallets['addresses']['ethereum'];
      print("✅ wallet created successfully - addresses: $wallets");

      _setState(WalletUIState.generated);
    } catch (e) {
      _setState(WalletUIState.portalInitialized);
      print("❌ Error generating wallet: ${e.toString()}\n Maybe this Client API key has wallet already generated, if that is the case you may recover or provide new Client API Key to generate new wallet.");
    }
  }

  // MARK: - Backup Wallet
  Future<void> backupWallet(String password) async {
    if (password.isEmpty) {
      print("❌ please enter valid password to continue.");
      return;
    }

    _setState(WalletUIState.loading);

    try {
      await platform.invokeMethod('setPassword', password);
      await platform.invokeMethod('backupWallet', 'Password');
      
      _refreshWalletUI();
      print("✅ Backup successfully.");
    } catch (e) {
      _refreshWalletUI();
      print("❌ Unable to backup the wallet with error: $e");
    }
  }

  // MARK: - Recover Wallet
  Future<void> recoverWallet(String password) async {
    if (password.isEmpty) {
      print("❌ please enter valid password to continue.");
      return;
    }

    _setState(WalletUIState.loading);

    try {
      await platform.invokeMethod('setPassword', password);
      final wallets = await platform.invokeMethod('recoverWallet', 'Password');
      
      print("✅ wallet recovered successfully - addresses: ${wallets}");
      solanaAddress = wallets['addresses']['solana'];
      ethereumAddress = wallets['addresses']['ethereum'];
      
      _setState(WalletUIState.generated);
    } catch (e) {
      _setState(WalletUIState.portalInitialized);
      print("❌ Unable to recover the wallet with error: $e");
    }
  }

  // MARK: - Eject Wallet
  Future<String> eject(String password) async {
    if (password.isEmpty) {
      print("❌ please enter valid password to continue.");
      throw Exception("Password cannot be empty");
    }

    _setState(WalletUIState.loading);

    try {
      await platform.invokeMethod('setPassword', password);
      final privateKeys = await platform.invokeMethod('eject', {
        'backupMethod': 'Password',
        'custodianApiKey': Constants.CUSTODIAN_API_KEY,
      });
      
      print("✅ Wallet ejected successfully. Keys: $privateKeys");
      _setState(WalletUIState.generated);
      return privateKeys.toString();
    } catch (e) {
      _setState(WalletUIState.generated);
      print("❌ Unable to eject the wallet with error: $e");
      rethrow;
    }
  }

  // MARK: - Swap
  Future<void> swap(String buyToken, String sellToken, String amount) async {
    _isSwapLoading = true;
    notifyListeners();
    
    try {
      final swapResult = await platform.invokeMethod('swap', {
        'swapsApiKey': swapsApiKey,
        'chainId': swapsChainId,
        'buyToken': buyToken,
        'sellToken': sellToken,
        'amount': amount,
      });

      print("✅ swap result: $swapResult");
      
      // Store transaction hash if available
      if (swapResult != null && swapResult is Map && swapResult['transactionHash'] != null) {
        transactionHash = swapResult['transactionHash'];
      }
    } catch (e) {
      print("❌ Swap failed: $e");
      rethrow;
    } finally {
      _isSwapLoading = false;
      notifyListeners();
    }
  }

  // MARK: - Send Asset
  Future<void> sendAsset(String to, String amount, String chainId, {String token = "NATIVE", String? signatureApprovalMemo}) async {
    _setState(WalletUIState.loading);
    
    try {
      final result = await platform.invokeMethod('sendAsset', {
        'chainId': chainId,
        'to': to,
        'amount': amount,
        'token': token,
        'signatureApprovalMemo': signatureApprovalMemo,
      });
      
      print("✅ sendAsset result: $result");
      
      if (result != null && result is Map && result['transactionHash'] != null) {
        transactionHash = result['transactionHash'];
      }
      
      _setState(WalletUIState.generated);
    } on PlatformException catch (e) {
      final cleanMessage = _extractErrorMessage(e.message);
      print("❌ Send Asset failed: $cleanMessage");
      error = cleanMessage;
      _setState(WalletUIState.generated);
    } catch (e) {
      print("❌ Send Asset failed: $e");
      error = e.toString();
      _setState(WalletUIState.generated);
    }
  }

  // MARK: - Receive Testnet Asset
  Future<void> receiveTestnetAsset(String chainId) async {
    _setState(WalletUIState.loading);
    
    try {
      final result = await platform.invokeMethod('receiveTestnetAsset', {
        'chainId': chainId,
      });
      
      print("✅ receiveTestnetAsset result: $result");
      
      if (result != null && result is Map && result['transactionHash'] != null) {
        transactionHash = result['transactionHash'];
      }
      
      _setState(WalletUIState.generated);
    } catch (e) {
      print("❌ Receive Testnet Asset failed: $e");
      _setState(WalletUIState.generated);
      rethrow;
    }
  }

  // MARK: - Copy Helpers
  Future<void> copyAddress() async {
    if (solanaAddress != null) {
      await Clipboard.setData(ClipboardData(text: solanaAddress!));
    }
  }

  Future<void> copyEthereumAddress() async {
    if (ethereumAddress != null) {
      await Clipboard.setData(ClipboardData(text: ethereumAddress!));
    }
  }

  Future<void> copyTransactionHash() async {
    if (transactionHash != null) {
      await Clipboard.setData(ClipboardData(text: transactionHash!));
    }
  }

  // MARK: - Private Helpers
  void _refreshWalletUI() {
    if (solanaAddress != null) {
      _setState(WalletUIState.generated);
    }
  }

  void _setState(WalletUIState newState) {
    _state = newState;
    notifyListeners();
  }

  String _extractErrorMessage(String? message) {
    if (message == null) return "Unknown error";
    
    // Try to extract "message: ..." part
    final messageRegex = RegExp(r'-message:\s*(.*?)(?:,|$)');
    final match = messageRegex.firstMatch(message);
    if (match != null && match.group(1) != null) {
      return match.group(1)!.trim();
    }
    
    return message;
  }
}
