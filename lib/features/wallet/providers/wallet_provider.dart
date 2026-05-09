import 'package:flutter/material.dart';

import '../../../data/repositories/wallet_repository.dart';
import '../../../data/models/wallet_model.dart';
import '../../../core/utils/logger.dart';

class WalletProvider extends ChangeNotifier {
  WalletProvider({required WalletRepository repository})
      : _repository = repository {
    _initialize();
  }

  final WalletRepository _repository;

  WalletModel? _wallet;
  bool _isLoading = false;
  String? _errorMessage;

  WalletModel? get wallet => _wallet;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasWallet => _wallet != null;

  double get walletBalance => _wallet?.walletBalance ?? 0.0;
  int get connectBalance => _wallet?.connectBalance ?? 0;

  Future<void> _initialize() async {
    await fetchWallet();
  }

  Future<void> fetchWallet() async {
    if (_isLoading) return;

    _setLoading(true);
    _errorMessage = null;

    try {
      Logger.info('Wallet Provider - Fetching wallet data');
      final wallet = await _repository.fetchWallet();
      _wallet = wallet;
      Logger.info('Wallet Provider - Wallet data loaded: ${wallet.connectBalance} connects');
      notifyListeners();
    } catch (e) {
      Logger.error('Wallet Provider - Failed to fetch wallet: $e');
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void refreshWallet() {
    fetchWallet();
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
