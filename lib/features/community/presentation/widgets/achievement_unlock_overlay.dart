import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../fitcoins/domain/entities/fitcoin_transaction.dart';
import '../providers/community_providers.dart';
import 'achievement_material_icon.dart';

/// Full-screen celebration with particle burst (no Lottie).
class AchievementUnlockOverlay extends StatefulWidget {
  const AchievementUnlockOverlay({
    super.key,
    required this.payload,
    required this.onDismiss,
    required this.onShareToFeed,
  });

  final AchievementCelebrationPayload payload;
  final VoidCallback onDismiss;
  final VoidCallback onShareToFeed;

  @override
  State<AchievementUnlockOverlay> createState() =>
      _AchievementUnlockOverlayState();
}

class _AchievementUnlockOverlayState extends State<AchievementUnlockOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background.withValues(alpha: 0.92),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _c,
              builder: (BuildContext context, Widget? child) {
                return CustomPaint(
                  painter: _ParticleBurstPainter(progress: _c.value),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    achievementIconDataForCodePoint(widget.payload.iconCodePoint),
                    size: 88,
                    color: AppColors.primary,
                    shadows: <Shadow>[
                      Shadow(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.payload.title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineLarge.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '+${widget.payload.fcAmount} FC Earned',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.primaryContainer,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: widget.onShareToFeed,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.background,
                    ),
                    child: Text(
                      'Share to Feed',
                      style: AppTextStyles.labelLarge,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: widget.onDismiss,
                    child: Text(
                      'Dismiss',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticleBurstPainter extends CustomPainter {
  _ParticleBurstPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final math.Random r = math.Random(42);
    final Offset c = Offset(size.width / 2, size.height * 0.35);
    for (int i = 0; i < 48; i++) {
      final double angle = r.nextDouble() * math.pi * 2;
      final double dist = 40 + r.nextDouble() * 180 * progress;
      final Offset p = c + Offset(math.cos(angle), math.sin(angle)) * dist;
      final Paint paint = Paint()
        ..color = (i.isEven ? AppColors.secondary : AppColors.primary)
            .withValues(alpha: 0.35 * (1 - progress * 0.6))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(p, 2 + r.nextDouble() * 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Listens to ledger updates and stacks [AchievementUnlockOverlay].
class AchievementUnlockHost extends ConsumerWidget {
  const AchievementUnlockHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<List<FitcoinTransaction>>>(
      fitcoinLedgerStreamProvider,
      (
        AsyncValue<List<FitcoinTransaction>>? previous,
        AsyncValue<List<FitcoinTransaction>> next,
      ) {
        next.whenData((List<FitcoinTransaction> list) {
          ref.read(achievementCelebrationProvider.notifier).evaluateLedger(list);
        });
      },
    );

    final AchievementCelebrationPayload? payload =
        ref.watch(achievementCelebrationProvider);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        child,
        if (payload != null)
          Positioned.fill(
            child: AchievementUnlockOverlay(
              payload: payload,
              onDismiss: () =>
                  ref.read(achievementCelebrationProvider.notifier).clear(),
              onShareToFeed: () {
                ref.read(achievementCelebrationProvider.notifier).clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Shared to feed (coming soon)'),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
