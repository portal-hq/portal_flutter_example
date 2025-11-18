import 'package:flutter/material.dart';
import 'theme.dart';

enum ButtonStyle {
  primary,
  secondary,
}

/// Reusable button Widget matching
class PortalButton extends StatelessWidget {
  final String? title;
  final ButtonStyle style;
  final VoidCallback? onPress;
  final double cornerRadius;
  final double? width;
  final double? height;

  const PortalButton({
    Key? key,
    this.title,
    this.style = ButtonStyle.primary,
    this.onPress,
    this.cornerRadius = 12,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPress,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getBackgroundColor(style),
          foregroundColor: _getForegroundColor(style),
          elevation: style == ButtonStyle.secondary ? 3 : 2,
          shadowColor: PortalColors.portalBlue.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius),
            side: style == ButtonStyle.secondary 
                ? const BorderSide(color: PortalColors.portalBlue, width: 2.0)
                : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: Text(
          title ?? "",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(ButtonStyle style) {
    switch (style) {
      case ButtonStyle.primary:
        return PortalColors.portalBlue;
      case ButtonStyle.secondary:
        return PortalColors.portalGrayLight;
    }
  }

  Color _getForegroundColor(ButtonStyle style) {
    switch (style) {
      case ButtonStyle.primary:
        return PortalColors.portalWhite;
      case ButtonStyle.secondary:
        return PortalColors.portalBlue;
    }
  }
}

/// Reusable Leading Text Widget matching
class LeadingText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const LeadingText(
    this.text, {
    Key? key,
    this.style,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: style,
            maxLines: maxLines,
            overflow: overflow ?? TextOverflow.visible,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class PortalInitializedView extends StatefulWidget {
  final bool isRecoverAvailable;
  final VoidCallback? onGenerateWalletClicked;
  final Function(String)? onRecoverWalletClicked;

  const PortalInitializedView({
    Key? key,
    required this.isRecoverAvailable,
    this.onGenerateWalletClicked,
    this.onRecoverWalletClicked,
  }) : super(key: key);

  @override
  State<PortalInitializedView> createState() => _PortalInitializedViewState();
}

class _PortalInitializedViewState extends State<PortalInitializedView> {
  bool showPasswordAlert = false;
  String recoverPassword = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.isRecoverAvailable
                ? "Wallet is available on the device. Recover it to continue!"
                : "No wallet is available on the device. Let's create one!",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: PortalColors.portalGrayDark,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          
          PortalButton(
            title: "Generate",
            onPress: widget.onGenerateWalletClicked,
            width: 200,
            height: 45,
          ),
          
          if (widget.isRecoverAvailable) ...[
            const SizedBox(height: 10),
            PortalButton(
              title: "Recover Wallet",
              style: ButtonStyle.secondary,
              onPress: () {
                setState(() {
                  showPasswordAlert = true;
                });
              },
              width: 200,
              height: 45,
            ),
          ],
          
          if (showPasswordAlert) _buildPasswordAlert(),
        ],
      ),
    );
  }

  Widget _buildPasswordAlert() {
    return AlertDialog(
      title: const Text("Enter Password"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            onChanged: (value) {
              recoverPassword = value;
            },
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "PASSWORD",
              hintText: "Enter password",
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              showPasswordAlert = false;
            });
          },
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onRecoverWalletClicked?.call(recoverPassword);
            setState(() {
              showPasswordAlert = false;
            });
          },
          child: const Text("Submit"),
        ),
      ],
    );
  }
}

class PortalWalletView extends StatefulWidget {
  final String solanaAddress;
  final String? ethereumAddress;
  final VoidCallback? onCopyAddressClick;
  final VoidCallback? onCopyEthereumAddressClick;
  final Function(String)? onBackupWalletClick;
  final Function(String)? onEjectWalletClick;
  final Function(String buyToken, String sellToken, String amount)? onSwapClick;
  final bool isSwapLoading;

  const PortalWalletView({
    Key? key,
    required this.solanaAddress,
    this.ethereumAddress,
    this.onCopyAddressClick,
    this.onCopyEthereumAddressClick,
    this.onBackupWalletClick,
    this.onEjectWalletClick,
    this.onSwapClick,
    this.isSwapLoading = false,
  }) : super(key: key);

  @override
  State<PortalWalletView> createState() => _PortalWalletViewState();
}

