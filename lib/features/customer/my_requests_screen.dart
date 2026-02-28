import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../auth/providers/auth_provider.dart';
import 'create_request_screen.dart';
import 'providers/quote_provider.dart';
import 'providers/request_provider.dart';
import 'request_detail_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RequestProvider>().loadRequests();
    });
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange.shade600;
      case RequestStatus.quoted:
        return Colors.purple.shade600;
      case RequestStatus.accepted:
        return Colors.blue.shade600;
      case RequestStatus.completed:
        return Colors.green.shade600;
      case RequestStatus.cancelled:
        return Colors.red.shade600;
    }
  }

  IconData _getStatusIcon(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Icons.hourglass_empty;
      case RequestStatus.quoted:
        return Icons.request_quote;
      case RequestStatus.accepted:
        return Icons.check_circle;
      case RequestStatus.completed:
        return Icons.task_alt;
      case RequestStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText(RequestStatus status) {
    return status
        .toString()
        .split('.')
        .last
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final requestProvider = context.watch<RequestProvider>();
    final quoteProvider = context.watch<QuoteProvider>();

    final currentUser = auth.currentUser;
    if (currentUser == null) {
      return Scaffold(
        body: Container(
          decoration: _buildBackgroundGradient(),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'No user logged in',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final myRequests = requestProvider.getCustomerRequests(currentUser.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Requests',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.green.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<RequestProvider>().loadRequests();
            },
          ),
        ],
      ),
      body: Container(
        decoration: _buildBackgroundGradient(),
        child: requestProvider.isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading your requests...',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              )
            : myRequests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade100, Colors.green.shade100],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.inbox,
                            size: 60,
                            color: Colors.blue.shade400,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Requests Yet',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'You have not created any service requests yet. Tap the + button to create your first request.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreateRequestScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create New Request'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: myRequests.length,
                    itemBuilder: (context, index) {
                      final request = myRequests[index];
                      final quotesCount = quoteProvider.getQuotesForRequest(request.id).length;

                      return _buildRequestCard(context, request, quotesCount);
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateRequestScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, dynamic request, int quotesCount) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RequestDetailScreen(
              request: request,
              quotes: [], // quotes will be loaded in detail screen
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Top gradient bar based on status
              Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getStatusColor(request.status).withValues(alpha: 0.7),
                      _getStatusColor(request.status),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              
              // Main content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with category and status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade400, Colors.green.shade400],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getCategoryIcon(request.category),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.category,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                'Request #${request.id.substring(0, 6)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(request.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusColor(request.status).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(request.status),
                                size: 14,
                                color: _getStatusColor(request.status),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getStatusText(request.status),
                                style: TextStyle(
                                  color: _getStatusColor(request.status),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    Text(
                      request.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Details grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.location_on,
                            label: 'Location',
                            value: _truncateText(request.location, 15),
                            color: Colors.blue.shade600,
                          ),
                        ),
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.attach_money,
                            label: 'Budget',
                            value: '${request.budget} ETB',
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Quotes and date
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.request_quote,
                            label: 'Quotes',
                            value: '$quotesCount ${quotesCount == 1 ? 'quote' : 'quotes'}',
                            color: Colors.purple.shade600,
                          ),
                        ),
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.access_time,
                            label: 'Created',
                            value: _formatDate(request.createdAt),
                            color: Colors.orange.shade600,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // View details button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RequestDetailScreen(
                                  request: request,
                                  quotes: [],
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'View Details',
                                  style: TextStyle(
                                    color: Colors.blue.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward,
                                  size: 16,
                                  color: Colors.blue.shade600,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  BoxDecoration _buildBackgroundGradient() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.blue.shade50,
          Colors.green.shade50,
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Plumbing':
        return Icons.plumbing;
      case 'Electrical':
        return Icons.electrical_services;
      case 'Painting':
        return Icons.format_paint;
      case 'Carpentry':
        return Icons.handyman;
      case 'Cleaning':
        return Icons.cleaning_services;
      default:
        return Icons.category;
    }
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}