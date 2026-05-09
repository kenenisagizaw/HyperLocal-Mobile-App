import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/wallet/providers/withdrawal_provider.dart';

class WithdrawalRequestScreen extends StatefulWidget {
  const WithdrawalRequestScreen({
    super.key,
    required this.availableBalance,
    this.feePercent,
  });

  final double availableBalance;
  final double? feePercent;

  @override
  State<WithdrawalRequestScreen> createState() =>
      _WithdrawalRequestScreenState();
}

class _WithdrawalRequestScreenState extends State<WithdrawalRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _method = 'bank';

  @override
  void dispose() {
    _amountController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  double? _parseAmount() {
    final raw = _amountController.text.trim();
    return double.tryParse(raw);
  }

  @override
  Widget build(BuildContext context) {
    final feePercent = widget.feePercent;
    final amount = _parseAmount() ?? 0.0;
    final fee = feePercent == null ? null : amount * (feePercent / 100.0);
    final net = feePercent == null ? null : amount - (fee ?? 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Request Withdrawal')),
      body: Consumer<WithdrawalProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available balance: ETB ${widget.availableBalance.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Icon(Icons.payments),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final amountValue = double.tryParse(value ?? '');
                      if (amountValue == null || amountValue <= 0) {
                        return 'Enter a valid amount';
                      }
                      if (amountValue > widget.availableBalance) {
                        return 'Amount exceeds available balance';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _method,
                    items: const [
                      DropdownMenuItem(
                        value: 'bank',
                        child: Text('Bank Transfer'),
                      ),
                      DropdownMenuItem(
                        value: 'mobile_money',
                        child: Text('Mobile Money'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _method = value);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Payout method',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_method == 'bank') ...[
                    TextFormField(
                      controller: _accountNameController,
                      decoration: const InputDecoration(
                        labelText: 'Account name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Account name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Account number',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Account number is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bankNameController,
                      decoration: const InputDecoration(
                        labelText: 'Bank name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Bank name is required';
                        }
                        return null;
                      },
                    ),
                  ] else ...[
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Mobile money number',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feePercent == null
                              ? 'Fee preview will appear after configuration.'
                              : 'Fee: ETB ${fee?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          feePercent == null
                              ? 'Net payout: --'
                              : 'Net payout: ETB ${net?.toStringAsFixed(2) ?? '0.00'}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.isSubmitting
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) {
                                return;
                              }
                              final amountValue = _parseAmount();
                              if (amountValue == null) return;
                              final result = await provider.requestWithdrawal(
                                amount: amountValue,
                                method: _method,
                                accountName: _accountNameController.text.trim(),
                                accountNumber: _accountNumberController.text
                                    .trim(),
                                bankName: _bankNameController.text.trim(),
                                phoneNumber: _phoneController.text.trim(),
                              );
                              if (!mounted) return;
                              if (result != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Withdrawal request submitted',
                                    ),
                                  ),
                                );
                                Navigator.of(context).pop();
                              } else if (provider.errorMessage != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(provider.errorMessage!),
                                  ),
                                );
                              }
                            },
                      child: provider.isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Submit request'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
