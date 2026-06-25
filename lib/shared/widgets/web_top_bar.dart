import 'dart:ui' as ui show TextDirection;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/fitcoins/domain/entities/fitcoin_wallet.dart';
import '../../features/community/presentation/providers/community_providers.dart';

/// Sticky top bar for tablet/desktop shell — scrolling quote ticker + balance + profile.
class WebTopBar extends ConsumerWidget {
  const WebTopBar({
    super.key,
    required this.moduleLabel,
    this.onSearchTap,
  });

  final String moduleLabel;
  final VoidCallback? onSearchTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FitcoinWallet> walletAsync =
        ref.watch(fitcoinWalletStreamProvider);
    final NumberFormat fc = NumberFormat('#,###');
    final String balance = walletAsync.when(
      data: (FitcoinWallet w) => fc.format(w.balance),
      loading: () => '…',
      error: (_, _) => '—',
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant, width: 0.5),
        ),
      ),
      child: SizedBox(
        height: 60,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: <Widget>[
              Text(
                moduleLabel,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 1,
                height: 22,
                color: AppColors.outlineVariant,
              ),
              const SizedBox(width: 16),
              const Expanded(child: _QuoteTicker()),
              const SizedBox(width: 16),
              Tooltip(
                message: 'Fitcoin balance',
                child: InkWell(
                  onTap: () => context.push('/community/wallet'),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.primaryContainer
                            .withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.monetization_on_outlined,
                          size: 16,
                          color: AppColors.primaryContainer,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$balance FC',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Profile',
                child: IconButton(
                  icon: const Icon(Icons.account_circle_outlined),
                  color: AppColors.onSurfaceVariant,
                  onPressed: () => context.push('/profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuoteTicker extends StatefulWidget {
  const _QuoteTicker();

  @override
  State<_QuoteTicker> createState() => _QuoteTickerState();
}

class _QuoteTickerState extends State<_QuoteTicker>
    with SingleTickerProviderStateMixin {
  static const List<String> _quotes = <String>[
    'Small steps every day lead to big changes.',
    'Your future is built by what you do today.',
    'Consistency beats intensity over time.',
    'Take care of your body — your mind will follow.',
    'Progress, not perfection, wins every time.',
    'Show up for yourself today.',
    'Discipline is the bridge between goals and accomplishment.',
    'A healthy outside starts from the inside.',
    'You don\'t have to be extreme, just consistent.',
    'The only bad workout is the one you didn\'t do.',
    'Hydrate. Move. Rest. Repeat.',
    'Your body hears everything your mind says — speak kindly.',
  ];

  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String stripText = _quotes
        .map((String q) => '✦  $q')
        .join('     ');
    return ClipRect(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final TextPainter painter = TextPainter(
            text: TextSpan(
              text: stripText,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
                letterSpacing: 0.4,
              ),
            ),
            textDirection: ui.TextDirection.ltr,
            maxLines: 1,
          )..layout();
          final double textW = painter.size.width;
          final double totalW = textW + 80; // gap between loops
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (BuildContext context, _) {
              final double dx = -totalW * _ctrl.value;
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: <Widget>[
                  Transform.translate(
                    offset: Offset(dx, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _strip(stripText),
                        SizedBox(width: 80),
                        _strip(stripText),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _strip(String text) {
    return SizedBox(
      height: 60,
      child: Center(
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
