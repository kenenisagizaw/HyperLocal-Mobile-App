import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_links/app_links.dart';
import '../../data/services/connect_purchase_service.dart';
import '../../data/repositories/payment_repository.dart';
import '../../core/utils/logger.dart';
import '../../core/services/service_locator.dart';

class CheckoutPendingScreen extends StatefulWidget {
  const CheckoutPendingScreen({
    super.key,
    this.transactionReference,
    this.connectAmount,
    this.amount,
  });

  final String? transactionReference;
  final int? connectAmount;
  final double? amount;

  @override
  State<CheckoutPendingScreen> createState() => _CheckoutPendingScreenState();
}

class _CheckoutPendingScreenState extends State<CheckoutPendingScreen> {
  bool _isVerifying = false;
  bool _paymentCompleted = false;
  String? _transactionReference;
  int? _connectAmount;
  double? _amount;
  Timer? _statusCheckTimer;
  StreamSubscription<Uri?>? _deepLinkSubscription;
  late final ConnectPurchaseService _connectPurchaseService;

  @override
  void initState() {
    super.initState();
    _transactionReference = widget.transactionReference;
    _connectAmount = widget.connectAmount;
    _amount = widget.amount;
    _connectPurchaseService = ServiceLocator().connectPurchaseService;
    _setupDeepLinkListener();
    _startStatusCheckTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _transactionReference = args['transactionReference'] as String?;
      _connectAmount = args['connectAmount'] as int?;
      _amount = args['amount'] as double?;
    }
  }

  void _setupDeepLinkListener() {
    _deepLinkSubscription = _connectPurchaseService.listenForPaymentCallback().listen(
      (Uri? uri) {
        if (uri != null && uri.scheme == 'myapp') {
          _handlePaymentCallback(uri);
        }
      },
      onError: (error) {
        Logger.error('Deep link error: $error');
      },
    );
  }

  void _handlePaymentCallback(Uri uri) {
    final txRef = uri.queryParameters['tx_ref'];
    if (txRef != null) {
      Logger.info('Payment callback received with tx_ref: $txRef');
      _verifyPayment(txRef);
    }
  }

  void _startStatusCheckTimer() {
    // Check payment status every 5 seconds
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_paymentCompleted && _transactionReference != null) {
        _checkPaymentStatus();
      }
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (_isVerifying || _transactionReference == null) return;

    try {
      setState(() {
        _isVerifying = true;
      });

      final verification = await _connectPurchaseService.verifyPayment(_transactionReference!);
      
      if (verification.verified) {
        _handlePaymentSuccess(verification);
      }
    } catch (e) {
      Logger.error('Error checking payment status: $e');
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  Future<void> _verifyPayment(String txRef) async {
    if (_isVerifying) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      final verification = await _connectPurchaseService.verifyPayment(txRef);
      
      if (verification.verified) {
        _handlePaymentSuccess(verification);
      } else {
        _handlePaymentFailure(verification);
      }
    } catch (e) {
      Logger.error('Payment verification failed: $e');
      _handlePaymentFailure(null);
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  void _handlePaymentSuccess(dynamic verification) {
    setState(() {
      _paymentCompleted = true;
    });
    _statusCheckTimer?.cancel();

    if (mounted) {
      Navigator.of(context).pushNamed(
        '/payment-result',
        arguments: {
          'success': true,
          'transactionReference': verification.transactionReference,
          'connectAmount': _connectAmount,
          'amount': _amount,
        },
      );
    }
  }

  void _handlePaymentFailure(dynamic verification) {
    _statusCheckTimer?.cancel();

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(
        '/payment-result',
        arguments: {
          'success': false,
          'transactionReference': verification?.transactionReference ?? _transactionReference,
          'connectAmount': _connectAmount,
          'amount': _amount,
          'error': verification?.status ?? 'Payment verification failed',
        },
      );
    }
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _deepLinkSubscription?.cancel();
    _connectPurchaseService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Processing Payment',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _isVerifying
                      ? SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                          ),
                        )
                      : Icon(
                          Icons.payment,
                          size: 60,
                          color: Colors.blue[600],
                        ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _isVerifying ? 'Verifying Payment...' : 'Payment in Progress',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _isVerifying
                    ? 'We are verifying your payment status. This may take a few moments.'
                    : 'Please complete your payment in the browser. We will automatically detect when you return.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_connectAmount != null && _amount != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_connectAmount Connects',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'ETB ${_amount!.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              OutlinedButton(
                onPressed: _isVerifying ? null : () => _checkPaymentStatus(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Check Status',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
