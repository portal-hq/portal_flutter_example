import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: PortalExample(),
    );
  }
}

class PortalExample extends StatefulWidget {
  @override
  _PortalExampleState createState() => _PortalExampleState();
}

class Wallet {
  final String ethereum;
  final String solana;

  Wallet({required this.ethereum, required this.solana});
}

class _PortalExampleState extends State<PortalExample> {
  static const platform = MethodChannel('your.bundle.identifier/portal');

  bool isInitialized = false;
  Wallet? wallet;
  bool isLoading = false; // Track loading state

  Future<void> initializePortal() async {
    setState(() {
      isLoading = true;
    });

    const apiKey = "API-KEY"; // TODO: - add the user API-KEY here for the example to work
    try {
      await platform.invokeMethod('initializePortal', apiKey);
      setState(() {
        isInitialized = true;
      });
    } on PlatformException catch (e) {
      print("Error initializing Portal SDK: ${e.message}");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> createWallet() async {
    setState(() {
      isLoading = true;
    });

    try {
      final addresses = await platform.invokeMethod('createWallet');
      setState(() {
        wallet = Wallet(
          ethereum: addresses["addresses"]["ethereum"],
          solana: addresses["addresses"]["solana"],
        );
      });
    } on PlatformException catch (e) {
      print("Error creating wallet: ${e.message}");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Portal SDK Example")),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator() // Show loader when loading
            : wallet != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Ethereum Address: ${wallet!.ethereum}"),
                      Text("Solana Address: ${wallet!.solana}"),
                    ],
                  )
                : isInitialized
                    ? ElevatedButton(
                        onPressed: createWallet,
                        child: const Text("Create Wallet"),
                      )
                    : ElevatedButton(
                        onPressed: initializePortal,
                        child: const Text("Initialize Portal"),
                      ),
      ),
    );
  }
}
