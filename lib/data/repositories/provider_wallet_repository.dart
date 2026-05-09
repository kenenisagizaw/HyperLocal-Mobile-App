import '../datasources/remote/provider_wallet_api.dart';
import '../models/provider_wallet_model.dart';
import '../../core/utils/logger.dart';

class ProviderWalletRepository {
  ProviderWalletRepository(this._api);

  final ProviderWalletApi _api;

  Future<ProviderWalletModel> fetchWallet({
    int? skip,
    int? take,
    String? status,
    String? type,
  }) async {
    try {
      Logger.info('Provider Wallet Repository - Fetching wallet');
      return await _api.fetchWallet(
        skip: skip,
        take: take,
        status: status,
        type: type,
      );
    } catch (e) {
      Logger.error('Provider Wallet Repository - Failed to fetch wallet: $e');
      rethrow;
    }
  }
}
