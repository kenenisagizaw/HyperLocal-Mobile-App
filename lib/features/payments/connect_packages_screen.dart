import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/services/connect_purchase_service.dart';
import '../../data/datasources/local/local_storage.dart';
import '../../core/utils/logger.dart';
import '../../core/services/service_locator.dart';
import '../auth/providers/auth_provider.dart';

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
      // Check if user is authenticated
      final authProvider = context.read<AuthProvider>();
      Logger.info('Auth Provider - Current user: ${authProvider.currentUser?.id ?? "null"}');
      Logger.info('Auth Provider - Is authenticated: ${authProvider.currentUser != null}');
      
      if (authProvider.currentUser == null) {
        throw Exception('User not authenticated. Please log in first.');
      }
      
      // Debug token comparison
      final localStorage = LocalStorage();
      final storedToken = await localStorage.getAccessToken();
      Logger.info('Token Debug - Stored token exists: ${storedToken != null}');
      if (storedToken != null) {
        Logger.info('Token Debug - Stored token length: ${storedToken.length}');
        Logger.info('Token Debug - Stored token preview: ${storedToken.substring(0, storedToken.length > 20 ? 20 : storedToken.length)}...');
      }
      
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
        String errorMessage = 'Payment initialization failed';
        String errorDetail = '';
        
        // Handle specific errors
        if (e.toString().contains('401') || e.toString().contains('unauthorized')) {
          errorMessage = 'Authentication required';
          errorDetail = 'Please log in again to continue.';
        } else if (e.toString().contains('User not authenticated')) {
          errorMessage = 'Please log in';
          errorDetail = 'You need to be logged in to purchase connects.';
        } else if (e.toString().contains('network') || e.toString().contains('connection')) {
          errorMessage = 'Network error';
          errorDetail = 'Please check your internet connection and try again.';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Request timeout';
          errorDetail = 'The server is taking too long to respond. Please try again.';
        } else if (e.toString().contains('404')) {
          errorMessage = 'Service unavailable';
          errorDetail = 'The payment service is currently unavailable.';
        } else if (e.toString().contains('400')) {
          errorMessage = 'Invalid request';
          errorDetail = 'The payment request format is invalid. Please try again.';
        } else if (e.toString().contains('500')) {
          errorMessage = 'Server error';
          errorDetail = 'Something went wrong on our end. Please try again later.';
        } else {
          errorMessage = 'Payment initialization failed';
          errorDetail = 'An unexpected error occurred. Please try again.';
        }
        
        // Show detailed error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(errorMessage),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(errorDetail),
                const SizedBox(height: 8),
                Text(
                  'Error details: ${e.toString()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            actions: [
              if (e.toString().contains('401') || e.toString().contains('User not authenticated'))
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
                  },
                  child: const Text('Login'),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
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
