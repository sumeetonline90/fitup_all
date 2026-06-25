import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/equipment.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/exercise_type.dart';
import '../../domain/entities/muscle_group.dart';
import '../providers/workout_providers.dart';

/// Searchable exercise catalog from [ExerciseRepository].
class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String _muscle = 'All';
  String _equip = 'Any';

  static const List<String> _muscles = <String>[
    'All',
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Core',
    'Legs',
    'Cardio',
  ];

  static const List<String> _equips = <String>[
    'Any',
    'No Equipment',
    'Dumbbells',
    'Barbell',
    'Gym',
  ];

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearch);
  }

  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _query = _search.text.trim());
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  MuscleGroup? _muscleFilter() {
    switch (_muscle) {
      case 'Chest':
        return MuscleGroup.chest;
      case 'Back':
        return MuscleGroup.back;
      case 'Shoulders':
        return MuscleGroup.shoulders;
      case 'Arms':
        return null;
      case 'Core':
        return MuscleGroup.core;
      case 'Legs':
        return MuscleGroup.quadriceps;
      case 'Cardio':
        return null;
      default:
        return null;
    }
  }

  Equipment? _equipFilter() {
    switch (_equip) {
      case 'No Equipment':
        return Equipment.none;
      case 'Dumbbells':
        return Equipment.dumbbells;
      case 'Barbell':
        return Equipment.barbell;
      case 'Gym':
        return Equipment.gym;
      default:
        return null;
    }
  }

  bool _matchesArmMuscle(Exercise e) {
    return e.muscleGroups.any(
      (MuscleGroup m) =>
          m == MuscleGroup.biceps ||
          m == MuscleGroup.triceps ||
          m == MuscleGroup.forearms,
    );
  }

  bool _matchesCardio(Exercise e) {
    return e.name.toLowerCase().contains('run') ||
        e.name.toLowerCase().contains('jump') ||
        e.type == WorkoutExerciseType.cardio;
  }

  List<Exercise> _applyLocalFilters(List<Exercise> list) {
    return list.where((Exercise e) {
      if (_muscle == 'Arms' && !_matchesArmMuscle(e)) {
        return false;
      }
      if (_muscle == 'Cardio' && !_matchesCardio(e)) {
        return false;
      }
      if (_muscle == 'Legs') {
        final bool leg = e.muscleGroups.any(
          (MuscleGroup m) =>
              m == MuscleGroup.quadriceps ||
              m == MuscleGroup.hamstrings ||
              m == MuscleGroup.glutes ||
              m == MuscleGroup.calves,
        );
        if (!leg) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ExerciseLibraryParams params = ExerciseLibraryParams(
      muscleGroup: _muscle == 'All' ? null : _muscleFilter(),
      equipment: _equip == 'Any' ? null : _equipFilter(),
      limit: 80,
    );

    final AsyncValue<List<Exercise>> libraryAsync =
        ref.watch(exerciseLibraryProvider(params));
    final AsyncValue<List<Exercise>> searchAsync =
        ref.watch(exerciseSearchProvider(_query));

    final List<Exercise> raw = _query.isNotEmpty
        ? searchAsync.maybeWhen(
            data: (List<Exercise> list) => list,
            orElse: () => <Exercise>[],
          )
        : libraryAsync.maybeWhen(
            data: (List<Exercise> list) => list,
            orElse: () => <Exercise>[],
          );
    final List<Exercise> filtered = _applyLocalFilters(raw);

    final bool loading = _query.isNotEmpty
        ? searchAsync.isLoading
        : libraryAsync.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Exercise library', style: AppTextStyles.headlineMedium),
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
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _search,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search exercises…',
                hintStyle: AppTextStyles.bodyMedium,
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.secondary),
                filled: true,
                fillColor: AppColors.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: _muscles.map((String m) {
                final bool sel = _muscle == m;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Semantics(
                    button: true,
                    label: 'Filter $m',
                    selected: sel,
                    child: FilterChip(
                      label: Text(m, style: AppTextStyles.labelSmall),
                      selected: sel,
                      onSelected: (_) => setState(() => _muscle = m),
                      selectedColor:
                          AppColors.secondary.withValues(alpha: 0.25),
                      checkmarkColor: AppColors.secondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              children: _equips.map((String m) {
                final bool sel = _equip == m;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Semantics(
                    button: true,
                    label: 'Equipment filter $m',
                    selected: sel,
                    child: FilterChip(
                      label: Text(m, style: AppTextStyles.labelSmall),
                      selected: sel,
                      onSelected: (_) => setState(() => _equip = m),
                      selectedColor:
                          AppColors.tertiary.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.tertiary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No exercises match filters.',
                          style: AppTextStyles.bodyMedium,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (BuildContext context, int i) {
                          final Exercise e = filtered[i];
                          return Semantics(
                            button: true,
                            label: '${e.name}, ${e.difficulty.name}',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => context.push(
                                '/workout/exercises/${e.id}',
                              ),
                              child: GlassCard(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            e.name,
                                            style: AppTextStyles.bodyLarge,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            e.difficulty.name,
                                            style: AppTextStyles.labelSmall,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 4,
                                      children: e.muscleGroups
                                          .map(
                                            (MuscleGroup m) => Text(
                                              m.name,
                                              style: AppTextStyles.bodySmall,
                                            ),
                                          )
                                          .toList(),
                                    ),
                                    Text(
                                      '~${e.caloriesPerMinute.toStringAsFixed(1)} kcal/min',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