class _PortalWalletViewState extends State<PortalWalletView> {
  bool showPasswordAlert = false;
  String backupPassword = '';
  bool showEjectAlert = false;
  String ejectPassword = '';
  bool showSwapAlert = false;
  String buyToken = 'USDC';
  String sellToken = 'ETH';
  String amount = '10000000000000';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Header with Wallet title and Backup button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Addresses:",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: PortalColors.portalBlue,
                ),
              ),
              PortalButton(
                title: "Backup Wallet",
                style: ButtonStyle.secondary,
                onPress: () {
                  setState(() {
                    showPasswordAlert = true;
                  });
                },
                width: 160,
                height: 45,
                cornerRadius: 22.5,
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Eject Button
          Align(
            alignment: Alignment.centerRight,
            child: PortalButton(
              title: "Eject Wallet",
              style: ButtonStyle.secondary,
              onPress: () {
                setState(() {
                  showEjectAlert = true;
                });
              },
              width: 160,
              height: 45,
              cornerRadius: 22.5,
            ),
          ),
          const SizedBox(height: 10),

          // Wallet details
          Column(
            children: [
              // Solana Address section
              Row(
                children: [
                  const Text(
                    "SOLANA ADDRESS:",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: PortalColors.portalBlue,
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onCopyAddressClick,
                    icon: const Icon(Icons.copy),
                  ),
                  const Spacer(),
                ],
              ),
              LeadingText(
                widget.solanaAddress,
                style: const TextStyle(
                  fontSize: 16,
                  color: PortalColors.portalGrayDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),

              // Ethereum Address section
              if (widget.ethereumAddress != null) ...[
                Row(
                  children: [
                    const Text(
                      "ETHEREUM ADDRESS:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: PortalColors.portalBlue,
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onCopyEthereumAddressClick,
                      icon: const Icon(Icons.copy),
                    ),
                    const Spacer(),
                  ],
                ),
                LeadingText(
                  widget.ethereumAddress!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: PortalColors.portalGrayDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // Password alert
          if (showPasswordAlert) _buildPasswordAlert(),

          const SizedBox(height: 12),

          // Swap button
          Align(
            alignment: Alignment.center,
            child: widget.isSwapLoading
                ? const SizedBox(
                    width: 160,
                    height: 42,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(PortalColors.portalBlue),
                      ),
                    ),
                  )
                : PortalButton(
                    title: "Swap",
                    onPress: () {
                      setState(() {
                        showSwapAlert = true;
                      });
                    },
                    width: 160,
                    height: 42,
                    cornerRadius: 21,
                  ),
          ),

          if (showSwapAlert) _buildSwapAlert(),
          if (showEjectAlert) _buildEjectAlert(),
        ],
      ),
    );
  }

  Widget _buildPasswordAlert() {
    return AlertDialog(
      title: const Text("Enter Password"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            onChanged: (value) {
              backupPassword = value;
            },
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "PASSWORD",
              hintText: "Enter password",
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              showPasswordAlert = false;
            });
          },
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onBackupWalletClick?.call(backupPassword);
            setState(() {
              showPasswordAlert = false;
            });
          },
          child: const Text("Submit"),
        ),
      ],
    );
  }

  Widget _buildSwapAlert() {
    return AlertDialog(
      title: const Text("Swap"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (v) => buyToken = v,
              controller: TextEditingController(text: "USDC"),
              decoration: const InputDecoration(
                labelText: "Buy Token",
                hintText: "e.g. USDC",
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: (v) => sellToken = v,
              controller: TextEditingController(text: "ETH"),
              decoration: const InputDecoration(
                labelText: "Sell Token",
                hintText: "e.g. ETH",
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: (v) => amount = v,
              controller: TextEditingController(text: "10000000000000"),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount in Wei",
                hintText: "Enter amount in Wei",
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              showSwapAlert = false;
            });
          },
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: widget.isSwapLoading ? null : () async {
            try {
              await widget.onSwapClick?.call(buyToken, sellToken, amount);
              setState(() {
                showSwapAlert = false;
              });
            } catch (e) {
              // Error handling is done in the viewmodel
              setState(() {
                showSwapAlert = false;
              });
            }
          },
          child: widget.isSwapLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(PortalColors.portalBlue),
                  ),
                )
              : const Text("Submit"),
        ),
      ],
    );
  }
  Widget _buildEjectAlert() {
    return AlertDialog(
      title: const Text("Eject Wallet"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Enter your password to eject your private key."),
          const SizedBox(height: 10),
          TextField(
            onChanged: (value) {
              ejectPassword = value;
            },
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "PASSWORD",
              hintText: "Enter password",
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              showEjectAlert = false;
            });
          },
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onEjectWalletClick?.call(ejectPassword);
            setState(() {
              showEjectAlert = false;
            });
          },
          child: const Text("Eject"),
        ),
      ],
    );
  }
}


class PortalTransactionHashView extends StatelessWidget {
  final String transactionHash;
  final VoidCallback? onCopyTransactionHashClick;

  const PortalTransactionHashView({
    Key? key,
    required this.transactionHash,
    this.onCopyTransactionHashClick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                "RECENT TRANSACTION HASH:",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: PortalColors.portalBlue,
                ),
              ),
              IconButton(
                onPressed: onCopyTransactionHashClick,
                icon: const Icon(Icons.copy),
              ),
              const Spacer(),
            ],
          ),
          LeadingText(
            transactionHash,
            style: const TextStyle(
              fontSize: 16,
              color: PortalColors.portalGrayDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
