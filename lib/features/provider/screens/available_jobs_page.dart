import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/service_request_model.dart';
import '../../../data/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customer/providers/customer_directory_provider.dart';
import '../../customer/providers/request_provider.dart';
import '../utils/distance_utils.dart';
import '../widgets/user_avatar.dart';
import 'job_detail_screen.dart';

class AvailableJobsPage extends StatefulWidget {
  const AvailableJobsPage({super.key});

  @override
  State<AvailableJobsPage> createState() => _AvailableJobsPageState();
}

class _AvailableJobsPageState extends State<AvailableJobsPage> {
  String _selectedCategory = 'All';
  double _maxDistanceKm = 25;

  static const _primaryBlue = Color(0xFF2563EB);
  static const _primaryGreen = Color(0xFF059669);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RequestProvider>().loadRequests();
      context.read<CustomerDirectoryProvider>().loadCustomers();
    });
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.quoted:
        return Colors.purple;
      case RequestStatus.accepted:
        return _primaryBlue;
      case RequestStatus.completed:
        return _primaryGreen;
      case RequestStatus.cancelled:
        return Colors.red;
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
    final requests = Provider.of<RequestProvider>(context).requests;
    final authProvider = Provider.of<AuthProvider>(context);
    final customerDirectory = Provider.of<CustomerDirectoryProvider>(context);
    final providerUser = authProvider.currentUser;

    final categories = <String>{'All'};
    for (final request in requests) {
      categories.add(request.category);
    }

    final filteredRequests = requests.where((request) {
      final matchesCategory =
          _selectedCategory == 'All' || request.category == _selectedCategory;
      if (!matchesCategory) {
        return false;
      }

      final distanceKm = calculateDistanceKm(
        providerUser,
        request.locationLat,
        request.locationLng,
      );

      if (distanceKm == null) {
        return true;
      }

      return distanceKm <= _maxDistanceKm;
    }).toList();

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline_rounded,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No available jobs',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                items: categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedCategory = value);
                },
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _primaryBlue, width: 2),
                  ),
                  prefixIcon:
                      const Icon(Icons.category_rounded, color: _primaryBlue),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Distance: ${_maxDistanceKm.toStringAsFixed(0)} km',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: _primaryBlue,
                            inactiveTrackColor: _primaryBlue.withValues(alpha: 0.2),
                            thumbColor: _primaryBlue,
                            overlayColor: _primaryBlue.withValues(alpha: 0.1),
                            valueIndicatorColor: _primaryBlue,
                          ),
                          child: Slider(
                            value: _maxDistanceKm,
                            min: 5,
                            max: 50,
                            divisions: 9,
                            label: '${_maxDistanceKm.toStringAsFixed(0)} km',
                            onChanged: (value) =>
                                setState(() => _maxDistanceKm = value),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.filter_alt_off_rounded,
                          size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No jobs match your filters',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredRequests.length,
                  itemBuilder: (context, index) {
                    final req = filteredRequests[index];
                    final customer = customerDirectory.getCustomerById(
                      req.customerId,
                    );
                    final isDisabled =
                        req.status == RequestStatus.accepted ||
                            req.status == RequestStatus.completed ||
                            req.status == RequestStatus.cancelled;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () => _openJobDetail(
                          context,
                          request: req,
                          customer: customer,
                          providerUser: providerUser,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  UserAvatar(
                                    name: customer?.name ?? 'Customer',
                                    imagePath: customer?.profilePicture,
                                    radius: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          req.category,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          req.location,
                                          style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(req.status)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _getStatusText(req.status),
                                      style: TextStyle(
                                        color: _getStatusColor(req.status),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                req.description,
                                style: TextStyle(color: Colors.grey.shade700),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.person_outline_rounded,
                                          size: 16, color: Colors.grey.shade500),
                                      const SizedBox(width: 4),
                                      Text(
                                        customer?.name ?? req.customerId,
                                        style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(Icons.attach_money_rounded,
                                          size: 16, color: Colors.grey.shade500),
                                      const SizedBox(width: 4),
                                      Text(
                                        '\$${req.budget.toStringAsFixed(0)}',
                                        style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDisabled
                                          ? Colors.grey.shade400
                                          : _primaryBlue,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 10),
                                    ),
                                    onPressed: isDisabled
                                        ? null
                                        : () => _openJobDetail(
                                              context,
                                              request: req,
                                              customer: customer,
                                              providerUser: providerUser,
                                            ),
                                    child: const Text('Quote'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openJobDetail(
    BuildContext context, {
    required ServiceRequest request,
    required UserModel? customer,
    required UserModel? providerUser,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailScreen(
          request: request,
          customer: customer,
          providerUser: providerUser,
        ),
      ),
    );
  }
}
