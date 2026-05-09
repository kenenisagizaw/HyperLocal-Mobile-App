class WalletModel {
  final double walletBalance;
  final int connectBalance;

  const WalletModel({
    required this.walletBalance,
    required this.connectBalance,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      walletBalance: (json['walletBalance'] as num).toDouble(),
      connectBalance: json['connectBalance'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'walletBalance': walletBalance,
      'connectBalance': connectBalance,
    };
  }

  @override
  String toString() {
    return 'WalletModel(walletBalance: $walletBalance, connectBalance: $connectBalance)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WalletModel &&
        other.walletBalance == walletBalance &&
        other.connectBalance == connectBalance;
  }

  @override
  int get hashCode => walletBalance.hashCode ^ connectBalance.hashCode;
}
