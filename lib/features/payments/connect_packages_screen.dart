import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/connect_purchase_service.dart';
import '../../core/utils/logger.dart';
import '../../core/services/service_locator.dart';

class ConnectPackagesScreen extends StatefulWidget {
  const ConnectPackagesScreen({super.key});

  @override
  State<ConnectPackagesScreen> createState() => _ConnectPackagesScreenState();
}

class _ConnectPackagesScreenState extends State<ConnectPackagesScreen> {
  bool _isLoading = false;
  late final ConnectPurchaseService _connectPurchaseService;

  @override
  void initState() {
    super.initState();
    _connectPurchaseService = ServiceLocator().connectPurchaseService;
  }

  @override
  Widget build(BuildContext context) {
    final packages = ConnectPurchaseService.getAvailablePackages();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Buy Connects',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a Connect Package',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select the number of connects you want to purchase',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.builder(
                  itemCount: packages.length,
                  itemBuilder: (context, index) {
                    final package = packages[index];
                    return _PackageCard(
                      package: package,
                      isLoading: _isLoading,
                      onTap: () => _purchaseConnects(package),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _purchaseConnects(ConnectPackage package) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Logger.info('Initializing purchase for ${package.connectAmount} connects');
      
      // Initialize payment
      final paymentInit = await _connectPurchaseService.initializeConnectPurchase(
        connectAmount: package.connectAmount,
      );

      Logger.info('Payment initialized, launching checkout URL');

      // Launch payment URL
      await _connectPurchaseService.launchPaymentUrl(paymentInit.checkoutUrl);

      // Navigate to checkout pending screen
      if (mounted) {
        Navigator.of(context).pushNamed(
          '/checkout-pending',
          arguments: {
            'transactionReference': paymentInit.transactionReference,
            'connectAmount': package.connectAmount,
            'amount': paymentInit.amount,
          },
        );
      }
    } catch (e) {
      Logger.error('Failed to initialize payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.isLoading,
    required this.onTap,
  });

  final ConnectPackage package;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isLoading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[400]!, Colors.blue[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.flash_on,
                        color: Colors.white,
                        size: 24,
                      ),
                      Text(
                        '${package.connectAmount}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        package.priceDisplay,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
