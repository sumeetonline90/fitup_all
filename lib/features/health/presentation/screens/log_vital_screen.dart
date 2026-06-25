import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../domain/entities/vital_category.dart';
import '../../domain/entities/vital_category_extension.dart';
import '../../domain/entities/vital_reference.dart';
import '../../domain/entities/vital_type.dart';
import '../../domain/entities/vital_type_extension.dart';
import '../health_ui_models.dart';
import '../providers/health_providers.dart';

VitalType? vitalTypeFromQueryParam(String? q) {
  if (q == null || q.isEmpty) {
    return null;
  }
  if (q == 'bloodGlucose') {
    return VitalType.fastingBloodSugar;
  }
  for (final VitalType t in VitalType.values) {
    if (t.name == q) {
      return t;
    }
  }
  return null;
}

/// Log a single vital reading.
class LogVitalScreen extends ConsumerStatefulWidget {
  const LogVitalScreen({super.key});

  @override
  ConsumerState<LogVitalScreen> createState() => _LogVitalScreenState();
}

class _LogVitalScreenState extends ConsumerState<LogVitalScreen> {
  late VitalType _type;
  final TextEditingController _valueCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  DateTime _when = DateTime.now();
  VitalLogSource _source = VitalLogSource.manual;

  @override
  void initState() {
    super.initState();
    _type = VitalType.fastingBloodSugar;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String? q = GoRouterState.of(context).uri.queryParameters['type'];
    final VitalType? parsed = vitalTypeFromQueryParam(q);
    if (parsed != null) {
      _type = parsed;
    }
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d == null || !mounted) {
      return;
    }
    final TimeOfDay? t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (t == null || !mounted) {
      return;
    }
    setState(() {
      _when = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  Future<void> _openTypePicker() async {
    final String filter = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.surfaceContainerHigh,
          builder: (BuildContext ctx) {
            final TextEditingController search = TextEditingController();
            return StatefulBuilder(
              builder: (BuildContext context, void Function(void Function()) setM) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.72,
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            controller: search,
                            style: AppTextStyles.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Search vitals…',
                              hintStyle: AppTextStyles.bodySmall,
                              filled: true,
                              fillColor: AppColors.surfaceContainer,
                            ),
                            onChanged: (_) => setM(() {}),
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            children: _groupedTiles(search.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ) ??
        '';
    if (filter.isEmpty) {
      return;
    }
    final VitalType? t = vitalTypeFromQueryParam(filter);
    if (t != null) {
      setState(() => _type = t);
    }
  }

  List<Widget> _groupedTiles(String q) {
    final String lower = q.trim().toLowerCase();
    final List<Widget> out = <Widget>[];
    for (final VitalCategory c in VitalCategory.values) {
      final List<VitalType> types = VitalType.values
          .where((VitalType t) => t.category == c)
          .where(
            (VitalType t) =>
                lower.isEmpty || t.displayName.toLowerCase().contains(lower),
          )
          .toList();
      if (types.isEmpty) {
        continue;
      }
      out.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(c.chipLabel, style: AppTextStyles.labelSmall),
        ),
      );
      for (final VitalType t in types) {
        out.add(
          ListTile(
            title: Text(t.displayName, style: AppTextStyles.bodyMedium),
            subtitle: Text(t.unit, style: AppTextStyles.bodySmall),
            onTap: () => Navigator.pop(context, t.name),
          ),
        );
      }
    }
    return out;
  }

  Future<void> _save() async {
    final double? v = double.tryParse(_valueCtrl.text.trim());
    if (v == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid number.')),
      );
      return;
    }
    final bool ok = await ref.read(vitalLoggerProvider.notifier).logVital(
          type: _type,
          value: v,
          recordedAt: _when,
          source: _source,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
    if (!mounted) {
      return;
    }
    if (ok) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ ${_type.displayName} logged')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Log Vital', style: AppTextStyles.headlineMedium),
        backgroundColor: AppColors.surfaceContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text('Vital', style: AppTextStyles.labelSmall),
          const SizedBox(height: 6),
          InkWell(
            onTap: _openTypePicker,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(_type.displayName, style: AppTextStyles.bodyLarge),
                        Text(
                          _type.category.chipLabel,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Value', style: AppTextStyles.labelSmall),
          const SizedBox(height: 6),
          TextField(
            controller: _valueCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              suffixText: _type.unit,
              suffixStyle: AppTextStyles.bodyMedium,
              filled: true,
              fillColor: AppColors.surfaceContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            referenceHintText(_type),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Text('Date & time', style: AppTextStyles.labelSmall),
          const SizedBox(height: 6),
          OutlinedButton(
            onPressed: _pickDateTime,
            child: Text(
              MaterialLocalizations.of(context).formatFullDate(_when) +
                  ' · ' +
                  TimeOfDay.fromDateTime(_when).format(context),
              style: AppTextStyles.bodyMedium,
            ),
          ),
          const SizedBox(height: 20),
          Text('Source', style: AppTextStyles.labelSmall),
          RadioListTile<VitalLogSource>(
            title: Text('Manual', style: AppTextStyles.bodyMedium),
            value: VitalLogSource.manual,
            groupValue: _source,
            onChanged: (VitalLogSource? v) =>
                setState(() => _source = v ?? VitalLogSource.manual),
          ),
          RadioListTile<VitalLogSource>(
            title: Text('Lab Upload', style: AppTextStyles.bodyMedium),
            value: VitalLogSource.labUpload,
            groupValue: _source,
            onChanged: (VitalLogSource? v) =>
                setState(() => _source = v ?? VitalLogSource.labUpload),
          ),
          const SizedBox(height: 12),
          Text('Notes (optional)', style: AppTextStyles.labelSmall),
          const SizedBox(height: 6),
          TextField(
            controller: _notesCtrl,
            maxLength: 200,
            maxLines: 3,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceContainer,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: NeonButton(
              label: 'Save',
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}
