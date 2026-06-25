import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/vital_reference.dart';
import '../../domain/entities/vital_status.dart';
import '../../domain/entities/vital_type.dart';
import '../../domain/entities/vital_type_extension.dart';
import '../health_ui_models.dart';
import '../providers/health_providers.dart';
import '../widgets/vital_status_colors.dart';
import '../widgets/vital_trend_chart.dart';

VitalType vitalTypeFromPathParam(String? raw) {
  if (raw == null || raw.isEmpty) {
    return VitalType.fastingBloodSugar;
  }
  for (final VitalType t in VitalType.values) {
    if (t.name == raw) {
      return t;
    }
  }
  return VitalType.fastingBloodSugar;
}

/// Trend + history for one [VitalType].
class VitalTrendScreen extends ConsumerStatefulWidget {
  const VitalTrendScreen({super.key, required this.type});

  final VitalType type;

  @override
  ConsumerState<VitalTrendScreen> createState() => _VitalTrendScreenState();
}

class _VitalTrendScreenState extends ConsumerState<VitalTrendScreen> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final VitalType type = widget.type;
    final AsyncValue<List<VitalReadingEntry>> asyncList = ref.watch(
      vitalReadingsForTypeProvider(type),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(type.displayName, style: AppTextStyles.headlineMedium),
        backgroundColor: AppColors.surfaceContainer,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/health/vitals/log?type=${type.name}'),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.background,
        icon: const Icon(Icons.add),
        label: const Text('Add reading'),
      ),
      body: asyncList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object _, StackTrace __) => Center(
          child: Text(
            'Could not load readings.',
            style: AppTextStyles.bodyMedium,
          ),
        ),
        data: (List<VitalReadingEntry> all) {
          final List<VitalReadingEntry> chartAsc = all.length <= 30
              ? all.reversed.toList()
              : all.sublist(0, 30).reversed.toList();
          final List<VitalReadingEntry> history10 = all.take(10).toList();
          final VitalReadingEntry? latest = all.isEmpty ? null : all.first;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              SizedBox(
                height: 220,
                child: VitalTrendChart(
                  type: type,
                  entriesAscending: chartAsc,
                  touchedIndex: _touchedIndex,
                  onTouch: (int i) => setState(() => _touchedIndex = i),
                ),
              ),
              if (latest != null) ...<Widget>[
                const SizedBox(height: 16),
                _LatestCard(type: type, entry: latest),
              ],
              const SizedBox(height: 20),
              Text('History', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 8),
              if (history10.isEmpty)
                Text('No entries yet.', style: AppTextStyles.bodySmall)
              else
                ...history10.map(
                  (VitalReadingEntry e) => _HistoryRow(
                    type: type,
                    entry: e,
                    onDelete: () => _confirmDelete(context, e.id),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String vitalEntryId) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text('Delete reading?', style: AppTextStyles.headlineMedium),
        content: Text(
          'This cannot be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AppTextStyles.labelLarge),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: AppTextStyles.labelLarge),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final bool deleted = await ref
          .read(vitalLoggerProvider.notifier)
          .deleteVital(vitalEntryId);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deleted ? 'Reading deleted' : 'Could not delete reading',
          ),
        ),
      );
    }
  }
}

class _LatestCard extends StatelessWidget {
  const _LatestCard({required this.type, required this.entry});

  final VitalType type;
  final VitalReadingEntry entry;

  @override
  Widget build(BuildContext context) {
    final VitalStatus st = statusForReading(type, entry.value);
    final String statusLabel = switch (st) {
      VitalStatus.normal => 'Normal',
      VitalStatus.borderline => 'Borderline',
      VitalStatus.elevated => 'Elevated',
      VitalStatus.unknown => '—',
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Latest', style: AppTextStyles.labelSmall),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                entry.value.toStringAsFixed(
                  entry.value == entry.value.roundToDouble() ? 0 : 1,
                ),
                style: AppTextStyles.headlineLarge.copyWith(fontSize: 36),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(type.unit, style: AppTextStyles.bodyLarge),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: vitalStatusColor(st).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(statusLabel, style: AppTextStyles.labelSmall),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat.yMMMd().add_jm().format(entry.recordedAt),
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.type,
    required this.entry,
    required this.onDelete,
  });

  final VitalType type;
  final VitalReadingEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final VitalStatus st = statusForReading(type, entry.value);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 10,
        height: 10,
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: vitalStatusColor(st),
        ),
      ),
      title: Text(
        '${entry.value.toStringAsFixed(entry.value == entry.value.roundToDouble() ? 0 : 1)} ${type.unit}',
        style: AppTextStyles.bodyLarge,
      ),
      subtitle: Text(
        DateFormat.yMMMd().add_jm().format(entry.recordedAt),
        style: AppTextStyles.bodySmall,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        color: AppColors.onSurfaceVariant,
        onPressed: onDelete,
      ),
    );
  }
}
