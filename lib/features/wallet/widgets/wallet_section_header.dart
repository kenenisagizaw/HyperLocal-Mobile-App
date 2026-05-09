import 'package:flutter/material.dart';

class WalletSectionHeader extends StatelessWidget {
  const WalletSectionHeader({
    super.key,
    required this.title,
    this.action,
  });

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}
