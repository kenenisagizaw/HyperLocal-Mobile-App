import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/wallet/providers/connects_provider.dart';
import '../../../features/wallet/widgets/wallet_balance_card.dart';
import '../../../features/wallet/widgets/wallet_empty_state.dart';
import '../../../features/wallet/widgets/wallet_section_header.dart';
import '../../../features/wallet/widgets/wallet_transaction_tile.dart';

class ConnectsWalletScreen extends StatefulWidget {
  const ConnectsWalletScreen({super.key});

  @override
  State<ConnectsWalletScreen> createState() => _ConnectsWalletScreenState();
}

class _ConnectsWalletScreenState extends State<ConnectsWalletScreen> {
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
    final provider = context.read<ConnectsProvider>();
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 120) {
      provider.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Wallet'),
        actions: [
          IconButton(
            tooltip: 'Buy Connects',
            onPressed: () => Navigator.of(context).pushNamed('/connect-packages'),
            icon: const Icon(Icons.flash_on),
          ),
        ],
      ),
      body: Consumer<ConnectsProvider>(
        builder: (context, provider, _) {
          final transactions = provider.transactions;
          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                WalletBalanceCard(
                  title: 'Connect Balance',
                  amount: '${provider.connectBalance}',
                  subtitle: 'Use connects to send quotes.',
                  trailing: IconButton(
                    tooltip: 'Refresh',
                    onPressed: provider.refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
                const SizedBox(height: 20),
                WalletSectionHeader(
                  title: 'Recent Activity',
                  action: TextButton(
                    onPressed: provider.refresh,
                    child: const Text('Refresh'),
                  ),
                ),
                const SizedBox(height: 12),
                if (provider.isLoading && transactions.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (provider.errorMessage != null && transactions.isEmpty)
                  WalletEmptyState(
                    title: 'Unable to load connects',
                    subtitle: provider.errorMessage ?? '',
                    icon: Icons.error_outline,
                  )
                else if (transactions.isEmpty)
                  const WalletEmptyState(
                    title: 'No connect activity yet',
                    subtitle: 'Your connect purchases and usage show here.',
                  )
                else
                  ...transactions.map((tx) {
                    final isCredit = tx.type.toLowerCase().contains('purchase') ||
                        tx.type.toLowerCase().contains('refund') ||
                        tx.amount > 0;
                    final subtitle =
                        '${_formatDate(tx.createdAt)} • ${tx.description.isEmpty ? 'Connect activity' : tx.description}';
                    final amount =
                        '${isCredit ? '+' : '-'}${tx.amount}';
                    return WalletTransactionTile(
                      title: _titleForConnect(tx.type),
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

  String _titleForConnect(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('purchase')) return 'Connect Purchase';
    if (normalized.contains('refund')) return 'Refund';
    if (normalized.contains('spend')) return 'Connect Spent';
    return 'Connect Activity';
  }
}
