import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/fitup_chip.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../domain/entities/emergency_contact.dart';
import '../../domain/entities/profile_enums.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/profile_providers.dart';

/// Edit profile — HTML prototype sections; saves via [EditProfileNotifier].
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  UserProfile? _draft;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _height = TextEditingController();
  final TextEditingController _weight = TextEditingController();
  final TextEditingController _targetW = TextEditingController();
  final TextEditingController _meds = TextEditingController();
  final TextEditingController _dailySteps = TextEditingController();
  final TextEditingController _dailyCalories = TextEditingController();
  final TextEditingController _dailySleep = TextEditingController();
  final TextEditingController _dailyWater = TextEditingController();
  final TextEditingController _dailyWorkout = TextEditingController();
  DateTime? _targetWeightDate;

  static const List<String> _cuisines = <String>[
    'Indian',
    'Italian',
    'Chinese',
    'Mexican',
    'Mediterranean',
  ];
  static const List<String> _allergies = <String>[
    'Nuts',
    'Dairy',
    'Gluten',
    'Shellfish',
  ];
  static const List<String> _conditions = <String>[
    'Diabetes',
    'Hypertension',
    'Thyroid',
    'Asthma',
    'PCOS',
  ];
  final DateFormat _displayDateFmt = DateFormat('dd MMM yyyy');
  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _height.dispose();
    _weight.dispose();
    _targetW.dispose();
    _meds.dispose();
    _dailySteps.dispose();
    _dailyCalories.dispose();
    _dailySleep.dispose();
    _dailyWater.dispose();
    _dailyWorkout.dispose();
    super.dispose();
  }

  void _syncFrom(UserProfile p) {
    _draft = p;
    _name.text = p.displayName ?? '';
    _phone.text = p.phone ?? '';
    _height.text = p.heightCm?.toStringAsFixed(0) ?? '';
    _weight.text = p.weightKg?.toStringAsFixed(1) ?? '';
    _targetW.text = p.targetWeightKg?.toStringAsFixed(1) ?? '';
    _targetWeightDate = p.targetWeightDate;
    _meds.text = p.medicationsNote;
    _dailySteps.text = p.dailyStepGoal?.toString() ?? '';
    _dailyCalories.text = p.dailyCalorieGoal?.toString() ?? '';
    _dailySleep.text = p.dailySleepGoalMinutes?.toString() ?? '';
    _dailyWater.text = p.dailyWaterGoalMl?.toString() ?? '';
    _dailyWorkout.text = p.dailyWorkoutGoalMinutes?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<UserProfile> async = ref.watch(userProfileProvider);
    final AsyncValue<void> saveState = ref.watch(editProfileNotifierProvider);

    return async.when(
      data: (UserProfile p) {
        if (_draft == null || _draft!.userId != p.userId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _syncFrom(p));
            }
          });
        }
        final UserProfile d = _draft ?? p;
        return _scaffold(context, d, p, saveState);
      },
      loading: () => const ColoredBox(
        color: AppColors.background,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryContainer),
        ),
      ),
      error: (Object e, _) => ColoredBox(
        color: AppColors.background,
        child: Center(child: Text('$e')),
      ),
    );
  }

  Widget _scaffold(
    BuildContext context,
    UserProfile d,
    UserProfile base,
    AsyncValue<void> saveState,
  ) {
    final bool saving = saveState.isLoading;
    return ColoredBox(
      color: AppColors.background,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.onSurfaceVariant),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Edit Profile',
            style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: saving
                  ? null
                  : () async {
                      final UserProfile next = d.copyWith(
                        displayName: _name.text.trim().isEmpty
                            ? null
                            : _name.text.trim(),
                        phone: _phone.text.trim().isEmpty
                            ? null
                            : _phone.text.trim(),
                        heightCm: double.tryParse(_height.text),
                        weightKg: double.tryParse(_weight.text),
                        targetWeightKg: double.tryParse(_targetW.text),
                        targetWeightDate: _targetWeightDate,
                        medicationsNote: _meds.text,
                        dailyStepGoal: int.tryParse(_dailySteps.text),
                        dailyCalorieGoal: int.tryParse(_dailyCalories.text),
                        dailySleepGoalMinutes: int.tryParse(_dailySleep.text),
                        dailyWaterGoalMl: int.tryParse(_dailyWater.text),
                        dailyWorkoutGoalMinutes:
                            int.tryParse(_dailyWorkout.text),
                        updatedAt: DateTime.now(),
                      );
                      await ref
                          .read(editProfileNotifierProvider.notifier)
                          .updateProfile(next);
                      if (!context.mounted) {
                        return;
                      }
                      final AsyncValue<void> st =
                          ref.read(editProfileNotifierProvider);
                      if (st.hasError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              st.error.toString(),
                            ),
                          ),
                        );
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile updated')),
                      );
                      context.pop();
                    },
              child: saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Save',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: <Widget>[
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: <Widget>[
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.surfaceContainerHighest,
                    backgroundImage: d.photoUrl != null
                        ? NetworkImage(d.photoUrl!)
                        : null,
                    child: d.photoUrl == null
                        ? const Icon(Icons.person, size: 48)
                        : null,
                  ),
                  Material(
                    color: AppColors.primaryContainer,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, size: 18),
                      color: AppColors.background,
                      onPressed: () => _pickAvatar(context, base.userId),
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeader(label: 'Basic info'),
            TextField(
              controller: _name,
              style: AppTextStyles.bodyLarge,
              decoration: _input('Display name'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              enabled: false,
              controller: TextEditingController(text: d.email),
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              decoration: _input('Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              style: AppTextStyles.bodyLarge,
              decoration: _input('Phone'),
              onChanged: (_) => setState(() {}),
            ),
            const SectionHeader(label: 'Body stats'),
            Row(
              children: ProfileGender.values.map((ProfileGender g) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FitupChip(
                      label: _genderL(g),
                      selected: d.gender == g,
                      onTap: () => setState(() {
                        _draft = d.copyWith(gender: g);
                      }),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                d.dateOfBirth == null
                    ? 'Date of birth'
                    : _displayDateFmt.format(d.dateOfBirth!),
                style: AppTextStyles.bodyLarge,
              ),
              trailing: const Icon(Icons.calendar_month, color: AppColors.secondary),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: d.dateOfBirth ?? DateTime(1995),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _draft = d.copyWith(dateOfBirth: picked));
                }
              },
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _height,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.bodyLarge,
                    decoration: _input(
                      d.useMetricUnits
                          ? 'Height in centimeters (cm)'
                          : 'Height',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _weight,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.bodyLarge,
                    decoration: _input(
                      d.useMetricUnits ? 'Weight in kilograms (kg)' : 'Weight',
                    ),
                  ),
                ),
              ],
            ),
            const SectionHeader(label: 'Daily goals (for AI planning)'),
            TextField(
              controller: _targetW,
              keyboardType: TextInputType.number,
              style: AppTextStyles.bodyLarge,
              decoration: _input('Target weight (kg)'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _targetWeightDate == null
                    ? 'Target date for target weight'
                    : 'Target date: ${_displayDateFmt.format(_targetWeightDate!)}',
                style: AppTextStyles.bodyLarge,
              ),
              trailing: const Icon(
                Icons.event_outlined,
                color: AppColors.secondary,
              ),
              onTap: () async {
                final DateTime now = DateTime.now();
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _targetWeightDate ?? now.add(const Duration(days: 90)),
                  firstDate: DateTime(now.year, now.month, now.day),
                  lastDate: DateTime(now.year + 5),
                );
                if (picked != null) {
                  setState(() {
                    _targetWeightDate = picked;
                  });
                }
              },
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _targetWeightDate = null;
                  });
                },
                child: const Text('Clear target date'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _dailySteps,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: AppTextStyles.bodyLarge,
              decoration: _input('Daily steps goal (e.g. 8000)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dailyCalories,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: AppTextStyles.bodyLarge,
              decoration: _input('Daily calorie intake goal (kcal)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dailySleep,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: AppTextStyles.bodyLarge,
              decoration: _input('Daily sleep goal (minutes)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dailyWater,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: AppTextStyles.bodyLarge,
              decoration: _input('Daily water intake goal (ml)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dailyWorkout,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: AppTextStyles.bodyLarge,
              decoration: _input('Daily workout duration goal (minutes)'),
            ),
            const SectionHeader(label: 'Health goals'),
            GlassCard(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HealthGoal.values.map((HealthGoal g) {
                  final bool sel = d.goals.contains(g);
                  return FitupChip(
                    label: g.title,
                    selected: sel,
                    onTap: () {
                      final List<HealthGoal> next = List<HealthGoal>.from(d.goals);
                      if (sel) {
                        if (next.length > 1) {
                          next.remove(g);
                        }
                      } else {
                        next.add(g);
                      }
                      setState(() => _draft = d.copyWith(goals: next));
                    },
                  );
                }).toList(),
              ),
            ),
            const SectionHeader(label: 'Diet preferences'),
            GlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 8,
                    children: DietType.values.map((DietType t) {
                      return FitupChip(
                        label: t.label,
                        selected: d.dietType == t,
                        onTap: () => setState(() => _draft = d.copyWith(dietType: t)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _cuisines.map((String c) {
                      final bool sel = d.cuisines.contains(c);
                      return FitupChip(
                        label: c,
                        selected: sel,
                        onTap: () {
                          final List<String> n = List<String>.from(d.cuisines);
                          if (sel) {
                            n.remove(c);
                          } else {
                            n.add(c);
                          }
                          setState(() => _draft = d.copyWith(cuisines: n));
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _allergies.map((String a) {
                      final bool sel = d.allergies.contains(a);
                      return FitupChip(
                        label: a,
                        selected: sel,
                        selectedColor: AppColors.tertiary,
                        onTap: () {
                          final List<String> n = List<String>.from(d.allergies);
                          if (sel) {
                            n.remove(a);
                          } else {
                            n.add(a);
                          }
                          setState(() => _draft = d.copyWith(allergies: n));
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Row(
              children: <Widget>[
                TextButton.icon(
                  onPressed: () => _showConditionSheet(context, d),
                  icon: const Icon(Icons.add, color: AppColors.tertiary),
                  label: Text(
                    'Add condition',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.tertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SectionHeader(label: 'Health conditions & meds'),
            GlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: <Widget>[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _conditions.map((String c) {
                      final bool sel = d.healthConditions.contains(c);
                      return FitupChip(
                        label: c,
                        selected: sel,
                        selectedColor: AppColors.tertiary,
                        onTap: () {
                          final List<String> n = List<String>.from(d.healthConditions);
                          if (sel) {
                            n.remove(c);
                          } else {
                            n.add(c);
                          }
                          setState(() => _draft = d.copyWith(healthConditions: n));
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _meds,
                    maxLines: 3,
                    style: AppTextStyles.bodyLarge,
                    decoration: _input('Medications / notes'),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const SectionHeader(label: 'Emergency contacts'),
            GlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextField(
                    decoration: const InputDecoration(labelText: 'Name'),
                    style: AppTextStyles.bodyLarge,
                    controller: TextEditingController(
                      text: d.emergencyContacts.isNotEmpty
                          ? d.emergencyContacts.first.name
                          : '',
                    ),
                    onChanged: (String v) {
                      final List<EmergencyContact> list =
                          List<EmergencyContact>.from(d.emergencyContacts);
                      if (list.isEmpty) {
                        list.add(EmergencyContact(name: v, phone: '', relationship: 'Friend'));
                      } else {
                        list[0] = list.first.copyWith(name: v);
                      }
                      setState(() => _draft = d.copyWith(emergencyContacts: list));
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                    style: AppTextStyles.bodyLarge,
                    controller: TextEditingController(
                      text: d.emergencyContacts.isNotEmpty
                          ? d.emergencyContacts.first.phone
                          : '',
                    ),
                    onChanged: (String v) {
                      final List<EmergencyContact> list =
                          List<EmergencyContact>.from(d.emergencyContacts);
                      if (list.isEmpty) {
                        list.add(EmergencyContact(name: '', phone: v, relationship: 'Friend'));
                      } else {
                        list[0] = list.first.copyWith(phone: v);
                      }
                      setState(() => _draft = d.copyWith(emergencyContacts: list));
                    },
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () {
                final List<EmergencyContact> list =
                    List<EmergencyContact>.from(d.emergencyContacts);
                if (list.length >= 2) {
                  return;
                }
                list.add(
                  const EmergencyContact(
                    name: '',
                    phone: '',
                    relationship: 'Friend',
                  ),
                );
                setState(() => _draft = d.copyWith(emergencyContacts: list));
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.glassBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                '+ Add another contact',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            const SectionHeader(label: 'Progress photos (private)'),
            Row(
              children: <String>['front', 'side', 'back'].map((String slot) {
                return Expanded(
                  child: _PhotoSlot(
                    label: slot,
                    url: d.progressPhotoUrls[slot],
                    onTap: () => _pickProgress(context, base.userId, slot),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _input(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium,
      filled: true,
      fillColor: AppColors.surfaceContainer.withValues(alpha: 0.6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.glassBorder),
      ),
    );
  }

  String _genderL(ProfileGender g) => switch (g) {
        ProfileGender.male => 'Male',
        ProfileGender.female => 'Female',
        ProfileGender.other => 'Other',
      };

  Future<void> _pickAvatar(BuildContext context, String uid) async {
    final XFile? x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x == null) {
      return;
    }
    final Uint8List bytes = await x.readAsBytes();
    final String mime = x.mimeType ?? 'image/jpeg';
    await ref.read(profileRepositoryProvider).uploadAvatar(uid, bytes, mime);
  }

  Future<void> _pickProgress(
    BuildContext context,
    String uid,
    String slot,
  ) async {
    final XFile? x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x == null) {
      return;
    }
    final Uint8List bytes = await x.readAsBytes();
    final String mime = x.mimeType ?? 'image/jpeg';
    await ref
        .read(profileRepositoryProvider)
        .uploadProgressPhoto(uid, slot, bytes, mime);
  }

  void _showConditionSheet(BuildContext context, UserProfile d) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: _conditions
                .where((String c) => !d.healthConditions.contains(c))
                .map(
                  (String c) => ListTile(
                    title: Text(c, style: AppTextStyles.bodyLarge),
                    onTap: () {
                      final List<String> n = List<String>.from(d.healthConditions)
                        ..add(c);
                      setState(() => _draft = d.copyWith(healthConditions: n));
                      Navigator.pop(ctx);
                    },
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.label,
    required this.url,
    required this.onTap,
  });

  final String label;
  final String? url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: DottedBorderBox(
            child: url != null
                ? Image.network(url!, fit: BoxFit.cover)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.add, color: AppColors.onSurfaceVariant),
                      Text(
                        label,
                        style: AppTextStyles.labelSmall,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Simple dashed border placeholder.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
