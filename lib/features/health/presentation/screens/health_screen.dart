import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/responsive_grid.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_app_bar.dart';
import '../../../../shared/widgets/neon_outline_button.dart';
import '../../domain/entities/vital_category.dart';
import '../../domain/entities/vital_category_extension.dart';
import '../../domain/entities/vital_reference_range.dart';
import '../../domain/entities/vital_type_extension.dart';
import '../health_ui_models.dart';
import '../providers/health_providers.dart';
import '../widgets/medication_card.dart';
import '../widgets/vital_tile_card.dart';
import '../../../../shared/widgets/module_top_header.dart';

/// Health & vitals dashboard (bottom nav Health tab).
class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  VitalCategory? _filter;
  _VitalStatusFilter _statusFilter = _VitalStatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<HealthSummaryUi> summaryAsync = ref.watch(
      healthSummaryProvider,
    );
    final AsyncValue<List<MedicationUi>> medsAsync = ref.watch(
      activeMedicationsProvider,
    );
    final AsyncValue<List<VitalReadingEntry>> readingsAsync = ref.watch(
      vitalReadingEntriesProvider,
    );

    return readingsAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (Object _, StackTrace __) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: GradientAppBar(
          title: 'Health & Vitals',
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.photo_camera_outlined),
              tooltip: 'Scan lab report',
              onPressed: () => context.push('/health/lab-scan'),
            ),
          ],
        ),
        body: Center(
          child: Text(
            'Could not load vitals.',
            style: AppTextStyles.bodyMedium,
          ),
        ),
      ),
      data: (List<VitalReadingEntry> allReadings) {
        return summaryAsync.when(
          loading: () => const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (Object _, StackTrace __) => Scaffold(
            backgroundColor: AppColors.background,
            appBar: GradientAppBar(title: 'Health & Vitals'),
            body: Center(
              child: Text(
                'Could not load summary.',
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ),
          data: (HealthSummaryUi summary) {
            return medsAsync.when(
              loading: () => const Scaffold(
                backgroundColor: AppColors.background,
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (Object _, StackTrace __) => _buildScaffold(
                context,
                summary,
                <MedicationUi>[],
                allReadings,
              ),
              data: (List<MedicationUi> meds) =>
                  _buildScaffold(context, summary, meds, allReadings),
            );
          },
        );
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    HealthSummaryUi summary,
    List<MedicationUi> meds,
    List<VitalReadingEntry> allReadings,
  ) {
    final DateTime? lastLab = _lastLabScanDate(allReadings);

    final List<VitalSummaryTile> categoryScoped = _filter == null
        ? List<VitalSummaryTile>.from(summary.tiles)
        : summary.tiles
              .where((VitalSummaryTile t) => t.type.category == _filter)
              .toList();

    final int withDataCount = categoryScoped
        .where((VitalSummaryTile t) => t.hasData && !t.type.isDerived)
        .length;
    final int attentionCount = categoryScoped.where((VitalSummaryTile t) {
      final RangeStatus? rs = _rangeStatusForTile(t);
      return rs != null && rs != RangeStatus.normal;
    }).length;
    final int moderateCount = categoryScoped.where((VitalSummaryTile t) {
      return _rangeStatusForTile(t) == RangeStatus.borderline;
    }).length;
    final int goodCount = categoryScoped.where((VitalSummaryTile t) {
      return _rangeStatusForTile(t) == RangeStatus.normal;
    }).length;

    List<VitalSummaryTile> tiles = categoryScoped;
    if (_statusFilter != _VitalStatusFilter.all) {
      tiles = tiles
          .where(
            (VitalSummaryTile t) => _matchesRangeStatusFilter(t, _statusFilter),
          )
          .toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/health/vitals/log'),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.background,
        icon: const Icon(Icons.add),
        label: Text('Log a Vital', style: AppTextStyles.labelLarge),
      ),
      body: SafeArea(
        top: true,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: <Widget>[
            const ModuleTopHeader(),
            const SizedBox(height: 10),
            if (kIsWeb)
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.sync,
                      color: AppColors.secondary,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            'Health data sync',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Health data is synced automatically from your Fitup mobile app. Open Fitup on your phone to connect Google Health Connect or Apple Health.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (kIsWeb) const SizedBox(height: 10),
            NeonOutlineButton(
              label: 'Health AI',
              onPressed: () => _showHealthInsightSheet(context),
            ),
            const SizedBox(height: 12),
            if (!kIsWeb)
              Row(
                children: <Widget>[
                  Expanded(
                    child: NeonOutlineButton(
                      label: 'Upload Lab PDF',
                      onPressed: () => context.push('/health/lab-scan'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: NeonOutlineButton(
                      label: 'Snap Report',
                      onPressed: () => context.push('/health/lab-scan'),
                    ),
                  ),
                ],
              )
            else
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.phone_android_rounded,
                      color: AppColors.secondary,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            'Available on Mobile',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lab photo scanning requires the mobile app.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '${summary.vitalsLoggedCount} vitals logged · '
              '${summary.needAttentionCount} need attention',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  _CategoryChip(
                    label: 'All',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  for (final VitalCategory c in VitalCategory.values)
                    _CategoryChip(
                      label: c.chipLabel,
                      selected: _filter == c,
                      onTap: () => setState(() => _filter = c),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  _CategoryChip(
                    label: 'Status: All ($withDataCount)',
                    selected: _statusFilter == _VitalStatusFilter.all,
                    onTap: () =>
                        setState(() => _statusFilter = _VitalStatusFilter.all),
                  ),
                  _CategoryChip(
                    label: 'Needs attention ($attentionCount)',
                    selected:
                        _statusFilter == _VitalStatusFilter.needsAttention,
                    onTap: () => setState(
                      () => _statusFilter = _VitalStatusFilter.needsAttention,
                    ),
                  ),
                  _CategoryChip(
                    label: 'Moderate ($moderateCount)',
                    selected: _statusFilter == _VitalStatusFilter.moderate,
                    onTap: () => setState(
                      () => _statusFilter = _VitalStatusFilter.moderate,
                    ),
                  ),
                  _CategoryChip(
                    label: 'Good ($goodCount)',
                    selected: _statusFilter == _VitalStatusFilter.good,
                    onTap: () =>
                        setState(() => _statusFilter = _VitalStatusFilter.good),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: responsiveColumns(context),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: responsiveAspect(context),
              ),
              itemCount: tiles.length,
              itemBuilder: (BuildContext context, int i) {
                final VitalSummaryTile t = tiles[i];
                return VitalTileCard(
                  tile: t,
                  onTap: () => context.push('/health/vitals/${t.type.name}'),
                );
              },
            ),
            const SizedBox(height: 24),
            Text('Medications', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            if (meds.isEmpty)
              Text('No medications yet.', style: AppTextStyles.bodySmall)
            else
              ...meds.map(
                (MedicationUi m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MedicationCard(medication: m),
                ),
              ),
            NeonOutlineButton(
              label: 'Add Medication',
              onPressed: () => context.push('/health/medications'),
            ),
            const SizedBox(height: 24),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Lab Reports', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    lastLab == null
                        ? 'No scans yet'
                        : 'Last scan: ${DateFormat.yMMMd().format(lastLab)}',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  NeonOutlineButton(
                    label: 'Scan New Report',
                    onPressed: () => context.push('/health/lab-scan'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Menstrual Cycle',
                  style: AppTextStyles.headlineMedium,
                ),
                subtitle: Text(
                  'Log periods & view cycle',
                  style: AppTextStyles.bodySmall,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/health/menstrual'),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'This is not medical advice.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static DateTime? _lastLabScanDate(List<VitalReadingEntry> all) {
    DateTime? best;
    for (final VitalReadingEntry e in all) {
      if (e.source != VitalLogSource.labUpload) {
        continue;
      }
      if (best == null || e.recordedAt.isAfter(best)) {
        best = e.recordedAt;
      }
    }
    return best;
  }

  Future<void> _showHealthInsightSheet(BuildContext context) async {
    ref.invalidate(healthInsightProvider);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) => Consumer(
        builder: (BuildContext context, WidgetRef ref, _) {
          final AsyncValue<String> insight = ref.watch(healthInsightProvider);
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.72,
            minChildSize: 0.45,
            maxChildSize: 0.92,
            builder: (BuildContext context, ScrollController controller) {
              return DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.onSurfaceVariant.withValues(
                            alpha: 0.4,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Health AI Insight',
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    insight.when(
                      data: (String text) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(text, style: AppTextStyles.bodyMedium),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            icon: const Icon(Icons.chat_outlined),
                            label: const Text('Ask AI about this'),
                            onPressed: () {
                              Navigator.of(context).pop();
                              context.push(
                                '/insights/chat',
                                extra: <String, String>{
                                  'moduleContext': 'Vitals',
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      loading: () => Shimmer.fromColors(
                        baseColor: AppColors.surfaceContainer,
                        highlightColor: AppColors.surfaceContainerHigh,
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                height: 12,
                                width: double.infinity,
                                color: AppColors.onSurface,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 12,
                                width: double.infinity,
                                color: AppColors.onSurface,
                              ),
                            ],
                          ),
                        ),
                      ),
                      error: (Object _, StackTrace __) => Text(
                        'Insight unavailable.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

enum _VitalStatusFilter { all, needsAttention, moderate, good }

/// Same tiers as [countVitalRangeStats] / headline [HealthSummaryUi.needAttentionCount].
bool _tileParticipatesInRangeFilter(VitalSummaryTile t) {
  return t.hasData && t.latestValue != null && !t.type.isDerived;
}

RangeStatus? _rangeStatusForTile(VitalSummaryTile t) {
  if (!_tileParticipatesInRangeFilter(t)) {
    return null;
  }
  return VitalReferenceRanges.statusFor(t.type, t.latestValue!);
}

bool _matchesRangeStatusFilter(VitalSummaryTile t, _VitalStatusFilter filter) {
  if (filter == _VitalStatusFilter.all) {
    return true;
  }
  final RangeStatus? rs = _rangeStatusForTile(t);
  if (rs == null) {
    return false;
  }
  return switch (filter) {
    _VitalStatusFilter.needsAttention => rs != RangeStatus.normal,
    _VitalStatusFilter.moderate => rs == RangeStatus.borderline,
    _VitalStatusFilter.good => rs == RangeStatus.normal,
    _VitalStatusFilter.all => true,
  };
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: AppTextStyles.labelSmall),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.secondary.withValues(alpha: 0.35),
        checkmarkColor: AppColors.background,
        backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.5),
        side: BorderSide(color: AppColors.glassBorder),
      ),
    );
  }
}
