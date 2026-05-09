import 'wallet_transaction_model.dart';

class ProviderWalletModel {
  ProviderWalletModel({
    required this.walletBalance,
    required this.totalEarned,
    required this.totalWithdrawn,
    required this.pendingWithdrawals,
    required this.availableToWithdraw,
    required this.currency,
    this.withdrawalFeePercent,
    required this.transactions,
    this.pagination,
  });

  final double walletBalance;
  final double totalEarned;
  final double totalWithdrawn;
  final double pendingWithdrawals;
  final double availableToWithdraw;
  final String currency;
  final double? withdrawalFeePercent;
  final List<WalletTransaction> transactions;
  final Map<String, dynamic>? pagination;
}
