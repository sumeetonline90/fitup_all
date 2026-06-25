import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/responsive_grid.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../auth/domain/entities/fitup_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/equipment.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_user_profile.dart';
import '../providers/workout_providers.dart';

/// Multi-step AI plan generator wired to [GeneratePlanNotifier].
class WorkoutPlanGeneratorScreen extends ConsumerStatefulWidget {
  const WorkoutPlanGeneratorScreen({super.key});

  @override
  ConsumerState<WorkoutPlanGeneratorScreen> createState() =>
      _WorkoutPlanGeneratorScreenState();
}

class _WorkoutPlanGeneratorScreenState
    extends ConsumerState<WorkoutPlanGeneratorScreen> {
  final PageController _page = PageController();
  int _step = 0;

  final Set<String> _goals = <String>{};
  String _level = 'Intermediate';
  final Set<String> _equipment = <String>{};
  double _daysPerWeek = 4;
  bool _loading = false;
  bool _error = false;
  bool _preview = false;
  WorkoutPlan? _generatedPlan;

  static const List<String> _goalOptions = <String>[
    'Weight Loss',
    'Muscle Gain',
    'Endurance',
    'Strength',
    'Flexibility',
    'General Fitness',
  ];

  static const List<String> _equipmentOptions = <String>[
    'No Equipment',
    'Dumbbells',
    'Barbell',
    'Resistance Bands',
    'Pull-up Bar',
    'Bench',
    'Cables',
    'Full Gym',
  ];

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final AsyncValue<FitupUser?> auth = ref.read(authStateProvider);
    final FitupUser? user = auth.maybeWhen(
      data: (FitupUser? u) => u,
      orElse: () => null,
    );
    if (user == null) {
      setState(() {
        _loading = false;
        _error = true;
      });
      return;
    }
    if (_goals.isEmpty) {
      setState(() {
        _loading = false;
        _error = true;
      });
      return;
    }
    final Either<Failure, WorkoutPlan> r =
        await ref.read(generatePlanProvider.notifier).generate(
              profile: () {
                final profile = ref.read(userProfileProvider).value;
                final int? age = profile?.dateOfBirth == null
                    ? null
                    : DateTime.now().year - profile!.dateOfBirth!.year;
                final String targetWeightText = profile?.targetWeightKg != null
                    ? 'Target weight: ${profile!.targetWeightKg!.toStringAsFixed(1)} kg'
                    : '';
                final String targetDateText = profile?.targetWeightDate != null
                    ? 'Target date: ${profile!.targetWeightDate!.toLocal().toString().split(' ').first}'
                    : '';
                final String notes = <String>[
                  targetWeightText,
                  targetDateText,
                ].where((String s) => s.isNotEmpty).join(' | ');
                return WorkoutUserProfile(
                  userId: user.id,
                  age: age,
                  weightKg: profile?.weightKg,
                  heightCm: profile?.heightCm,
                  healthConditions: profile?.healthConditions ?? const <String>[],
                  notes: notes.isEmpty ? null : notes,
                );
              }(),
              goals: _goals.toList(),
              equipment: _selectionToEquipment(_equipment),
              fitnessLevel: _level,
              daysPerWeek: _daysPerWeek.round(),
            );
    if (!mounted) {
      return;
    }
    r.fold(
      (Failure _) {
        setState(() {
          _loading = false;
          _error = true;
        });
      },
      (WorkoutPlan plan) {
        setState(() {
          _loading = false;
          _preview = true;
          _generatedPlan = plan;
        });
      },
    );
  }

  List<Equipment> _selectionToEquipment(Set<String> raw) {
    if (raw.isEmpty) {
      return <Equipment>[Equipment.none];
    }
    final List<Equipment> out = <Equipment>[];
    for (final String s in raw) {
      final Equipment? e = _parseEquipment(s);
      if (e != null) {
        out.add(e);
      }
    }
    return out.isEmpty ? <Equipment>[Equipment.none] : out;
  }

  Equipment? _parseEquipment(String s) {
    final String lower = s.toLowerCase();
    if (lower.contains('no equipment')) {
      return Equipment.none;
    }
    if (lower.contains('dumbbell')) {
      return Equipment.dumbbells;
    }
    if (lower.contains('barbell')) {
      return Equipment.barbell;
    }
    if (lower.contains('band')) {
      return Equipment.resistanceBand;
    }
    if (lower.contains('pull')) {
      return Equipment.pullupBar;
    }
    if (lower.contains('bench')) {
      return Equipment.bench;
    }
    if (lower.contains('cable')) {
      return Equipment.cables;
    }
    if (lower.contains('full gym')) {
      return Equipment.gym;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Plan generator', style: AppTextStyles.headlineMedium),
        leading: Semantics(
          button: true,
          label: 'Back',
          child: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: _loading
          ? _buildLoading()
          : _error
              ? _buildError()
              : _preview
                  ? _buildPreview()
                  : Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: List<Widget>.generate(5, (int i) {
                              final bool done = i <= _step;
                              return Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  child: Semantics(
                                    label: 'Step ${i + 1} of 5',
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        color: done
                                            ? AppColors.secondary
                                            : AppColors.surfaceContainerHighest,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        Expanded(
                          child: PageView(
                            controller: _page,
                            onPageChanged: (int i) =>
                                setState(() => _step = i),
                            children: <Widget>[
                              _stepGoals(),
                              _stepLevel(),
                              _stepEquipment(),
                              _stepSchedule(),
                              _stepSummary(),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: <Widget>[
                              if (_step > 0)
                                TextButton(
                                  onPressed: () {
                                    _page.previousPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    );
                                  },
                                  child: Text(
                                    'Back',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              if (_step < 4)
                                NeonButton(
                                  label: 'Next',
                                  onPressed: () {
                                    _page.nextPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const ShimmerLoading(height: 120, borderRadius: 20),
            const SizedBox(height: 20),
            Text(
              'AI is building your plan…',
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(
                'Pick at least one goal and try again.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              NeonButton(
                label: 'Retry',
                icon: Icons.refresh,
                onPressed: () => setState(() => _error = false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final WorkoutPlan? p = _generatedPlan;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: <Widget>[
          Text('Your plan preview', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 12),
          GlassCard(
            child: Text(
              p == null
                  ? 'Plan ready.'
                  : '${p.name} · ${p.sessions.length} sessions · '
                      '${_daysPerWeek.round()}×/week · $_level',
              style: AppTextStyles.bodyMedium,
            ),
          ),
          const SizedBox(height: 20),
          NeonButton(
            label: 'Activate plan',
            icon: Icons.check_circle_outline,
            onPressed: () {
              ref.invalidate(activeWorkoutPlanProvider);
              context.pop(true);
            },
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() {
              _preview = false;
              _generatedPlan = null;
            }),
            child: Text(
              'Edit selections',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepGoals() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text('Goals', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 8),
        Text('Select all that apply', style: AppTextStyles.bodySmall),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _goalOptions.map((String g) {
            final bool sel = _goals.contains(g);
            return Semantics(
              button: true,
              label: g,
              selected: sel,
              child: FilterChip(
                label: Text(g, style: AppTextStyles.labelSmall),
                selected: sel,
                onSelected: (bool v) {
                  setState(() {
                    if (v) {
                      _goals.add(g);
                    } else {
                      _goals.remove(g);
                    }
                  });
                },
                selectedColor: AppColors.secondary.withValues(alpha: 0.25),
                checkmarkColor: AppColors.secondary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _stepLevel() {
    const List<({String title, String desc, IconData icon})> levels =
        <({String title, String desc, IconData icon})>[
      (
        title: 'Beginner',
        desc: 'New to lifting or returning after a long break.',
        icon: Icons.fitness_center_outlined,
      ),
      (
        title: 'Intermediate',
        desc: 'Comfortable with compound lifts and progression.',
        icon: Icons.trending_up,
      ),
      (
        title: 'Expert',
        desc: 'Structured training history and high volume tolerance.',
        icon: Icons.bolt_outlined,
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text('Fitness level', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 16),
        ...levels.map((({String title, String desc, IconData icon}) l) {
          final bool sel = _level == l.title;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Semantics(
              button: true,
              label: '${l.title}. ${l.desc}',
              selected: sel,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => setState(() => _level = l.title),
                child: GlassCard(
                  glowColor: sel ? AppColors.secondary : null,
                  child: Row(
                    children: <Widget>[
                      Icon(l.icon, color: AppColors.secondary, size: 36),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(l.title, style: AppTextStyles.headlineMedium.copyWith(
                                  fontSize: 18,
                                )),
                            Text(l.desc, style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                      if (sel)
                        const Icon(Icons.check_circle, color: AppColors.secondary),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _stepEquipment() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text('Equipment', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 8),
        Text('What do you have access to?', style: AppTextStyles.bodySmall),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount:
              responsiveColumns(context, mobile: 2, tablet: 3, desktop: 4, wide: 5),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.4,
          children: _equipmentOptions.map((String e) {
            final bool sel = _equipment.contains(e);
            return Semantics(
              button: true,
              label: e,
              selected: sel,
              child: FilterChip(
                label: Text(e, style: AppTextStyles.bodySmall),
                selected: sel,
                onSelected: (bool v) {
                  setState(() {
                    if (v) {
                      _equipment.add(e);
                    } else {
                      _equipment.remove(e);
                    }
                  });
                },
                selectedColor: AppColors.secondary.withValues(alpha: 0.25),
                checkmarkColor: AppColors.secondary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _stepSchedule() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text('Schedule', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'How many days per week?',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(
          '${_daysPerWeek.round()} days',
          style: AppTextStyles.headlineMedium,
        ),
        Slider(
          value: _daysPerWeek,
          min: 2,
          max: 6,
          divisions: 4,
          label: '${_daysPerWeek.round()}',
          activeColor: AppColors.secondary,
          onChanged: (double v) => setState(() => _daysPerWeek = v),
        ),
        Text(
          '3–4 days is optimal for most goals.',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }

  Widget _stepSummary() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text('Review', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Goals: ${_goals.isEmpty ? '—' : _goals.join(', ')}',
                  style: AppTextStyles.bodyMedium),
              Text('Level: $_level', style: AppTextStyles.bodyMedium),
              Text(
                'Equipment: ${_equipment.isEmpty ? 'Any' : _equipment.join(', ')}',
                style: AppTextStyles.bodyMedium,
              ),
              Text(
                'Days/week: ${_daysPerWeek.round()}',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Semantics(
          button: true,
          label: 'Generate my workout plan',
          child: NeonButton(
            label: 'Generate my plan',
            icon: Icons.auto_awesome,
            onPressed: _generate,
          ),
        ),
      ],
    );
  }
}
