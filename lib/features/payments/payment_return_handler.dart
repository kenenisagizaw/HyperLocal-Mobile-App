import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'payment_return_screen.dart';

class PaymentReturnHandler extends StatefulWidget {
  const PaymentReturnHandler({super.key, required this.child});

  final Widget child;

  @override
  State<PaymentReturnHandler> createState() => _PaymentReturnHandlerState();
}

class _PaymentReturnHandlerState extends State<PaymentReturnHandler> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  String? _lastHandledTxRef;

  @override
  void initState() {
    super.initState();
    _listenForLinks();
  }

  Future<void> _listenForLinks() async {
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      _handleLink(initial);
    }
    _subscription = _appLinks.uriLinkStream.listen(_handleLink);
  }

  void _handleLink(Uri uri) {
    if (uri.scheme != 'myapp' || uri.host != 'payment') {
      return;
    }
    if (uri.path != '/chapa/callback') {
      return;
    }

    final txRef =
        uri.queryParameters['tx_ref'] ?? uri.queryParameters['txRef'] ?? '';
    if (txRef.isEmpty || txRef == _lastHandledTxRef) {
      return;
    }
    _lastHandledTxRef = txRef;

    final bookingId = uri.queryParameters['bookingId'];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentReturnScreen(
          txRef: txRef,
          bookingId: bookingId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
