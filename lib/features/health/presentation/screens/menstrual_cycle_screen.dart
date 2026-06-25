import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/menstrual_cycle.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../health_ui_models.dart';
import '../providers/health_providers.dart';

Color _phaseColor(MenstrualPhase p) {
  return switch (p) {
    MenstrualPhase.period => AppColors.tertiaryContainer,
    MenstrualPhase.fertile => AppColors.secondary,
    MenstrualPhase.ovulation => AppColors.secondaryDim,
    MenstrualPhase.none => AppColors.surfaceContainerHighest,
  };
}

/// Calendar + log period for cycle tracking (persisted via [HealthRepository]).
class MenstrualCycleScreen extends ConsumerStatefulWidget {
  const MenstrualCycleScreen({super.key});

  @override
  ConsumerState<MenstrualCycleScreen> createState() =>
      _MenstrualCycleScreenState();
}

class _MenstrualCycleScreenState extends ConsumerState<MenstrualCycleScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final DateTime n = DateTime.now();
    _month = DateTime(n.year, n.month);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<MenstrualCycle>> history =
        ref.watch(menstrualHistoryProvider);

    return history.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Menstrual cycle', style: AppTextStyles.headlineMedium),
          backgroundColor: AppColors.surfaceContainer,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (Object _, StackTrace __) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Menstrual cycle', style: AppTextStyles.headlineMedium),
          backgroundColor: AppColors.surfaceContainer,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load cycle history.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (List<MenstrualCycle> cycles) {
        final MenstrualStateData state = menstrualStateFromHistory(cycles);
        return _buildBody(context, state);
      },
    );
  }

  Widget _buildBody(BuildContext context, MenstrualStateData state) {
    final int daysInMonth =
        DateTime(_month.year, _month.month + 1, 0).day;
    final int firstWeekday = DateTime(_month.year, _month.month, 1).weekday;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Menstrual cycle', style: AppTextStyles.headlineMedium),
        backgroundColor: AppColors.surfaceContainer,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _logSheet(context, ref),
        backgroundColor: AppColors.tertiary,
        foregroundColor: AppColors.onSurface,
        icon: const Icon(Icons.add),
        label: Text('Log Period', style: AppTextStyles.labelLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() {
                  _month = DateTime(_month.year, _month.month - 1);
                }),
              ),
              Text(
                DateFormat.yMMMM().format(_month),
                style: AppTextStyles.headlineMedium,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() {
                  _month = DateTime(_month.year, _month.month + 1);
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              for (final String d in <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                  child: Center(
                    child: Text(d, style: AppTextStyles.labelSmall),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: firstWeekday - 1 + daysInMonth,
            itemBuilder: (BuildContext context, int i) {
              if (i < firstWeekday - 1) {
                return const SizedBox.shrink();
              }
              final int day = i - (firstWeekday - 1) + 1;
              final DateTime cell = DateTime(_month.year, _month.month, day);
              final MenstrualPhase ph = menstrualPhaseFor(state, cell);
              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: _phaseColor(ph),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: ph == MenstrualPhase.none
                          ? AppColors.onSurfaceVariant
                          : AppColors.onSurface,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text('Summary', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Average cycle length (estimate): 28 days',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Next predicted start: ${DateFormat.MMMd().format(
              state.cycleAnchor.add(const Duration(days: 28)),
            )}',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          _LegendRow(
            color: AppColors.tertiaryContainer,
            label: 'Period',
          ),
          _LegendRow(color: AppColors.secondary, label: 'Fertile window'),
          _LegendRow(color: AppColors.secondaryDim, label: 'Predicted ovulation'),
        ],
      ),
    );
  }

  Future<void> _logSheet(BuildContext context, WidgetRef ref) async {
    DateTime start = DateTime.now();
    String flow = 'Medium';
    final List<String> symptoms = <String>[];
    final TextEditingController notes = TextEditingController();
    final List<String> options = <String>[
      'Cramps',
      'Bloating',
      'Headache',
      'Mood swings',
      'Fatigue',
      'Spotting',
    ];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerHigh,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setS) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text('Log period', style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () async {
                        final DateTime? d = await showDatePicker(
                          context: context,
                          initialDate: start,
                          firstDate: DateTime(2022),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) {
                          setS(() => start = d);
                        }
                      },
                      child: Text(
                        'Start: ${DateFormat.yMMMd().format(start)}',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Flow', style: AppTextStyles.labelSmall),
                    Row(
                      children: <String>['Light', 'Medium', 'Heavy']
                          .map(
                            (String f) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(f),
                                selected: flow == f,
                                onSelected: (_) => setS(() => flow = f),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    Text('Symptoms', style: AppTextStyles.labelSmall),
                    Wrap(
                      spacing: 8,
                      children: options.map((String s) {
                        final bool on = symptoms.contains(s);
                        return FilterChip(
                          label: Text(s),
                          selected: on,
                          onSelected: (bool v) {
                            setS(() {
                              if (v) {
                                symptoms.add(s);
                              } else {
                                symptoms.remove(s);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notes,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Notes (optional)',
                        filled: true,
                        fillColor: AppColors.surfaceContainer,
                      ),
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: NeonButton(
                        label: 'Save',
                        onPressed: () async {
                          final Either<Failure, MenstrualCycle> r = await ref
                              .read(menstrualCycleLogProvider.notifier)
                              .saveCycleLog(
                                startDate: start,
                                flowIntensityLabel: flow,
                                symptoms: List<String>.from(symptoms),
                                notes: notes.text.trim().isEmpty
                                    ? null
                                    : notes.text.trim(),
                              );
                          if (!ctx.mounted) {
                            return;
                          }
                          r.fold(
                            (Failure f) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    f.message ?? 'Could not save period',
                                  ),
                                ),
                              );
                            },
                            (_) => Navigator.pop(ctx),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: <Widget>[
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
