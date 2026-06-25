import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../services/subscription_service.dart';
import '../../../../shared/widgets/glass_card.dart';

/// fitup PRO paywall — native billing; web shows availability message only.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() =>
      _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _annual = true;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.onBackground,
            tooltip: 'Back',
            onPressed: () => context.pop(),
          ),
          title: Text('fitup PRO', style: AppTextStyles.headlineMedium),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: GlassCard(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Subscriptions and in-app purchases are available on the '
                'iOS and Android apps.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: <Widget>[
          Positioned(
            top: -120,
            right: -40,
            child: IgnorePointer(
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      AppColors.primaryContainer.withValues(alpha: 0.14),
                      AppColors.secondary.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.onBackground,
                      onPressed: () => context.pop(),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 8),
                ShaderMask(
                  shaderCallback: (Rect b) =>
                      AppColors.secondaryToPrimaryGradient.createShader(b),
                  child: Text(
                    'fitup PRO',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.onBackground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Holistic insights, advanced AI, and priority support.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'Compare',
                        style: AppTextStyles.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      const _CompareRow(
                        label: 'Weekly AI holistic report',
                        freeOk: true,
                        proOk: true,
                      ),
                      const _CompareRow(
                        label: 'Advanced AI coaching',
                        freeOk: false,
                        proOk: true,
                      ),
                      const _CompareRow(
                        label: 'Priority support',
                        freeOk: false,
                        proOk: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _PlanCard(
                  title: 'Monthly',
                  price: '₹499',
                  sub: 'per month',
                  selected: !_annual,
                  highlight: false,
                  onTap: () => setState(() => _annual = false),
                ),
                const SizedBox(height: 12),
                _PlanCard(
                  title: 'Annual',
                  price: '₹3,999',
                  sub: 'per year · save 33%',
                  selected: _annual,
                  highlight: true,
                  onTap: () => setState(() => _annual = true),
                ),
                const SizedBox(height: 28),
                _PrimaryCta(
                  loading: _loading,
                  onPressed: _onStartPro,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _onRestore,
                  child: Text(
                    'Restore purchases',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onStartPro() async {
    setState(() => _loading = true);
    final Either<Failure, Unit> r =
        await getIt<SubscriptionService>().launchSubscriptionFlow();
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
    r.fold(
      (Failure f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$f')),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks — subscription flow completed.')),
        );
      },
    );
  }

  Future<void> _onRestore() async {
    setState(() => _loading = true);
    final Either<Failure, Unit> r =
        await getIt<SubscriptionService>().restorePurchases();
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
    r.fold(
      (Failure f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$f')),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored.')),
        );
      },
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({
    required this.label,
    required this.freeOk,
    required this.proOk,
  });

  final String label;
  final bool freeOk;
  final bool proOk;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(
            child: Center(
              child: Icon(
                freeOk ? Icons.check_rounded : Icons.close_rounded,
                color: freeOk ? AppColors.secondary : AppColors.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Icon(
                proOk ? Icons.check_rounded : Icons.close_rounded,
                color: proOk ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.sub,
    required this.selected,
    required this.highlight,
    required this.onTap,
  });

  final String title;
  final String price;
  final String sub;
  final bool selected;
  final bool highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      label: '$title $price',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? AppColors.primaryContainer
                    : AppColors.glassBorder,
                width: selected ? 2 : 1,
              ),
              color: highlight
                  ? AppColors.primaryContainer.withValues(alpha: 0.06)
                  : AppColors.surfaceContainer.withValues(alpha: 0.5),
              boxShadow: selected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: AppColors.primaryContainer.withValues(
                          alpha: 0.35,
                        ),
                        blurRadius: 24,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: AppTextStyles.headlineMedium),
                      const SizedBox(height: 4),
                      Text(sub, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                Text(
                  price,
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.35),
            blurRadius: 24,
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: AppColors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          onPressed: loading ? null : onPressed,
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Start Pro'),
        ),
      ),
    );
  }
}
