import 'package:flutter/material.dart';

import '../../../core/utils/logger.dart';
import '../../../data/models/provider_wallet_model.dart';
import '../../../data/models/wallet_transaction_model.dart';
import '../../../data/repositories/provider_wallet_repository.dart';

class ProviderWalletProvider extends ChangeNotifier {
  ProviderWalletProvider({required ProviderWalletRepository repository})
    : _repository = repository {
    fetchWallet();
  }

  final ProviderWalletRepository _repository;
  final int _pageSize = 20;

  ProviderWalletModel? _wallet;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  String? _statusFilter;
  String? _typeFilter;

  ProviderWalletModel? get wallet => _wallet;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  String? get statusFilter => _statusFilter;
  String? get typeFilter => _typeFilter;

  List<WalletTransaction> get transactions => _wallet?.transactions ?? const [];

  Future<void> fetchWallet({bool refresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    if (refresh) {
      _wallet = null;
      _hasMore = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      Logger.info('Provider Wallet Provider - Loading wallet');
      final result = await _repository.fetchWallet(
        skip: 0,
        take: _pageSize,
        status: _statusFilter,
        type: _typeFilter,
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
      await fetchWallet();
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _repository.fetchWallet(
        skip: current.transactions.length,
        take: _pageSize,
        status: _statusFilter,
        type: _typeFilter,
      );
      final resolvedCurrency = result.currency.isEmpty
          ? current.currency
          : result.currency;
      final resolvedWalletBalance = result.walletBalance == 0
          ? current.walletBalance
          : result.walletBalance;
      final resolvedTotalEarned = result.totalEarned == 0
          ? current.totalEarned
          : result.totalEarned;
      final resolvedTotalWithdrawn = result.totalWithdrawn == 0
          ? current.totalWithdrawn
          : result.totalWithdrawn;
      final resolvedPendingWithdrawals = result.pendingWithdrawals == 0
          ? current.pendingWithdrawals
          : result.pendingWithdrawals;
      final resolvedAvailableToWithdraw = result.availableToWithdraw == 0
          ? current.availableToWithdraw
          : result.availableToWithdraw;
      final resolvedWithdrawalFeePercent =
          result.withdrawalFeePercent ?? current.withdrawalFeePercent;
      _wallet = ProviderWalletModel(
        walletBalance: resolvedWalletBalance,
        totalEarned: resolvedTotalEarned,
        totalWithdrawn: resolvedTotalWithdrawn,
        pendingWithdrawals: resolvedPendingWithdrawals,
        availableToWithdraw: resolvedAvailableToWithdraw,
        currency: resolvedCurrency,
        withdrawalFeePercent: resolvedWithdrawalFeePercent,
        transactions: [...current.transactions, ...result.transactions],
        pagination: result.pagination,
      );
      _hasMore = result.transactions.length >= _pageSize;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void updateFilters({String? status, String? type}) {
    _statusFilter = status;
    _typeFilter = type;
    fetchWallet(refresh: true);
  }

  void clearFilters() {
    _statusFilter = null;
    _typeFilter = null;
    fetchWallet(refresh: true);
  }

  Future<void> refresh() => fetchWallet(refresh: true);
}
