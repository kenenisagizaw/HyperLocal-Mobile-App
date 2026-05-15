import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/wallet/providers/provider_wallet_provider.dart';
import '../../../features/wallet/screens/withdrawal_history_screen.dart';
import '../../../features/wallet/screens/withdrawal_request_screen.dart';
import '../../../features/wallet/widgets/wallet_balance_card.dart';
import '../../../features/wallet/widgets/wallet_empty_state.dart';
import '../../../features/wallet/widgets/wallet_section_header.dart';
import '../../../features/wallet/widgets/wallet_transaction_tile.dart';

class ProviderWalletScreen extends StatefulWidget {
  const ProviderWalletScreen({super.key});

  @override
  State<ProviderWalletScreen> createState() => _ProviderWalletScreenState();
}

class _ProviderWalletScreenState extends State<ProviderWalletScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final provider = context.read<ProviderWalletProvider>();
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 120) {
      provider.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Wallet'),
        actions: [
          IconButton(
            tooltip: 'Withdrawal history',
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const WithdrawalHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ProviderWalletProvider>(
        builder: (context, provider, _) {
          final wallet = provider.wallet;
          final transactions = provider.transactions;
          final currency = wallet?.currency ?? 'ETB';

          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                WalletBalanceCard(
                  title: 'Available balance',
                  amount:
                      '$currency ${wallet?.walletBalance.toStringAsFixed(2) ?? '0.00'}',
                  subtitle:
                      'Wallet balance: $currency ${wallet?.walletBalance.toStringAsFixed(2) ?? '0.00'}',
                  trailing: ElevatedButton(
                    onPressed: wallet == null
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => WithdrawalRequestScreen(
                                  availableBalance: wallet.availableToWithdraw,
                                  feePercent: wallet.withdrawalFeePercent,
                                ),
                              ),
                            );
                          },
                    child: const Text('Withdraw'),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: WalletBalanceCard(
                        title: 'Total earned',
                        amount:
                            '$currency ${wallet?.totalEarned.toStringAsFixed(2) ?? '0.00'}',
                        subtitle: 'All-time earnings',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: WalletBalanceCard(
                        title: 'Withdrawn',
                        amount:
                            '$currency ${wallet?.totalWithdrawn.toStringAsFixed(2) ?? '0.00'}',
                        subtitle: 'Completed withdrawals',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                WalletSectionHeader(
                  title: 'Transactions',
                  action: TextButton(
                    onPressed: provider.refresh,
                    child: const Text('Refresh'),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _FilterChip(
                      label: provider.statusFilter ?? 'All status',
                      options: const [
                        'All status',
                        'completed',
                        'pending',
                        'failed',
                      ],
                      onSelected: (value) {
                        provider.updateFilters(
                          status: value == 'All status' ? null : value,
                          type: provider.typeFilter,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: provider.typeFilter ?? 'All types',
                      options: const [
                        'All types',
                        'payment',
                        'withdrawal',
                        'refund',
                      ],
                      onSelected: (value) {
                        provider.updateFilters(
                          status: provider.statusFilter,
                          type: value == 'All types' ? null : value,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (provider.isLoading && transactions.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (provider.errorMessage != null && transactions.isEmpty)
                  WalletEmptyState(
                    title: 'Unable to load wallet',
                    subtitle: provider.errorMessage ?? '',
                    icon: Icons.error_outline,
                  )
                else if (transactions.isEmpty)
                  const WalletEmptyState(
                    title: 'No transactions yet',
                    subtitle:
                        'Payments, withdrawals, and refunds show up here.',
                  )
                else
                  ...transactions.map((tx) {
                    final isCredit =
                        tx.type.toLowerCase().contains('payment') ||
                        tx.type.toLowerCase().contains('refund') ||
                        tx.amount >= 0;
                    final subtitle =
                        '${_formatDate(tx.createdAt)} • ${tx.description.isEmpty ? 'Wallet activity' : tx.description}';
                    final amount =
                        '${isCredit ? '+' : '-'}$currency ${tx.amount.abs().toStringAsFixed(2)}';
                    return WalletTransactionTile(
                      title: _titleForWallet(tx.type),
                      subtitle: subtitle,
                      amount: amount,
                      status: _formatStatus(tx.status),
                      isCredit: isCredit,
                    );
                  }),
                if (provider.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatStatus(String status) {
    if (status.isEmpty) return 'completed';
    return status.replaceAll('_', ' ');
  }

  String _titleForWallet(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('withdraw')) return 'Withdrawal';
    if (normalized.contains('refund')) return 'Refund';
    if (normalized.contains('payment')) return 'Payment received';
    return 'Wallet activity';
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (context) {
        return options
            .map((option) => PopupMenuItem(value: option, child: Text(option)))
            .toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, size: 16),
          ],
        ),
      ),
    );
  }
}
