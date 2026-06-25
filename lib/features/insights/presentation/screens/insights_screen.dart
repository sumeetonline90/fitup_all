import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_app_bar.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../domain/entities/correlation_alert.dart';
import '../../domain/entities/goal_adjustment.dart';
import '../../domain/entities/weekly_report.dart';
import '../providers/insights_providers.dart';
import '../widgets/correlation_alert_card.dart';
import '../widgets/daily_briefing_card.dart';

/// AI Insights hub: briefing, alerts, chat & weekly entry points.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<CorrelationAlert>> alerts = ref.watch(
      activeAlertsProvider,
    );
    final AsyncValue<WeeklyReport> weekly = ref.watch(weeklyReportProvider);
    final AsyncValue<GoalAdjustment?> goalAdj = ref.watch(
      goalAdjustmentProvider,
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: 'AI Insights',
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(Icons.auto_awesome, color: AppColors.primary),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: <Widget>[
          const DailyBriefingCard(),
          const SizedBox(height: 24),
          Row(
            children: <Widget>[
              Text(
                'Cross-Module Insights',
                style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
              ),
              const SizedBox(width: 8),
              alerts.when(
                data: (List<CorrelationAlert> list) {
                  if (list.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${list.length}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          alerts.when(
            data: (List<CorrelationAlert> list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'All your modules look balanced 🎉',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.primaryContainer,
                    ),
                  ),
                );
              }
              return Column(
                children: list.map((CorrelationAlert a) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Dismissible(
                      key: Key(a.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) =>
                          ref.read(activeAlertsProvider.notifier).dismiss(a.id),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: AppColors.tertiary.withValues(alpha: 0.25),
                        child: const Text('Dismiss'),
                      ),
                      child: CorrelationAlertCard(
                        alert: a,
                        onDismiss: () => ref
                            .read(activeAlertsProvider.notifier)
                            .dismiss(a.id),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const ShimmerLoading(height: 80),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          _NavGlassCard(
            title: 'Chat with your AI Health Coach',
            subtitle: 'Ask questions with full cross-module context',
            icon: Icons.chat_bubble_outline_rounded,
            onTap: () => context.push('/insights/chat'),
          ),
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'This Week\'s Report',
                  style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 10),
                weekly.when(
                  data: (WeeklyReport r) {
                    if (r.isPlaceholder) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            r.executiveSummary,
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => ref
                                .read(weeklyHolisticReportProvider.notifier)
                                .generateThisWeekReport(),
                            child: const Text('Generate this week'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () =>
                                context.push('/insights/weekly-report'),
                            child: Text(
                              'Open weekly report screen →',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    final String sum = r.executiveSummary;
                    final String short = sum.length > 100
                        ? '${sum.substring(0, 100)}…'
                        : sum;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(short, style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () =>
                              context.push('/insights/weekly-report'),
                          child: Text(
                            'View Full Report →',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const ShimmerLoading(height: 14),
                      const SizedBox(height: 8),
                      const ShimmerLoading(height: 14),
                      const SizedBox(height: 8),
                      Text(
                        'Loading report…',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  error: (Object e, StackTrace _) => Text(
                    'Report unavailable. Pull to retry from the full report.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
          goalAdj.when(
            data: (GoalAdjustment? g) {
              if (g == null) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'AI Suggestion for Your Goal',
                        style: AppTextStyles.headlineMedium.copyWith(
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(g.suggestion, style: AppTextStyles.bodyLarge),
                      const SizedBox(height: 6),
                      Text(g.rationale, style: AppTextStyles.bodySmall),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              ref.invalidate(goalAdjustmentProvider),
                          child: const Text('Got it'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _NavGlassCard extends StatelessWidget {
  const _NavGlassCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        child: Row(
          children: <Widget>[
            Icon(icon, color: AppColors.secondary, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '$title →',
                    style: AppTextStyles.headlineMedium.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
