import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/neon_button.dart';

/// Modal bottom sheet for manual sleep logging.
Future<void> showSleepLogSheet(
  BuildContext context, {
  void Function(DateTime start, DateTime end, int qualityStars)? onSave,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => SleepLogSheet(onSave: onSave),
  );
}

class SleepLogSheet extends StatefulWidget {
  const SleepLogSheet({super.key, this.onSave});

  final void Function(DateTime start, DateTime end, int qualityStars)? onSave;

  @override
  State<SleepLogSheet> createState() => _SleepLogSheetState();
}

class _SleepLogSheetState extends State<SleepLogSheet> {
  DateTime _start = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day - 1,
    23,
  );
  DateTime _end = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
    7,
  );
  double _quality = 4;

  Future<void> _pickDate({required bool isStart}) async {
    final DateTime current = isStart ? _start : _end;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      final DateTime updated = DateTime(
        picked.year,
        picked.month,
        picked.day,
        current.hour,
        current.minute,
      );
      if (isStart) {
        _start = updated;
      } else {
        _end = updated;
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final DateTime current = isStart ? _start : _end;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.secondary,
              surface: AppColors.surfaceContainer,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        final DateTime updated = DateTime(
          current.year,
          current.month,
          current.day,
          picked.hour,
          picked.minute,
        );
        if (isStart) {
          _start = updated;
        } else {
          _end = updated;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (BuildContext context, ScrollController c) {
          return DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: c,
              padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
              children: <Widget>[
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Log sleep', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 20),
                _DateTimeRow(
                  label: 'Sleep start',
                  dateTime: _start,
                  onDateTap: () => _pickDate(isStart: true),
                  onTimeTap: () => _pickTime(isStart: true),
                ),
                const SizedBox(height: 12),
                _DateTimeRow(
                  label: 'Sleep end',
                  dateTime: _end,
                  onDateTap: () => _pickDate(isStart: false),
                  onTimeTap: () => _pickTime(isStart: false),
                ),
                const SizedBox(height: 20),
                Text('Sleep quality', style: AppTextStyles.labelSmall),
                const SizedBox(height: 8),
                _StarSlider(
                  value: _quality,
                  onChanged: (double v) => setState(() => _quality = v),
                ),
                const SizedBox(height: 24),
                Center(
                  child: NeonButton(
                    label: 'Save Sleep',
                    onPressed: () {
                      if (!_end.isAfter(_start)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'End date/time must be after start date/time.',
                            ),
                          ),
                        );
                        return;
                      }
                      widget.onSave?.call(
                        _start,
                        _end,
                        _quality.round().clamp(1, 5),
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({
    required this.label,
    required this.dateTime,
    required this.onDateTap,
    required this.onTimeTap,
  });

  final String label;
  final DateTime dateTime;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations loc = MaterialLocalizations.of(context);
    final String formattedTime = loc.formatTimeOfDay(
      TimeOfDay(hour: dateTime.hour, minute: dateTime.minute),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
    final String formattedDate = MaterialLocalizations.of(
      context,
    ).formatShortDate(dateTime);
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: AppTextStyles.bodyLarge)),
        Wrap(
          spacing: 8,
          children: <Widget>[
            OutlinedButton(
              onPressed: onDateTap,
              child: Text(formattedDate, style: AppTextStyles.labelLarge),
            ),
            TextButton(
              onPressed: onTimeTap,
              child: Text(
                formattedTime,
                style: AppTextStyles.headlineMedium.copyWith(
                  fontSize: 18,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StarSlider extends StatelessWidget {
  const _StarSlider({
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(5, (int i) {
            final int starIndex = i + 1;
            final bool filled = value >= starIndex - 0.5;
            return IconButton(
              tooltip: '$starIndex star${starIndex == 1 ? '' : 's'}',
              onPressed: () => onChanged(starIndex.toDouble()),
              icon: Icon(
                filled ? Icons.star_rounded : Icons.star_outline_rounded,
                color: filled ? AppColors.secondary : AppColors.onSurfaceVariant,
                size: 36,
              ),
            );
          }),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.secondary,
            inactiveTrackColor: AppColors.surfaceContainerHighest,
            thumbColor: AppColors.secondary,
            overlayColor: AppColors.secondary.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: value.clamp(1, 5),
            min: 1,
            max: 5,
            divisions: 4,
            label: '${value.round()}',
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
