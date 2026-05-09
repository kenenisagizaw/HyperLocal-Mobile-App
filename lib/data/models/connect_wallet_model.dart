import 'connect_transaction_model.dart';

class ConnectWallet {
  ConnectWallet({
    required this.connectBalance,
    required this.transactions,
    this.pagination,
  });

  final int connectBalance;
  final List<ConnectTransaction> transactions;
  final Map<String, dynamic>? pagination;
}
