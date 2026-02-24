import '../models/user_model.dart';

class ProviderRepository {
  final List<UserModel> _providers = [
    UserModel(
      id: 'provider-1',
      role: UserRole.provider,
      name: 'Abebe Bekele',
      phone: '0911 223 344',
      email: 'abebe@example.com',
      location: 'Bole, Addis Ababa',
      latitude: 8.9969,
      longitude: 38.7875,
      isVerified: true,
    ),
    UserModel(
      id: 'provider-2',
      role: UserRole.provider,
      name: 'Mekdes Girma',
      phone: '0900 556 677',
      email: 'mekdes@example.com',
      location: 'Sar Bet, Addis Ababa',
      latitude: 9.0088,
      longitude: 38.7349,
      isVerified: true,
    ),
  ];

  Future<List<UserModel>> fetchProviders() async {
    return _providers;
  }

  UserModel? getProviderById(String id) {
    try {
      return _providers.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void upsertProvider(UserModel provider) {
    final index = _providers.indexWhere((p) => p.id == provider.id);
    if (index == -1) {
      _providers.add(provider);
    } else {
      _providers[index] = provider;
    }
  }
}
