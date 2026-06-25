import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../services/logger_service.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/domain/entities/fitup_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/meal.dart';
import '../../domain/entities/meal_type.dart';
import '../providers/diet_providers.dart';

FoodItem _foodItemFromFood(Food f, double grams) {
  final double s = grams / 100.0;
  return FoodItem(
    id: 'line_${f.id}_${DateTime.now().microsecondsSinceEpoch}',
    name: f.name,
    quantity: grams,
    unit: 'g',
    calories: f.caloriesPer100g * s,
    protein: f.proteinPer100g * s,
    carbs: f.carbsPer100g * s,
    fat: f.fatPer100g * s,
    fiber: f.fiberPer100g != null ? f.fiberPer100g! * s : null,
    sodium: f.sodiumPer100g != null ? f.sodiumPer100g! * s : null,
    sugar: f.sugarPer100g != null ? f.sugarPer100g! * s : null,
    barcode: f.barcode,
  );
}

class _PortionOption {
  const _PortionOption(this.label, this.grams);

  final String label;
  final double grams;
}

const List<_PortionOption> _portionOptions = <_PortionOption>[
  _PortionOption('1 Katori', 150),
  _PortionOption('1 Bowl', 250),
  _PortionOption('1 Tablespoon', 15),
  _PortionOption('1 Teaspoon', 5),
  _PortionOption('1 Glass', 240),
  _PortionOption('100 g', 100),
];

/// Extra passed via [GoRouter] when editing an existing meal log.
class MealLogRouteExtra {
  const MealLogRouteExtra({
    required this.meal,
    this.supersededMealIds = const <String>[],
  });

  final Meal meal;
  final List<String> supersededMealIds;

  /// Merges all meals in a slot into one editable meal.
  factory MealLogRouteExtra.forSlot(List<Meal> slotMeals) {
    final Meal primary = slotMeals.first;
    final List<FoodItem> allItems = <FoodItem>[
      for (final Meal m in slotMeals) ...m.foodItems,
    ];
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    for (final FoodItem item in allItems) {
      calories += item.calories;
      protein += item.protein;
      carbs += item.carbs;
      fat += item.fat;
    }
    return MealLogRouteExtra(
      meal: primary.copyWith(
        foodItems: allItems,
        totalCalories: calories,
        totalProtein: protein,
        totalCarbs: carbs,
        totalFat: fat,
      ),
      supersededMealIds: slotMeals.length > 1
          ? slotMeals.skip(1).map((Meal m) => m.id).toList()
          : const <String>[],
    );
  }
}

/// Food search → detail → review with repository-backed data.
class MealLogScreen extends ConsumerStatefulWidget {
  const MealLogScreen({
    super.key,
    required this.initialMealType,
    this.existingMeal,
    this.supersededMealIds = const <String>[],
  });

  final MealType initialMealType;
  final Meal? existingMeal;
  final List<String> supersededMealIds;

  @override
  ConsumerState<MealLogScreen> createState() => _MealLogScreenState();
}

