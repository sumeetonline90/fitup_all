import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../health_ui_models.dart';
import '../providers/health_providers.dart';
import '../widgets/medication_card.dart';

/// List medications + add via bottom sheet.
class MedicationScreen extends ConsumerWidget {
  const MedicationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<MedicationUi>> medsAsync =
        ref.watch(activeMedicationsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Medications', style: AppTextStyles.headlineMedium),
        backgroundColor: AppColors.surfaceContainer,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context, ref),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.background,
        icon: const Icon(Icons.add),
        label: Text('Add Medication', style: AppTextStyles.labelLarge),
      ),
      body: medsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object _, StackTrace __) => Center(
          child: Text(
            'Could not load medications.',
            style: AppTextStyles.bodyMedium,
          ),
        ),
        data: (List<MedicationUi> meds) => ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            if (meds.isEmpty)
              Text('No active medications.', style: AppTextStyles.bodyMedium)
            else
              ...meds.map(
                (MedicationUi m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: MedicationCard(
                    medication: m,
                    onLongPress: () => _confirmDelete(context, ref, m),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    MedicationUi m,
  ) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text('Remove ${m.name}?', style: AppTextStyles.headlineMedium),
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
      ref.read(medicationProvider.notifier).deleteMedication(m.id);
    }
  }

  static Future<void> _openAddSheet(BuildContext context, WidgetRef ref) async {
    final TextEditingController name = TextEditingController();
    final TextEditingController dose = TextEditingController();
    final TextEditingController freq = TextEditingController();
    TimeOfDay? reminder;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerHigh,
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: StatefulBuilder(
            builder: (BuildContext context, void Function(void Function()) setS) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text('Add Medication', style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 16),
                    TextField(
                      controller: name,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        labelStyle: AppTextStyles.bodySmall,
                        filled: true,
                        fillColor: AppColors.surfaceContainer,
                      ),
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dose,
                      decoration: InputDecoration(
                        labelText: 'Dose',
                        labelStyle: AppTextStyles.bodySmall,
                        filled: true,
                        fillColor: AppColors.surfaceContainer,
                      ),
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: freq,
                      decoration: InputDecoration(
                        labelText: 'Frequency',
                        labelStyle: AppTextStyles.bodySmall,
                        filled: true,
                        fillColor: AppColors.surfaceContainer,
                      ),
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () async {
                        final TimeOfDay? t = await showTimePicker(
                          context: context,
                          initialTime: reminder ?? TimeOfDay.now(),
                        );
                        if (t != null) {
                          setS(() => reminder = t);
                        }
                      },
                      child: Text(
                        reminder == null
                            ? 'Reminder time (optional)'
                            : 'Reminder: ${reminder!.format(context)}',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: NeonButton(
                        label: 'Save',
                        onPressed: () async {
                          if (name.text.trim().isEmpty) {
                            return;
                          }
                          DateTime? rt;
                          if (reminder != null) {
                            final DateTime n = DateTime.now();
                            rt = DateTime(
                              n.year,
                              n.month,
                              n.day,
                              reminder!.hour,
                              reminder!.minute,
                            );
                          }
                          await ref
                              .read(medicationProvider.notifier)
                              .addMedication(
                                name: name.text.trim(),
                                dose: dose.text.trim().isEmpty
                                    ? '—'
                                    : dose.text.trim(),
                                frequency: freq.text.trim().isEmpty
                                    ? 'As needed'
                                    : freq.text.trim(),
                                reminderTime: rt,
                              );
                          if (context.mounted) {
                            Navigator.pop(ctx);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
