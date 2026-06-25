import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../community/presentation/providers/community_providers.dart';
import '../../../fitcoins/domain/entities/fitcoin_transaction.dart';
import '../../../fitcoins/domain/entities/fitcoin_wallet.dart';

/// Wallet detail + history preview.
class FitcoinsWalletScreen extends ConsumerWidget {
  const FitcoinsWalletScreen({super.key});

  static String _fmt(int n) => NumberFormat.decimalPattern().format(n);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FitcoinWallet> w = ref.watch(fitcoinWalletStreamProvider);
    final AsyncValue<List<FitcoinTransaction>> ledger =
        ref.watch(fitcoinLedgerStreamProvider);
    final List<FitcoinTransaction> preview = ledger.maybeWhen(
      data: (List<FitcoinTransaction> l) => l.take(10).toList(),
      orElse: () => <FitcoinTransaction>[],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainer,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Fitcoins', style: AppTextStyles.headlineMedium.copyWith(fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: <Widget>[
          w.when(
            data: (FitcoinWallet wallet) => GlassCard(
              glowColor: AppColors.primary,
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                        'assets/images/fitcoins.png',
                        width: 56,
                        height: 56,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.monetization_on,
                          size: 52,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_fmt(wallet.balance)} FC',
                        style: AppTextStyles.displayLarge.copyWith(fontSize: 40),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '≈ ₹${wallet.approximateInrValue.toStringAsFixed(2)} value (1 FC = ₹0.10 — display only, not financial advice)',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text('Error', style: AppTextStyles.bodyMedium),
          ),
          const SizedBox(height: 16),
          w.when(
            data: (FitcoinWallet wallet) => GlassCard(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _StatCell(
                      label: 'Earned Today',
                      value: '+${_fmt(wallet.earnedToday)}',
                    ),
                  ),
                  Expanded(
                    child: _StatCell(
                      label: 'This Week',
                      value: '+${_fmt(wallet.earnedThisWeek)}',
                    ),
                  ),
                  Expanded(
                    child: _StatCell(
                      label: 'All Time',
                      value: _fmt(wallet.earnedAllTime),
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),
          Text('Ways to Earn', style: AppTextStyles.headlineMedium.copyWith(fontSize: 18)),
          const SizedBox(height: 10),
          GlassCard(
            child: Column(
              children: <Widget>[
                _EarnRow(
                  icon: Icons.fitness_center,
                  label: 'Complete workouts',
                  fc: '+15–120',
                ),
                _EarnRow(
                  icon: Icons.directions_run,
                  label: 'Hit activity goals',
                  fc: '+10–50',
                ),
                _EarnRow(
                  icon: Icons.restaurant,
                  label: 'Log meals',
                  fc: '+5–20',
                ),
                _EarnRow(
                  icon: Icons.emoji_events,
                  label: 'Win challenges',
                  fc: '+50–300',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.push('/community/shop'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.background,
              ),
              child: Text('Redeem', style: AppTextStyles.button),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Transaction History',
                style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
              ),
              TextButton(
                onPressed: () => context.push('/community/wallet/history'),
                child: Text(
                  'View All',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.secondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...preview.map(_txTile),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(label, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.labelLarge, textAlign: TextAlign.center),
      ],
    );
  }
}

class _EarnRow extends StatelessWidget {
  const _EarnRow({
    required this.icon,
    required this.label,
    required this.fc,
  });

  final IconData icon;
  final String label;
  final String fc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: <Widget>[
          Icon(icon, color: AppColors.secondary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTextStyles.bodyLarge)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(fc, style: AppTextStyles.labelSmall),
          ),
        ],
      ),
    );
  }
}

Widget _txTile(FitcoinTransaction t) {
  final bool earn = t.kind == FitcoinTransactionKind.earn;
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: GlassCard(
      padding: EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: earn ? AppColors.primaryContainer : AppColors.tertiary,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          child: Row(
            children: <Widget>[
              Icon(
                earn ? Icons.add_circle_outline : Icons.remove_circle_outline,
                color: earn ? AppColors.primary : AppColors.tertiary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(t.description, style: AppTextStyles.bodyLarge),
                    Text(
                      DateFormat.yMMMd().add_jm().format(t.occurredAt),
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '${earn ? '+' : '−'}${t.amount} FC',
                style: AppTextStyles.labelLarge.copyWith(
                  color: earn ? AppColors.primary : AppColors.tertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
