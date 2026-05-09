import 'package:flutter/material.dart';

import '../../../core/utils/logger.dart';
import '../../../data/models/withdrawal_request_model.dart';
import '../../../data/repositories/withdrawal_repository.dart';

class WithdrawalProvider extends ChangeNotifier {
  WithdrawalProvider({required WithdrawalRepository repository})
    : _repository = repository;

  final WithdrawalRepository _repository;
  final int _pageSize = 20;

  List<WithdrawalRequest> _withdrawals = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSubmitting = false;
  bool _hasMore = true;
  String? _errorMessage;

  List<WithdrawalRequest> get withdrawals => _withdrawals;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSubmitting => _isSubmitting;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  Future<void> fetchWithdrawals({bool refresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    if (refresh) {
      _withdrawals = [];
      _hasMore = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      Logger.info('Withdrawal Provider - Loading withdrawals');
      final result = await _repository.fetchWithdrawals(
        skip: 0,
        take: _pageSize,
      );
      _withdrawals = result;
      _hasMore = result.length >= _pageSize;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _repository.fetchWithdrawals(
        skip: _withdrawals.length,
        take: _pageSize,
      );
      _withdrawals = [..._withdrawals, ...result];
      _hasMore = result.length >= _pageSize;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<WithdrawalRequest?> requestWithdrawal({
    required double amount,
    required String method,
    String? accountName,
    String? accountNumber,
    String? bankName,
    String? phoneNumber,
  }) async {
    if (_isSubmitting) return null;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Logger.info('Withdrawal Provider - Submitting withdrawal');
      final result = await _repository.requestWithdrawal(
        amount: amount,
        method: method,
        accountName: accountName,
        accountNumber: accountNumber,
        bankName: bankName,
        phoneNumber: phoneNumber,
      );
      _withdrawals = [result, ..._withdrawals];
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => fetchWithdrawals(refresh: true);
}
