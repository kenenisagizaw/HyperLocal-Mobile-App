import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../../../routes.dart';
import 'password_reset_deep_link_service.dart';

class PasswordResetLinkHandler extends StatefulWidget {
  const PasswordResetLinkHandler({super.key, required this.child});

  final Widget child;

  @override
  State<PasswordResetLinkHandler> createState() =>
      _PasswordResetLinkHandlerState();
}

class _PasswordResetLinkHandlerState extends State<PasswordResetLinkHandler> {
  final AppLinks _appLinks = AppLinks();
  final PasswordResetDeepLinkService _service =
      const PasswordResetDeepLinkService();
  StreamSubscription<Uri>? _subscription;
  String? _lastHandledToken;

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
    final token = _service.extractToken(uri);
    if (token == null || token == _lastHandledToken) {
      return;
    }
    _lastHandledToken = token;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamed(
        Routes.verifyResetToken,
        arguments: {'token': token},
      );
    });
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
