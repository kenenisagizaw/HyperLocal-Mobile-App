import '../../core/utils/logger.dart';
import '../datasources/remote/withdrawal_api.dart';
import '../models/withdrawal_request_model.dart';

class WithdrawalRepository {
  WithdrawalRepository(this._api);

  final WithdrawalApi _api;

  Future<WithdrawalRequest> requestWithdrawal({
    required double amount,
    required String method,
    String? accountName,
    String? accountNumber,
    String? bankName,
    String? phoneNumber,
  }) async {
    try {
      Logger.info('Withdrawal Repository - Requesting withdrawal');
      return await _api.requestWithdrawal(
        amount: amount,
        method: method,
        accountName: accountName,
        accountNumber: accountNumber,
        bankName: bankName,
        phoneNumber: phoneNumber,
      );
    } catch (e) {
      Logger.error('Withdrawal Repository - Failed to request withdrawal: $e');
      rethrow;
    }
  }

  Future<List<WithdrawalRequest>> fetchWithdrawals({
    int? skip,
    int? take,
    String? status,
  }) async {
    try {
      Logger.info('Withdrawal Repository - Fetching withdrawals');
      return await _api.fetchWithdrawals(
        skip: skip,
        take: take,
        status: status,
      );
    } catch (e) {
      Logger.error('Withdrawal Repository - Failed to fetch withdrawals: $e');
      rethrow;
    }
  }
}
