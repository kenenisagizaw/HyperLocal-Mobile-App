import '../../core/utils/logger.dart';
import '../datasources/remote/connects_api.dart';
import '../models/connect_wallet_model.dart';

class ConnectsRepository {
  ConnectsRepository(this._api);

  final ConnectsApi _api;

  Future<ConnectWallet> fetchConnects({int? skip, int? take}) async {
    try {
      Logger.info('Connects Repository - Fetching connects');
      return await _api.fetchConnects(skip: skip, take: take);
    } catch (e) {
      Logger.error('Connects Repository - Failed to fetch connects: $e');
      rethrow;
    }
  }
}
