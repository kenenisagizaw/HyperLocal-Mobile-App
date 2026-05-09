import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/wallet/providers/withdrawal_provider.dart';
import '../../../features/wallet/widgets/wallet_empty_state.dart';
import '../../../features/wallet/widgets/wallet_transaction_tile.dart';

class WithdrawalHistoryScreen extends StatefulWidget {
  const WithdrawalHistoryScreen({super.key});

  @override
  State<WithdrawalHistoryScreen> createState() =>
      _WithdrawalHistoryScreenState();
}

class _WithdrawalHistoryScreenState extends State<WithdrawalHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WithdrawalProvider>().fetchWithdrawals();
    });
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
    final provider = context.read<WithdrawalProvider>();
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 120) {
      provider.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Withdrawal History')),
      body: Consumer<WithdrawalProvider>(
        builder: (context, provider, _) {
          final withdrawals = provider.withdrawals;
          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                if (provider.isLoading && withdrawals.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (provider.errorMessage != null && withdrawals.isEmpty)
                  WalletEmptyState(
                    title: 'Unable to load withdrawals',
                    subtitle: provider.errorMessage ?? '',
                    icon: Icons.error_outline,
                  )
                else if (withdrawals.isEmpty)
                  const WalletEmptyState(
                    title: 'No withdrawals yet',
                    subtitle: 'Your payout history appears here.',
                  )
                else
                  ...withdrawals.map((withdrawal) {
                    final subtitle =
                        '${_formatDate(withdrawal.createdAt)} • ${withdrawal.method.toUpperCase()}';
                    return WalletTransactionTile(
                      title: 'Withdrawal',
                      subtitle: subtitle,
                      amount: '-ETB ${withdrawal.amount.toStringAsFixed(2)}',
                      status: withdrawal.status,
                      isCredit: false,
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
}