class _MealLogScreenState extends ConsumerState<MealLogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;
  String _query = '';

  _MealLogPhase _phase = _MealLogPhase.search;
  Food? _detailFood;
  double _detailGrams = 100;
  _PortionOption _selectedPortion = _portionOptions.last;
  final List<FoodItem> _lines = <FoodItem>[];
  final TextEditingController _notes = TextEditingController();
  Meal? _editingMeal;
  List<String> _supersededMealIds = const <String>[];

  bool get _isEditing => _editingMeal != null;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _search.addListener(_onSearchChanged);
    _editingMeal = widget.existingMeal;
    _supersededMealIds = widget.supersededMealIds;
    if (_editingMeal != null) {
      _lines.addAll(_editingMeal!.foodItems);
      final String? notes = _editingMeal!.notes;
      if (notes != null && notes.isNotEmpty) {
        _notes.text = notes;
      }
      _phase = _MealLogPhase.review;
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      if (mounted) {
        setState(() => _query = _search.text.trim());
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _tabs.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _openDetail(Food f) {
    setState(() {
      _detailFood = f;
      _detailGrams = 100;
      _selectedPortion = _portionOptions.last;
      _phase = _MealLogPhase.detail;
    });
  }

  void _addLineFromFood(Food f, double grams) {
    setState(() {
      _lines.add(_foodItemFromFood(f, grams));
      _phase = _MealLogPhase.search;
      _detailFood = null;
    });
  }

  double get _totalCal =>
      _lines.fold<double>(0, (double a, FoodItem i) => a + i.calories);

  double get _totalP =>
      _lines.fold<double>(0, (double a, FoodItem i) => a + i.protein);

  double get _totalC =>
      _lines.fold<double>(0, (double a, FoodItem i) => a + i.carbs);

  double get _totalF =>
      _lines.fold<double>(0, (double a, FoodItem i) => a + i.fat);

  Future<void> _openScan() async {
    final Food? f = await context.push<Food?>(
      '/diet/scan?mealType=${widget.initialMealType.name}',
    );
    if (f != null && mounted) {
      _openDetail(f);
    }
  }

  Future<void> _openPhoto() async {
    final List<FoodItem>? picks = await context.push<List<FoodItem>>(
      '/diet/photo/${widget.initialMealType.name}',
    );
    if (picks != null && mounted) {
      setState(() => _lines.addAll(picks));
    }
  }

  Future<void> _saveMeal() async {
    final String? uid = ref.read(authStateProvider).maybeWhen(
          data: (FitupUser? u) => u?.id,
          orElse: () => null,
        );
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign in to save meals.', style: AppTextStyles.bodyLarge),
        ),
      );
      return;
    }
    final String? notes =
        _notes.text.trim().isEmpty ? null : _notes.text.trim();
    final Meal meal = _isEditing
        ? _editingMeal!.copyWith(
            foodItems: List<FoodItem>.from(_lines),
            totalCalories: _totalCal,
            totalProtein: _totalP,
            totalCarbs: _totalC,
            totalFat: _totalF,
            notes: notes,
          )
        : Meal(
            id: 'meal_${DateTime.now().millisecondsSinceEpoch}',
            userId: uid,
            mealType: widget.initialMealType,
            foodItems: List<FoodItem>.from(_lines),
            totalCalories: _totalCal,
            totalProtein: _totalP,
            totalCarbs: _totalC,
            totalFat: _totalF,
            dateTime: DateTime.now(),
            notes: notes,
          );
    final Either<Failure, Meal> r = await ref
        .read(mealLoggerProvider.notifier)
        .logMeal(meal, supersededMealIds: _supersededMealIds);
    if (!mounted) {
      return;
    }
    r.fold(
      (Failure f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              f.message ?? 'Could not save meal',
              style: AppTextStyles.bodyLarge,
            ),
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Meal updated' : 'Meal saved',
              style: AppTextStyles.bodyLarge,
            ),
          ),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/diet');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Food>> searchAsync =
        ref.watch(foodSearchProvider(_query));
    final AsyncValue<List<Food>> recentAsync =
        ref.watch(recentFoodsProvider);
    final AsyncValue<List<Food>> frequentAsync =
        ref.watch(frequentFoodsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          _phase == _MealLogPhase.review
              ? (_isEditing ? 'Edit meal' : 'Review meal')
              : _isEditing
                  ? 'Edit ${widget.initialMealType.label}'
                  : 'Log ${widget.initialMealType.label}',
          style: AppTextStyles.headlineMedium,
        ),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_phase == _MealLogPhase.detail) {
              setState(() {
                _phase = _MealLogPhase.search;
                _detailFood = null;
              });
            } else if (_phase == _MealLogPhase.review) {
              setState(() => _phase = _MealLogPhase.search);
            } else {
              context.pop();
            }
          },
        ),
        actions: <Widget>[
          if (_lines.isNotEmpty && _phase != _MealLogPhase.review)
            TextButton(
              onPressed: () => setState(() => _phase = _MealLogPhase.review),
              child: Text(
                'Review (${_lines.length})',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.secondary,
                ),
              ),
            ),
        ],
      ),
      body: switch (_phase) {
        _MealLogPhase.search => _buildSearch(
            searchAsync: searchAsync,
            recentAsync: recentAsync,
            frequentAsync: frequentAsync,
          ),
        _MealLogPhase.detail => _buildDetail(),
        _MealLogPhase.review => _buildReview(),
      },
    );
  }

  Widget _buildSearch({
    required AsyncValue<List<Food>> searchAsync,
    required AsyncValue<List<Food>> recentAsync,
    required AsyncValue<List<Food>> frequentAsync,
  }) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _search,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Search foods…',
              hintStyle: AppTextStyles.bodyMedium,
              prefixIcon: const Icon(Icons.search, color: AppColors.secondary),
              filled: true,
              fillColor: AppColors.surfaceContainerHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          tabs: const <Tab>[
            Tab(text: 'Search'),
            Tab(text: 'Recent'),
            Tab(text: 'Frequent'),
            Tab(text: 'Scan'),
            Tab(text: 'Photo'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: <Widget>[
              searchAsync.when(
                data: (List<Food> foods) => _foodList(foods),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object e, StackTrace st) {
                  LoggerService.e('MealLog search tab load failed', e, st);
                  return Center(
                    child: Text(
                      'Could not load foods. Please retry.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  );
                },
              ),
              recentAsync.when(
                data: (List<Food> foods) => _foodList(foods),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object e, StackTrace st) {
                  LoggerService.e('MealLog recent tab load failed', e, st);
                  return Center(
                    child: Text(
                      'Could not load foods. Please retry.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  );
                },
              ),
              frequentAsync.when(
                data: (List<Food> foods) => _foodList(foods),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object e, StackTrace st) {
                  LoggerService.e('MealLog frequent tab load failed', e, st);
                  return Center(
                    child: Text(
                      'Could not load foods. Please retry.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  );
                },
              ),
              _scanTab(),
              _photoTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _scanTab() {
    if (kIsWeb) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
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
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.secondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Barcode scanning and photo analysis are available on the mobile app.',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.qr_code_scanner, size: 56, color: AppColors.secondary),
            const SizedBox(height: 12),
            Text(
              'Scan a barcode to look up nutrition.',
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            NeonButton(
              label: 'Open scanner',
              icon: Icons.camera_alt_outlined,
              onPressed: _openScan,
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoTab() {
    if (kIsWeb) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
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
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.secondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Barcode scanning and photo analysis are available on the mobile app.',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.image_outlined, size: 56, color: AppColors.secondary),
            const SizedBox(height: 12),
            Text(
              'Use AI to estimate foods from a photo.',
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            NeonButton(
              label: 'Photo meal',
              icon: Icons.photo_camera_outlined,
              onPressed: _openPhoto,
            ),
          ],
        ),
      ),
    );
  }

  Widget _foodList(List<Food> foods) {
    if (foods.isEmpty) {
      return Center(
        child: Text('No foods to show', style: AppTextStyles.bodyMedium),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: foods.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int i) {
        final Food f = foods[i];
        return Material(
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          child: ListTile(
            title: Text(f.name, style: AppTextStyles.bodyLarge),
            subtitle: Text(
              '${f.brand ?? 'Generic'} · ${f.caloriesPer100g.round()} kcal/100g',
              style: AppTextStyles.bodySmall,
            ),
            trailing: IconButton(
              tooltip: 'Add food',
              icon: const Icon(Icons.add_circle_outline, color: AppColors.secondary),
              onPressed: () => _openDetail(f),
            ),
            onTap: () => _openDetail(f),
          ),
        );
      },
    );
  }

  Widget _buildDetail() {
    final Food f = _detailFood!;
    final double s = _detailGrams / 100;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text(f.name, style: AppTextStyles.headlineMedium),
        if (f.brand != null) Text(f.brand!, style: AppTextStyles.bodySmall),
        const SizedBox(height: 16),
        Text('Common units', style: AppTextStyles.labelSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _portionOptions.map((option) {
            final bool selected = _selectedPortion.label == option.label;
            return ChoiceChip(
              label: Text(
                '${option.label} (≈ ${option.grams.round()} g)',
                style: AppTextStyles.bodySmall,
              ),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _selectedPortion = option;
                  _detailGrams = option.grams;
                });
              },
              selectedColor: AppColors.secondary.withValues(alpha: 0.22),
              backgroundColor: AppColors.surfaceContainerHigh,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text('Serving (grams)', style: AppTextStyles.labelSmall),
        Slider(
          value: _detailGrams.clamp(10, 500),
          min: 10,
          max: 500,
          divisions: 49,
          label: '${_detailGrams.round()} g',
          onChanged: (double v) => setState(() {
            _detailGrams = v;
            _selectedPortion = const _PortionOption('Custom', 0);
          }),
        ),
        const SizedBox(height: 16),
        Text('Nutrition (estimated)', style: AppTextStyles.labelSmall),
        const SizedBox(height: 8),
        _NutRow(
          label: 'Calories',
          value: '${(f.caloriesPer100g * s).round()} kcal',
        ),
        _NutRow(label: 'Protein', value: '${(f.proteinPer100g * s).round()} g'),
        _NutRow(label: 'Carbs', value: '${(f.carbsPer100g * s).round()} g'),
        _NutRow(label: 'Fat', value: '${(f.fatPer100g * s).round()} g'),
        if (f.fiberPer100g != null)
          _NutRow(
            label: 'Fiber',
            value: '${(f.fiberPer100g! * s).round()} g',
          ),
        if (f.sugarPer100g != null)
          _NutRow(
            label: 'Sugar',
            value: '${(f.sugarPer100g! * s).toStringAsFixed(1)} g',
          ),
        if (f.sodiumPer100g != null)
          _NutRow(
            label: 'Sodium',
            value: '${(f.sodiumPer100g! * s).toStringAsFixed(1)} mg',
          ),
        const SizedBox(height: 24),
        NeonButton(
          label: 'Add to ${widget.initialMealType.label}',
          onPressed: () => _addLineFromFood(f, _detailGrams),
        ),
      ],
    );
  }

  Widget _buildReview() {
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              ..._lines.map(
                (FoodItem i) => Dismissible(
                  key: ValueKey<String>(i.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: AppColors.error.withValues(alpha: 0.25),
                    child: const Icon(Icons.delete_outline),
                  ),
                  onDismissed: (_) {
                    setState(() => _lines.remove(i));
                  },
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    title: Text(i.name, style: AppTextStyles.bodyLarge),
                    subtitle: Text(
                      '${i.quantity.round()} ${i.unit} · '
                      '${i.calories.round()} kcal · '
                      'P ${i.protein.round()}g · '
                      'C ${i.carbs.round()}g · '
                      'F ${i.fat.round()}g'
                      '${i.fiber != null ? ' · Fi ${i.fiber!.toStringAsFixed(1)}g' : ''}'
                      '${i.sugar != null ? ' · Su ${i.sugar!.toStringAsFixed(1)}g' : ''}'
                      '${i.sodium != null ? ' · Na ${i.sodium!.toStringAsFixed(1)}mg' : ''}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notes,
                style: AppTextStyles.bodyLarge,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Notes (optional)',
                  hintStyle: AppTextStyles.bodyMedium,
                  filled: true,
                  fillColor: AppColors.surfaceContainerHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withValues(alpha: 0.9),
            border: Border(
              top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Total: ${_totalCal.round()} kcal · '
                'P ${_totalP.round()}g · '
                'C ${_totalC.round()}g · '
                'F ${_totalF.round()}g',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              NeonButton(
                label: _isEditing ? 'Update meal' : 'Save meal',
                icon: Icons.check_rounded,
                onPressed: _saveMeal,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _MealLogPhase { search, detail, review }

class _NutRow extends StatelessWidget {
  const _NutRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: AppTextStyles.bodyMedium),
          Text(value, style: AppTextStyles.bodyLarge),
        ],
      ),
    );
  }
}
