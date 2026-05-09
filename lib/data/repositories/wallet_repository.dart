import '../datasources/remote/wallet_api.dart';
import '../models/wallet_model.dart';
import '../../core/utils/logger.dart';

class WalletRepository {
  WalletRepository(this._walletApi);

  final WalletApi _walletApi;

  Future<WalletModel> fetchWallet() async {
    try {
      Logger.info('Wallet Repository - Fetching wallet');
      final wallet = await _walletApi.fetchWallet();
      Logger.info('Wallet Repository - Wallet fetched successfully');
      return wallet;
    } catch (e) {
      Logger.error('Wallet Repository - Failed to fetch wallet: $e');
      rethrow;
    }
  }
}
