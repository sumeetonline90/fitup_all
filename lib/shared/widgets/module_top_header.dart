import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/auth/domain/entities/fitup_user.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/community/presentation/providers/community_providers.dart';
import '../../features/fitcoins/domain/entities/fitcoin_wallet.dart';
import 'fitup_logo.dart';
import 'glass_card.dart';

class ModuleTopHeader extends ConsumerWidget {
  const ModuleTopHeader({
    super.key,
    this.quote,
    this.actions = const <Widget>[],
  });

  final String? quote;
  final List<Widget> actions;

  String _firstName(FitupUser? u) {
    if (u?.displayName != null && u!.displayName!.trim().isNotEmpty) {
      return u.displayName!.split(' ').first;
    }
    if (u?.email.isNotEmpty ?? false) {
      return u!.email.split('@').first;
    }
    return 'there';
  }

  String _greetingLabel() {
    final int h = DateTime.now().hour;
    if (h < 12) {
      return 'Good Morning';
    }
    if (h < 17) {
      return 'Good Afternoon';
    }
    return 'Good Evening';
  }

  String _dynamicQuote() {
    const List<String> quotes = <String>[
      'Small steps every day lead to big changes.',
      'Your future is built by what you do today.',
      'Consistency beats intensity over time.',
      'Take care of your body, and your mind will follow.',
      'Progress, not perfection, wins every time.',
      'Show up for yourself today.',
    ];
    final DateTime now = DateTime.now();
    final DateTime jan1 = DateTime(now.year, 1, 1);
    final int dayIndex = now.difference(jan1).inDays;
    return quotes[dayIndex % quotes.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FitupUser? user = ref.watch(authStateProvider).maybeWhen(
          data: (FitupUser? u) => u,
          orElse: () => null,
        );
    final AsyncValue<FitcoinWallet> fitcoinWallet =
        ref.watch(fitcoinWalletStreamProvider);
    final NumberFormat fcFmt = NumberFormat('#,###');
    final String balance = fitcoinWallet.maybeWhen(
      data: (FitcoinWallet w) => fcFmt.format(w.balance),
      orElse: () => '—',
    );
    final String greeting = _greetingLabel();
    final String quoteLine = quote ?? _dynamicQuote();

    return Column(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const FitupLogo(size: 34),
            const SizedBox(width: 10),
            Text(
              'Fitup',
              style: AppTextStyles.headlineLarge.copyWith(fontSize: 24),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  ...actions,
                  if (actions.isNotEmpty) const SizedBox(width: 6),
                  if (!kIsWeb)
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer.withValues(
                              alpha: 0.6,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Image.asset(
                                'assets/images/fitcoins.png',
                                width: 20,
                                height: 20,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.monetization_on_outlined,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$balance FC',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                greeting.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.secondary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Hello, ${_firstName(user)}',
                style: AppTextStyles.headlineLarge.copyWith(fontSize: 40),
              ),
              const SizedBox(height: 8),
              Text(
                '"$quoteLine"',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
