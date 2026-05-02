import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import '../repositories/payment_repository.dart';
import '../models/payment_model.dart';
import '../../core/utils/logger.dart';
import '../../core/constants/api_constants.dart';

class ConnectPurchaseService {
  ConnectPurchaseService(this._paymentRepository);

  final PaymentRepository _paymentRepository;
  final AppLinks _appLinks = AppLinks();
  
  static const Map<int, double> connectPackages = {
    50: 100.0,   // 50 connects for 100 ETB
    75: 150.0,   // 75 connects for 150 ETB
    100: 200.0,  // 100 connects for 200 ETB
  };

  StreamSubscription<Uri>? _deepLinkSubscription;

  Future<PaymentInitialization> initializeConnectPurchase({
    required int connectAmount,
  }) async {
    if (!connectPackages.containsKey(connectAmount)) {
      throw ArgumentError('Invalid connect amount. Must be 50, 75, or 100');
    }

    final amount = connectPackages[connectAmount]!;
    
    return await _paymentRepository.initializeBookingPayment(
      purpose: 'CONNECT_PURCHASE',
      amount: amount,
      returnUrl: ApiConstants.mobilePaymentReturnUrl,
      metadata: {
        'connectAmount': connectAmount,
        'purpose': 'CONNECT_PURCHASE',
      },
    );
  }

  Future<void> launchPaymentUrl(String checkoutUrl) async {
    final uri = Uri.parse(checkoutUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw Exception('Could not launch payment URL: $checkoutUrl');
    }
  }

  Future<PaymentVerification> verifyPayment(String txRef) async {
    return await _paymentRepository.verifyPayment(txRef);
  }

  Stream<Uri?> listenForPaymentCallback() {
    return _appLinks.uriLinkStream;
  }

  void dispose() {
    _deepLinkSubscription?.cancel();
  }

  static List<ConnectPackage> getAvailablePackages() {
    return connectPackages.entries.map((entry) {
      return ConnectPackage(
        connectAmount: entry.key,
        price: entry.value,
      );
    }).toList();
  }
}

class ConnectPackage {
  const ConnectPackage({
    required this.connectAmount,
    required this.price,
  });

  final int connectAmount;
  final double price;

  String get displayName => '$connectAmount Connects';
  String get priceDisplay => 'ETB ${price.toStringAsFixed(0)}';
}
