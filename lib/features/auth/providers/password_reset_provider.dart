import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/error_utils.dart';
import '../models/password_reset_models.dart';
import '../repositories/password_reset_repository.dart';

class PasswordResetProvider extends ChangeNotifier {
  PasswordResetProvider({required PasswordResetRepository repository})
    : _repository = repository;

  static const int resendCooldownSeconds = 60;

  final PasswordResetRepository _repository;

  bool isLoading = false;
  bool isVerifying = false;
  String? errorMessage;
  String? lastSuccessMessage;
  int? lastStatusCode;
  String? _verifiedToken;
  String? _lastEmail;
  int _resendSecondsRemaining = 0;
  Timer? _resendTimer;

  String? get verifiedToken => _verifiedToken;
  String? get lastEmail => _lastEmail;
  int get resendSecondsRemaining => _resendSecondsRemaining;
  bool get canResend => _lastEmail != null && _resendSecondsRemaining == 0;

  Future<bool> requestReset({required String email}) async {
    final normalizedEmail = email.trim();
    return _run(() async {
      await _repository.requestReset(
        PasswordResetRequest(email: normalizedEmail),
      );
      _lastEmail = normalizedEmail;
      _verifiedToken = null;
      lastSuccessMessage =
          'If an account exists, a reset link has been sent to your email.';
      _startResendCooldown();
    });
  }

  Future<bool> resendReset() async {
    final email = _lastEmail;
    if (email == null || _resendSecondsRemaining > 0) {
      return false;
    }
    return requestReset(email: email);
  }

  Future<bool> verifyToken({required String token}) async {
    final normalizedToken = token.trim();
    return _run(
      () async {
        isVerifying = true;
        notifyListeners();
        final response = await _repository.verifyToken(
          PasswordResetVerifyRequest(token: normalizedToken),
        );
        if (!response.valid) {
          throw const PasswordResetException(
            'This reset link is invalid or has expired.',
          );
        }
        _verifiedToken = normalizedToken;
        lastSuccessMessage = 'Reset link verified.';
      },
      onFinally: () {
        isVerifying = false;
      },
    );
  }

  Future<bool> confirmReset({
    required String token,
    required String password,
  }) async {
    final normalizedToken = token.trim();
    return _run(() async {
      final response = await _repository.confirmReset(
        PasswordResetConfirmRequest(
          token: normalizedToken,
          password: password,
        ),
      );
      lastSuccessMessage = response.message;
      _verifiedToken = null;
    });
  }

  void clearToken() {
    _verifiedToken = null;
    notifyListeners();
  }

  void clearMessages() {
    errorMessage = null;
    lastSuccessMessage = null;
    lastStatusCode = null;
  }

  Future<bool> _run(
    Future<void> Function() action, {
    VoidCallback? onFinally,
  }) async {
    errorMessage = null;
    lastSuccessMessage = null;
    lastStatusCode = null;
    isLoading = true;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (error) {
      _setError(error);
      return false;
    } finally {
      onFinally?.call();
      isLoading = false;
      notifyListeners();
    }
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    _resendSecondsRemaining = resendCooldownSeconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSecondsRemaining <= 1) {
        timer.cancel();
        _resendSecondsRemaining = 0;
      } else {
        _resendSecondsRemaining -= 1;
      }
      notifyListeners();
    });
  }

  void _setError(Object error) {
    if (error is PasswordResetException) {
      errorMessage = error.message;
      return;
    }
    if (error is DioException) {
      lastStatusCode = error.response?.statusCode;
      errorMessage = ErrorUtils.friendlyMessage(
        error,
        statusMessages: const {
          400: 'This reset link is invalid or has expired.',
          401: 'This reset link is invalid or has expired.',
          404: 'This reset link is invalid or has expired.',
        },
        fallbackMessage: 'Something went wrong. Please try again.',
      );
      return;
    }
    errorMessage = error.toString();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }
}

class PasswordResetException implements Exception {
  const PasswordResetException(this.message);

  final String message;
}
