import 'package:flutter/material.dart';

import '../../../core/utils/logger.dart';
import '../../../data/models/connect_wallet_model.dart';
import '../../../data/models/connect_transaction_model.dart';
import '../../../data/repositories/connects_repository.dart';

class ConnectsProvider extends ChangeNotifier {
  ConnectsProvider({required ConnectsRepository repository})
      : _repository = repository {
    fetchConnects();
  }

  final ConnectsRepository _repository;
  final int _pageSize = 20;

  ConnectWallet? _wallet;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  ConnectWallet? get wallet => _wallet;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  int get connectBalance => _wallet?.connectBalance ?? 0;
  List<ConnectTransaction> get transactions =>
      _wallet?.transactions ?? const [];

  Future<void> fetchConnects({bool refresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    if (refresh) {
      _wallet = null;
      _hasMore = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      Logger.info('Connects Provider - Loading connects');
      final result = await _repository.fetchConnects(
        skip: 0,
        take: _pageSize,
      );
      _wallet = result;
      _hasMore = result.transactions.length >= _pageSize;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    final current = _wallet;
    if (current == null) {
      await fetchConnects();
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _repository.fetchConnects(
        skip: current.transactions.length,
        take: _pageSize,
      );
      final merged = ConnectWallet(
        connectBalance: result.connectBalance,
        transactions: [...current.transactions, ...result.transactions],
        pagination: result.pagination,
      );
      _wallet = merged;
      _hasMore = result.transactions.length >= _pageSize;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => fetchConnects(refresh: true);
}
