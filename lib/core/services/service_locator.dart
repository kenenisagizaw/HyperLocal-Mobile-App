import '../../data/datasources/remote/payment_api.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/services/connect_purchase_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  PaymentApi? _paymentApi;
  PaymentRepository? _paymentRepository;
  ConnectPurchaseService? _connectPurchaseService;

  PaymentApi get paymentApi {
    _paymentApi ??= PaymentApi();
    return _paymentApi!;
  }

  PaymentRepository get paymentRepository {
    _paymentRepository ??= PaymentRepository(paymentApi);
    return _paymentRepository!;
  }

  ConnectPurchaseService get connectPurchaseService {
    _connectPurchaseService ??= ConnectPurchaseService(paymentRepository);
    return _connectPurchaseService!;
  }

  void dispose() {
    _connectPurchaseService?.dispose();
    _connectPurchaseService = null;
    _paymentRepository = null;
    _paymentApi = null;
  }
}
