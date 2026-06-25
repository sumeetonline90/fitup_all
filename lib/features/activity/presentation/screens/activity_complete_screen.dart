import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../services/logger_service.dart';
import '../../../../services/models/ai_insight.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../domain/entities/activity.dart';
import '../providers/activity_providers.dart';
import '../widgets/activity_session_bento.dart';
import '../widgets/activity_session_metrics.dart';

/// Post-activity summary — map route, bento stats, fitcoins, AI insight.
class ActivityCompleteScreen extends ConsumerStatefulWidget {
  const ActivityCompleteScreen({
    super.key,
    required this.activity,
    this.fitcoinsEarned = 0,
  });

  final Activity activity;
  final int fitcoinsEarned;

  @override
  ConsumerState<ActivityCompleteScreen> createState() =>
      _ActivityCompleteScreenState();
}

class _ActivityCompleteScreenState
    extends ConsumerState<ActivityCompleteScreen> {
  bool _aiLoading = false;
  AiInsight? _aiInsight;
  String? _aiError;

  String _formatDuration(int seconds) {
    final int h = seconds ~/ 3600;
    final int m = (seconds % 3600) ~/ 60;
    final int s = seconds % 60;
    if (h > 0) {
      return '${h}h ${m}m ${s}s';
    }
    return '${m}m ${s}s';
  }

  Future<void> _loadAiInsight() async {
    if (_aiLoading) return;
    setState(() {
      _aiLoading = true;
      _aiError = null;
    });
    try {
      final Activity a = widget.activity;
      final AiInsight insight = await ref.read(
        activityInsightProvider(
          'Post-activity summary for ${a.type.label}: '
          '${ActivitySessionMetrics.distanceLabel(a.type, a.distanceMeters)} in '
          '${_formatDuration(a.durationSeconds)}',
        ).future,
      );
      if (mounted) {
        setState(() {
          _aiInsight = insight;
          _aiLoading = false;
        });
      }
    } catch (e, st) {
      LoggerService.e('ActivityComplete AI insight', e, st);
      if (mounted) {
        setState(() {
          _aiError = 'Could not load AI insight';
          _aiLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Activity a = widget.activity;
    final double km = a.distanceMeters / 1000;
    final int fitcoins =
        widget.fitcoinsEarned > 0 ? widget.fitcoinsEarned : 10;
    final DateFormat timeFmt = DateFormat('hh:mm a');
    final String firstName = activitySummaryFirstName(ref);
    final String locName = ActivitySessionMetrics.locationSubtitle(
      a.type,
      a.routePoints.length,
    );

    final Widget scroll = CustomScrollView(
      slivers: <Widget>[
            const SliverToBoxAdapter(child: ActivitySummaryTopRow()),
            SliverToBoxAdapter(
              child: ActivitySessionHeadline(
                badge: 'SESSION COMPLETE',
                headline: ActivitySessionMetrics.headline(a.type, firstName),
              ),
            ),
            SliverToBoxAdapter(
              child: ActivitySessionMapCard(
                routePoints: a.routePoints,
                activityType: a.type,
                locationName: locName,
                height: 220,
              ),
            ),
            SliverToBoxAdapter(
              child: ActivitySessionBentoGrid(
                type: a.type,
                durationSeconds: a.durationSeconds,
                distanceMeters: a.distanceMeters,
                caloriesBurnt: a.caloriesBurnt,
                steps: a.steps,
                avgPaceMinPerKm: a.avgPace,
                avgSpeedKmh: a.avgSpeed,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: GlassCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Session',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _MiniTime(
                              label: 'Start',
                              value: timeFmt.format(a.startTime),
                            ),
                          ),
                          Expanded(
                            child: _MiniTime(
                              label: 'End',
                              value: a.endTime != null
                                  ? timeFmt.format(a.endTime!)
                                  : '—',
                            ),
                          ),
                        ],
                      ),
                      if (a.gpsDropSeconds > 0) ...<Widget>[
                        const SizedBox(height: 12),
                        Text(
                          'GPS: ${a.gpsDropInterruptions} interruptions '
                          '(${a.gpsDropSeconds}s)',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: fitcoins.toDouble()),
                  duration: const Duration(milliseconds: 900),
                  builder: (BuildContext context, double v, Widget? child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.primaryContainer.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.stars_rounded,
                            color: AppColors.primaryContainer,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+${v.round()} Fitcoins',
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: AppColors.primaryContainer,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: GlassCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'AI Coach Insights',
                              style: AppTextStyles.headlineMedium.copyWith(
                                fontSize: 18,
                              ),
                            ),
                          ),
                          if (_aiInsight == null && !_aiLoading)
                            IconButton(
                              onPressed: _loadAiInsight,
                              icon: const Icon(Icons.auto_awesome_rounded),
                              color: AppColors.secondary,
                              tooltip: 'Get AI insight',
                            ),
                        ],
                      ),
                      if (_aiLoading) ...<Widget>[
                        const SizedBox(height: 12),
                        const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ] else if (_aiInsight != null) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          _aiInsight!.summary,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ] else if (_aiError != null) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          _aiError!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ] else ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          'Tap the sparkle icon for feedback on this activity.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await Share.share(
                            'Fitup: ${a.type.label} — '
                            '${km.toStringAsFixed(1)} km in ${_formatDuration(a.durationSeconds)} '
                            '• ${a.caloriesBurnt.round()} kcal burned',
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: BorderSide(
                            color: AppColors.secondary.withValues(alpha: 0.35),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          'Share',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NeonButton(
                        label: 'Done',
                        onPressed: () {
                          ref
                              .read(lastActivitySessionResultProvider.notifier)
                              .clear();
                          ref.invalidate(recentTrackedActivitiesProvider);
                          context.go('/activity');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
    );

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: kIsWeb
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: scroll,
                ),
              )
            : scroll,
      ),
    );
  }
}

class _MiniTime extends StatelessWidget {
  const _MiniTime({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.headlineMedium.copyWith(fontSize: 16),
        ),
      ],
    );
  }
}
