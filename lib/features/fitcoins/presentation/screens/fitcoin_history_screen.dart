import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../community/presentation/providers/community_providers.dart';
import '../../../fitcoins/domain/entities/fitcoin_transaction.dart';

/// Full paginated-style history (all loaded from stream for Phase 7).
class FitcoinHistoryScreen extends ConsumerWidget {
  const FitcoinHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<FitcoinTransaction>> async =
        ref.watch(fitcoinLedgerStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainer,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'All transactions',
          style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
        ),
      ),
      body: async.when(
        data: (List<FitcoinTransaction> list) => ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          itemBuilder: (BuildContext context, int i) {
            final FitcoinTransaction t = list[i];
            return _row(t);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text('Could not load', style: AppTextStyles.bodyMedium),
        ),
      ),
    );
  }

  static Widget _row(FitcoinTransaction t) {
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
          child: ListTile(
            title: Text(t.description, style: AppTextStyles.bodyLarge),
            subtitle: Text(
              DateFormat.yMMMd().add_jm().format(t.occurredAt),
              style: AppTextStyles.bodySmall,
            ),
            trailing: Text(
              '${earn ? '+' : '−'}${t.amount} FC',
              style: AppTextStyles.labelLarge.copyWith(
                color: earn ? AppColors.primary : AppColors.tertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
