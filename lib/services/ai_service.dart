import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../core/constants/env_config.dart';
import '../core/database/fitup_database.dart';
import '../core/error/failures.dart';
import 'ai_usage_service.dart';
import '../features/activity/domain/entities/activity.dart';
import '../features/activity/domain/repositories/activity_repository.dart';
import '../features/diet/domain/entities/diet_summary.dart';
import '../features/diet/domain/entities/food_item.dart';
import '../features/diet/domain/entities/meal.dart';
import '../features/diet/domain/repositories/diet_repository.dart';
import '../features/workout/data/parsers/workout_plan_ai_parser.dart';
import '../features/workout/domain/entities/equipment.dart';
import '../features/workout/domain/entities/workout.dart';
import '../features/workout/domain/entities/workout_user_profile.dart';
import '../features/activity/domain/entities/activity_stats.dart';
import '../features/health/data/lab_metric_mapper.dart';
import '../features/health/domain/entities/health_summary.dart';
import '../features/health/domain/entities/health_user_profile_context.dart';
import '../features/health/domain/entities/medication_log.dart';
import '../features/health/domain/entities/vital_entry.dart';
import '../features/health/domain/entities/vital_reference_range.dart';
import '../features/health/domain/entities/vital_type.dart';
import '../features/health/domain/entities/vital_type_extension.dart';
import '../features/insights/domain/entities/chat_message.dart';
import '../features/insights/domain/entities/correlation_alert.dart';
import '../features/insights/domain/entities/holistic_plan.dart';
import '../features/insights/domain/entities/holistic_context.dart';
import '../features/mental_wellbeing/domain/entities/survey_severity.dart';
import '../features/mental_wellbeing/domain/entities/survey_type.dart';
import 'ai_health_prompts.dart';
import 'ai_prompts.dart';
import 'logger_service.dart';
import 'models/ai_insight.dart';
import 'models/diet_plan_suggestion.dart';
import 'models/extracted_vital.dart';
import 'models/meal_analysis_result.dart';
import 'models/weekly_report_content.dart';
import 'holistic_prompt_formatter.dart';
import 'ai_input_sanitizer.dart';
import 'workout_ai_prompt.dart';

/// Gemini Flash (cheap) + Pro (holistic weekly) routing; diet vision on Flash.
class AiService {
  /// Model id for weekly holistic reports (Pro). Tests may assert this constant.
  static const String weeklyHolisticModelId = 'gemini-2.5-pro';

  static const int _labReportMaxOutputTokens = 4096;

  AiService({
    required ActivityRepository activityRepository,
    required DietRepository dietRepository,
    required AiUsageService usageTracker,
    FitupDatabase? database,
  }) : _activityRepository = activityRepository,
       _dietRepository = dietRepository,
       _db = database,
       _usageTracker = usageTracker,
       _flashLiteModel = GenerativeModel(
         model: 'gemini-2.5-flash-lite',
         apiKey: EnvConfig.geminiApiKey,
       ),
       _flashModel = GenerativeModel(
         model: 'gemini-2.5-flash',
         apiKey: EnvConfig.geminiApiKey,
       ),
       _proModel = GenerativeModel(
         model: 'gemini-2.5-pro',
         apiKey: EnvConfig.geminiApiKey,
       );

  final ActivityRepository _activityRepository;
  final DietRepository _dietRepository;
  final FitupDatabase? _db;
  final AiUsageService _usageTracker;
  final GenerativeModel _flashLiteModel;
  final GenerativeModel _flashModel;
  final GenerativeModel _proModel;

  /// Last 7 days of activity context, Flash model.
  Future<AiInsight> getActivityInsight(String userId, String? userQuery) async {
    final DateTime now = DateTime.now();
    final DateTime from = now.subtract(const Duration(days: 7));
    final result = await _activityRepository.getActivities(
      userId,
      from: from,
      to: now,
    );
    final List<Activity> activities = result.fold(
      (Failure _) => <Activity>[],
      (List<Activity> list) => list,
    );
    final String context = _buildActivityContext(activities);
    final String? safeQuery = userQuery != null
        ? AiInputSanitizer.sanitizeContextSnippet(userQuery, maxLength: 500)
        : null;
    final String prompt = AiPrompts.activityInsight(context, safeQuery);
    try {
      final GenerateContentResponse response = await _flashModel
          .generateContent(<Content>[Content.text(prompt)]);
      await _usageTracker.record(
        AiUsageModelKind.flash,
        promptChars: prompt.length,
        responseChars: response.text?.length ?? 0,
      );
      final String? text = response.text;
      if (text == null || text.isEmpty) {
        return _fallbackInsight();
      }
      return _parseAiInsight(text);
    } catch (e, st) {
      LoggerService.e('getActivityInsight', e, st);
      return _fallbackInsight();
    }
  }

  /// Cross-module holistic insight — Flash (Pro reserved for [generateWeeklyReport]).
  Future<AiInsight> getHolisticInsight(String userId) async {
    final DateTime now = DateTime.now();
    final DateTime from = now.subtract(const Duration(days: 7));
    final Either<Failure, Map<String, DietSummary>> dietEither =
        await _dietRepository.getWeeklyNutrition(userId);
    final String dietLine = dietEither.fold(
      (_) => 'Diet: unavailable.',
      (Map<String, DietSummary> m) =>
          'Diet (7d days logged): ${m.length} day summaries.',
    );
    final result = await _activityRepository.getActivities(
      userId,
      from: from,
      to: now,
    );
    final List<Activity> activities = result.fold(
      (Failure _) => <Activity>[],
      (List<Activity> list) => list,
    );
    final String crossModuleContext =
        'Activity (7d): ${_buildActivityContext(activities)}\n$dietLine';
    final String prompt = AiPrompts.holisticInsight(crossModuleContext);
    try {
      final GenerateContentResponse response = await _flashModel
          .generateContent(<Content>[Content.text(prompt)]);
      await _usageTracker.record(
        AiUsageModelKind.flash,
        promptChars: prompt.length,
        responseChars: response.text?.length ?? 0,
      );
      final String? text = response.text;
      if (text == null || text.isEmpty) {
        return _fallbackInsight();
      }
      return _parseAiInsight(text);
    } catch (e, st) {
      LoggerService.e('getHolisticInsight', e, st);
      return _fallbackInsight();
    }
  }

  /// Vision: identify foods and estimate macros (Flash).
  Future<MealAnalysisResult> analyzeMealPhoto(Uint8List imageBytes) async {
    const String prompt =
        'You are a nutrition expert. Identify all food items in this photo. '
        'For each item estimate: name, approximate portion size in grams, calories, '
        'protein (g), carbs (g), fat (g). Focus on Indian cuisine when relevant. '
        'Return JSON only: {"items":[{"name":"...","quantity":100,"unit":"g",'
        '"calories":0,"protein":0,"carbs":0,"fat":0}], "note":"optional"} '
        'Use hedging language in note if needed. Do not diagnose.';
    try {
      final GenerateContentResponse response = await _flashModel
          .generateContent(<Content>[
            Content.multi(<Part>[
              TextPart(prompt),
              DataPart('image/jpeg', imageBytes),
            ]),
          ]);
      await _usageTracker.record(
        AiUsageModelKind.flash,
        promptChars: prompt.length,
        responseChars: response.text?.length ?? 0,
      );
      final String? text = response.text;
      if (text == null || text.isEmpty) {
        return const MealAnalysisResult(items: <FoodItem>[]);
      }
      return _parseMealAnalysisJson(text);
    } catch (e, st) {
      LoggerService.e('analyzeMealPhoto', e, st);
      return const MealAnalysisResult(items: <FoodItem>[]);
    }
  }

  /// Voice / free-text logging.
  Future<List<FoodItem>> parseMealFromText(String userDescription) async {
    final String sanitized = AiInputSanitizer.sanitizeMealDescription(
      userDescription,
    );
    final String prompt =
        'Parse this meal description into food line items with estimated nutrition. '
        'Description: $sanitized\n'
        'Return JSON only: {"items":[{"name":"...","quantity":1,"unit":"serving",'
        '"calories":0,"protein":0,"carbs":0,"fat":0}]} '
        'Focus on Indian foods when appropriate. Do not diagnose.';
    try {
      final GenerateContentResponse response = await _flashModel
          .generateContent(<Content>[Content.text(prompt)]);
      await _usageTracker.record(
        AiUsageModelKind.flash,
        promptChars: prompt.length,
        responseChars: response.text?.length ?? 0,
      );
      final String? text = response.text;
      if (text == null || text.isEmpty) {
        return <FoodItem>[];
      }
      return _parseMealAnalysisJson(text).items;
    } catch (e, st) {
      LoggerService.e('parseMealFromText', e, st);
      return <FoodItem>[];
    }
  }

  /// Cross-module diet narrative (hedging).
  Future<String> getDietInsight({
    required List<Meal> meals,
    required Map<String, String> userGoals,
    required String activityData,
    required String healthData,
  }) async {
    final StringBuffer mealsBuf = StringBuffer();
    for (final Meal m in meals) {
      mealsBuf.writeln(
        '${m.mealType.name}: ${m.totalCalories.toStringAsFixed(0)} kcal, '
        'P ${m.totalProtein.toStringAsFixed(1)} C ${m.totalCarbs.toStringAsFixed(1)} '
        'F ${m.totalFat.toStringAsFixed(1)}',
      );
    }
    final String goalsLine = userGoals.entries
        .map(
          (MapEntry<String, String> e) =>
              '${e.key}:${AiInputSanitizer.sanitizeContextSnippet(e.value, maxLength: 400)}',
        )
        .join('; ');
    final String activitySafe = AiInputSanitizer.sanitizeContextSnippet(
      activityData,
      maxLength: 1200,
    );
    final String healthSafe = AiInputSanitizer.sanitizeContextSnippet(
      healthData,
      maxLength: 1200,
    );
    final String prompt =
        'You are a holistic health coach. Summarize diet patterns for today only. '
        'Meals:\n$mealsBuf\n'
        'User goals: $goalsLine\n'
        'Activity context: $activitySafe\n'
        'Health context (non-diagnostic): $healthSafe\n'
        'Write 2-3 short paragraphs using hedging ("you may consider", "could"). '
        'Never diagnose. No medical claims.';
    try {
      final GenerateContentResponse response = await _flashModel
          .generateContent(<Content>[Content.text(prompt)]);
      await _usageTracker.record(
        AiUsageModelKind.flash,
        promptChars: prompt.length,
        responseChars: response.text?.length ?? 0,
      );
      return response.text?.trim() ?? 'No insight available.';
    } catch (e, st) {
      LoggerService.e('getDietInsight', e, st);
      return 'Unable to generate a diet insight right now.';
    }
  }

  /// Flash meal-plan suggestion with 24h Drift cache per user.
  Future<DietPlanSuggestion> suggestDietPlan({
    required String userId,
    required String userProfile,
    required Map<String, DietSummary> weeklyNutrition,
    required List<String> goals,
  }) async {
    final FitupDatabase? db = _db;
    if (db != null) {
      final DietPlanCacheRow? row = await (db.select(
        db.dietPlanCache,
      )..where((t) => t.userId.equals(userId))).getSingleOrNull();
      if (row != null && row.expiresAt.isAfter(DateTime.now())) {
        try {
          return DietPlanSuggestion.fromJson(
            jsonDecode(row.payloadJson) as Map<String, dynamic>,
          );
        } catch (_) {}
      }
    }
    final String week = weeklyNutrition.entries
        .map(
          (MapEntry<String, DietSummary> e) =>
              '${e.key}: ${e.value.totalCalories.toStringAsFixed(0)} kcal',
        )
        .join('; ');
    final String profileSafe = AiInputSanitizer.sanitizeProfileText(
      userProfile,
      maxLength: 2000,
    );
    final String goalsSafe = goals
        .map(
          (String g) =>
              AiInputSanitizer.sanitizeContextSnippet(g, maxLength: 200),
        )
        .join(', ');
    final String prompt =
        'Suggest a simple 1-day meal idea list for gaps in nutrition. '
        'Profile: $profileSafe\nWeek summary: $week\nGoals: $goalsSafe\n'
        'Return JSON only: {"summary":"...","mealIdeas":["...","..."],"disclaimer":"..."} '
        'Ideas should be practical for Indian kitchens. Hedging only; not medical advice.';
    try {
      final GenerateContentResponse response = await _flashModel
          .generateContent(<Content>[Content.text(prompt)]);
      await _usageTracker.record(
        AiUsageModelKind.flash,
        promptChars: prompt.length,
        responseChars: response.text?.length ?? 0,
      );
      final String? text = response.text;
      if (text == null || text.isEmpty) {
        return _fallbackPlan();
      }
      final DietPlanSuggestion plan = _parseDietPlan(text);
      if (db != null) {
        final String json = jsonEncode(plan.toJson());
        await db
            .into(db.dietPlanCache)
            .insertOnConflictUpdate(
              DietPlanCacheCompanion.insert(
                userId: userId,
                payloadJson: json,
                expiresAt: DateTime.now().add(const Duration(hours: 24)),
              ),
            );
      }
      return plan;
    } catch (e, st) {
      LoggerService.e('suggestDietPlan', e, st);
      return _fallbackPlan();
    }
  }

  DietPlanSuggestion _fallbackPlan() {
    return const DietPlanSuggestion(
      summary: 'Could not build a full plan right now.',
      mealIdeas: <String>[
        'Consider a balanced plate with dal, vegetables, and roti or rice.',
      ],
    );
  }

  DietPlanSuggestion _parseDietPlan(String raw) {
    final String trimmed = raw.trim();
    final int start = trimmed.indexOf('{');
    final int end = trimmed.lastIndexOf('}');
    if (start < 0 || end <= start) {
      return _fallbackPlan();
    }
    try {
      final Map<String, dynamic> map =
          jsonDecode(trimmed.substring(start, end + 1)) as Map<String, dynamic>;
      return DietPlanSuggestion.fromJson(map);
    } catch (e, st) {
      LoggerService.e('parseDietPlan', e, st);
      return _fallbackPlan();
    }
  }

  MealAnalysisResult _parseMealAnalysisJson(String raw) {
    final String trimmed = raw.trim();
    final int start = trimmed.indexOf('{');
    final int end = trimmed.lastIndexOf('}');
    if (start < 0 || end <= start) {
      return MealAnalysisResult(items: <FoodItem>[], note: trimmed);
    }
    try {
      final Map<String, dynamic> map =
          jsonDecode(trimmed.substring(start, end + 1)) as Map<String, dynamic>;
      final List<dynamic>? items = map['items'] as List<dynamic>?;
      final List<FoodItem> out = <FoodItem>[];
      int i = 0;
      for (final dynamic e in items ?? <dynamic>[]) {
        if (e is! Map<String, dynamic>) {
          continue;
        }
        final String name = e['name'] as String? ?? 'Food';
        out.add(
          FoodItem(
            id: 'ai_${DateTime.now().millisecondsSinceEpoch}_$i',
            name: name,
            quantity: (e['quantity'] as num?)?.toDouble() ?? 1,
            unit: e['unit'] as String? ?? 'serving',
            calories: (e['calories'] as num?)?.toDouble() ?? 0,
            protein: (e['protein'] as num?)?.toDouble() ?? 0,
            carbs: (e['carbs'] as num?)?.toDouble() ?? 0,
            fat: (e['fat'] as num?)?.toDouble() ?? 0,
            isCustom: true,
          ),
        );
        i++;
      }
      return MealAnalysisResult(items: out, note: map['note'] as String?);
    } catch (e, st) {
      LoggerService.e('parseMealAnalysisJson', e, st);
      return MealAnalysisResult(items: <FoodItem>[], note: trimmed);
    }
  }

  String _buildActivityContext(List<Activity> list) {
    if (list.isEmpty) {
      return 'No activities logged in the last 7 days.';
    }
    final StringBuffer b = StringBuffer();
    for (final Activity a in list) {
      b.writeln(
        '${a.type.name}: distance ${a.distanceMeters.toStringAsFixed(0)} m, '
        'duration ${a.durationSeconds} s, kcal ${a.caloriesBurnt.toStringAsFixed(0)}',
      );
    }
    return b.toString();
  }

  AiInsight _parseAiInsight(String raw) {
    final String trimmed = raw.trim();
    final int start = trimmed.indexOf('{');
    final int end = trimmed.lastIndexOf('}');
    if (start < 0 || end <= start) {
      return AiInsight(
        summary: trimmed.split('\n').first,
        details: const <String>['Could not parse structured JSON.'],
        suggestions: const <String>[
          'Consider reviewing your activity log in the app.',
        ],
      );
    }
    try {
      final Object? decoded = jsonDecode(trimmed.substring(start, end + 1));
      if (decoded is! Map<String, dynamic>) {
        return _fallbackInsight();
      }
      final Map<String, dynamic> map = decoded;
      final String summary = map['summary'] as String? ?? '';
      final List<String> details =
          (map['details'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[];
      final List<String> suggestions =
          (map['suggestions'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[];
      return AiInsight(
        summary: summary,
        details: details,
        suggestions: suggestions,
      );
    } catch (e, st) {
      LoggerService.e('AiInsight JSON parse', e, st);
      return _fallbackInsight();
    }
  }

  AiInsight _fallbackInsight() {
    return const AiInsight(
      summary: 'We could not generate a full insight right now.',
      details: <String>['Try again in a moment or check your connection.'],
      suggestions: <String>[
        'Consider logging a short walk to build more context.',
      ],
    );
  }

  /// Flash: structured JSON plan; cached 7d in [FitupDatabase] when available.
  Future<Either<Failure, WorkoutPlan>> generateWorkoutPlan({
    required WorkoutUserProfile profile,
    required List<String> goals,
    required List<Equipment> equipment,
    required String fitnessLevel,
    required int daysPerWeek,
    required List<String> approvedExerciseNames,
  }) async {
    final FitupDatabase? db = _db;
    if (db != null) {
      final WorkoutPlanCacheRow? row = await (db.select(
        db.workoutPlanCache,
      )..where((t) => t.userId.equals(profile.userId))).getSingleOrNull();
      if (row != null && row.expiresAt.isAfter(DateTime.now())) {
        try {
          final Map<String, dynamic> map =
              jsonDecode(row.payloadJson) as Map<String, dynamic>;
          return Right<Failure, WorkoutPlan>(
            parseAiWorkoutPlanJson(
              json: map,
              userId: profile.userId,
              isAiGenerated: true,
            ),
          );
        } catch (e, st) {
          LoggerService.e('workout plan cache parse', e, st);
        }
      }
    }
    final String profileCtx = workoutProfilePromptSegment(profile);
    final String goalsSafe = goals
        .map(
          (String g) =>
              AiInputSanitizer.sanitizeContextSnippet(g, maxLength: 120),
        )
        .join(', ');
    final String equip = equipment.map((Equipment e) => e.name).join(', ');
    final String namesSample = approvedExerciseNames.take(80).join(', ');
    final String level = AiInputSanitizer.sanitizeContextSnippet(
      fitnessLevel,
      maxLength: 40,
    );
    final String prompt =
        'You are a certified personal trainer AI. Create a $daysPerWeek-day '
        'workout plan for a $level user. Goals: $goalsSafe. '
        'Available equipment: $equip. User context (non-diagnostic): $profileCtx. '
        'Use ONLY exercises from this approved list (match exerciseName exactly): '
        '$namesSample. '
        'Return JSON only with keys: name, description, goals (array of strings), '
        'fitnessLevel, equipment (array of enum names: none, dumbbells, barbell, ...), '
        'daysPerWeek, isActive, sessions (array of {name, dayOfWeek, '
        'estimatedDurationMinutes, targetMuscleGroups (muscle enum names), '
        'exercises: [{exerciseId, exerciseName, sets, reps, durationSeconds, '
        'restSeconds, weightKg, notes}]}). '
        'Never diagnose. Use hedging: "may", "consider".';
    try {
      final GenerateContentResponse response = await _flashModel
          .generateContent(<Content>[Content.text(prompt)]);
      await _usageTracker.record(
        AiUsageModelKind.flash,
        promptChars: prompt.length,
        responseChars: response.text?.length ?? 0,
      );
      final String? text = response.text;
      if (text == null || text.isEmpty) {
        return const Left<Failure, WorkoutPlan>(
          AiFailure('Empty model response'),
        );
      }
      final String trimmed = text.trim();
      final int start = trimmed.indexOf('{');
      final int end = trimmed.lastIndexOf('}');
      if (start < 0 || end <= start) {
        return const Left<Failure, WorkoutPlan>(
          AiFailure('Invalid JSON shape'),
        );
      }
      final Map<String, dynamic> map =
          jsonDecode(trimmed.substring(start, end + 1)) as Map<String, dynamic>;
      final WorkoutPlan plan = parseAiWorkoutPlanJson(
        json: map,
        userId: profile.userId,
        isAiGenerated: true,
      );
      if (db != null) {
        await db
            .into(db.workoutPlanCache)
            .insertOnConflictUpdate(
              WorkoutPlanCacheCompanion.insert(
                userId: profile.userId,
                payloadJson: trimmed.substring(start, end + 1),
                expiresAt: DateTime.now().add(const Duration(days: 7)),
              ),
            );
      }
      return Right<Failure, WorkoutPlan>(plan);
    } catch (e, st) {
      LoggerService.e('generateWorkoutPlan', e, st);
      return Left<Failure, WorkoutPlan>(AiFailure(e.toString()));
    }
  }

  /// Cross-module workout reflection (hedging). No raw log notes in prompt.
  Future<String> getWorkoutInsight({
    required List<WorkoutLog> recentLogs,
    required WorkoutSummary summary,
    ActivityStats? activityData,
    DietSummary? dietData,
    Map<String, DietSummary>? weeklyNutrition,
    List<String>? activePlanGoals,
  }) async {
    final StringBuffer logBuf = StringBuffer();
    for (final WorkoutLog l in recentLogs.take(8)) {
      final String? safeNotes = l.notes != null && l.notes!.isNotEmpty
          ? AiInputSanitizer.sanitizeContextSnippet(l.notes!, maxLength: 200)
          : null;
      logBuf.writeln(
        '${l.sessionName}: ${l.endTime.difference(l.startTime).inMinutes} min, '
        '${l.totalCaloriesBurnt.toStringAsFixed(0)} kcal, sets:${l.completedSets.length}'
        '${safeNotes != null ? ', note:$safeNotes' : ''}',
      );
    }
    final String act = activityData != null
        ? 'Activity: steps ${activityData.totalSteps}, distanceM ${activityData.totalDistanceMeters.toStringAsFixed(0)}'
        : 'Activity: n/a';
    final String diet = dietData != null
        ? 'Diet kcal today ~${dietData.totalCalories.toStringAsFixed(0)}'
        : 'Diet: n/a';
    final String weekDiet =
        weeklyNutrition != null && weeklyNutrition.isNotEmpty
        ? weeklyNutrition.entries
              .map(
                (MapEntry<String, DietSummary> e) =>
                    '${e.key}: ${e.value.totalCalories.toStringAsFixed(0)} kcal',
              )
              .join('; ')
        : '';
    final String goals = activePlanGoals != null && activePlanGoals.isNotEmpty
        ? activePlanGoals.join(', ')
        : 'not set';
    final String prompt =
        'You are a fitness coach. Summarize workout patterns and recovery hints. '
        'Recent sessions:\n$logBuf\n'
        'Summary: sessions ${summary.totalSessions}, streak ${summary.currentStreak}, '
        'week ${summary.thisWeekSessions}.\n$act\n$diet\n'
        'Weekly diet by day: ${weekDiet.isEmpty ? 'n/a' : weekDiet}\n'
        'Active workout plan goals: $goals\n'
        'Use hedging only; no medical claims or diagnoses.';
    try {
      final GenerateContentResponse response = await _flashModel
          .generateContent(<Content>[Content.text(prompt)]);
      await _usageTracker.record(
        AiUsageModelKind.flash,
        promptChars: prompt.length,
        responseChars: response.text?.length ?? 0,
      );
      return response.text?.trim() ?? 'No insight available.';
    } catch (e, st) {
      LoggerService.e('getWorkoutInsight', e, st);
      return 'Unable to generate workout insight right now.';
    }
  }

  /// Short progression cue; max ~200 tokens.
  Future<String> suggestProgressiveOverload({
    required PersonalRecord record,
    required List<WorkoutLog> history,
  }) async {
    final String ex = AiInputSanitizer.sanitizeContextSnippet(
      record.exerciseName,
      maxLength: 80,
    );
    final StringBuffer h = StringBuffer();
    for (final WorkoutLog l in history.take(5)) {
      for (final CompletedSet s in l.completedSets) {
        if (s.exerciseId == record.exerciseId) {
          h.writeln(
            'w:${s.weightKg?.toStringAsFixed(1) ?? '-'} r:${s.reps ?? '-'}',
          );
        }
      }
    }
    final String prompt =
        'Give 2-3 short bullets on progressive overload for "$ex". '
        'Recent sets:\n$h\n'
        'PR weight kg: ${record.maxWeightKg}, PR reps: ${record.maxReps}. '
        'Hedging language; not medical advice.';
    try {
      final GenerateContentResponse response = await _flashModel
          .generateContent(<Content>[
            Content.text(prompt),
          ], generationConfig: GenerationConfig(maxOutputTokens: 200));
      await _usageTracker.record(
        AiUsageModelKind.flash,
        promptChars: prompt.length,
        responseChars: response.text?.length ?? 0,
      );
      return response.text?.trim() ?? 'No suggestion right now.';
    } catch (e, st) {
      LoggerService.e('suggestProgressiveOverload', e, st);
      return 'Could not load a progression suggestion.';
    }
  }

  /// Vision: extract lab metrics as structured rows. No user id in prompt.
  /// Tries flash-lite then flash (cost-first for images).
  Future<Either<Failure, List<ExtractedVital>>> analyzeLabReport(
    Uint8List imageBytes,
  ) async {
    final String prompt = labReportVisionPrompt();
    final List<GenerativeModel> order = <GenerativeModel>[
      _flashLiteModel,
      _flashModel,
    ];
    Object? lastError;
    for (final GenerativeModel model in order) {
      try {
        final GenerateContentResponse response = await model.generateContent(
          <Content>[
            Content.multi(<Part>[
              TextPart(prompt),
              DataPart('image/jpeg', imageBytes),
            ]),
          ],
          generationConfig: GenerationConfig(
            maxOutputTokens: _labReportMaxOutputTokens,
            temperature: 0,
          ),
        );
        if (identical(model, _flashLiteModel)) {
          await _usageTracker.record(
            AiUsageModelKind.flashLite,
            promptChars: prompt.length,
            responseChars: response.text?.length ?? 0,
          );
        } else if (identical(model, _flashModel)) {
          await _usageTracker.record(
            AiUsageModelKind.flash,
            promptChars: prompt.length,
            responseChars: response.text?.length ?? 0,
          );
        }
        final String? text = response.text;
        if (text == null || text.isEmpty) {
          lastError = 'Empty model response';
          continue;
        }
        if (!_looksLikeLabReportJson(text)) {
          lastError = 'Low-confidence lab JSON';
          continue;
        }
        final List<ExtractedVital> rows = _parseLabReportExtractedList(text);
        return Right<Failure, List<ExtractedVital>>(rows);
      } catch (e, st) {
        lastError = e;
        LoggerService.e('analyzeLabReport', e, st);
      }
    }
    return Left<Failure, List<ExtractedVital>>(
      AiFailure(lastError?.toString() ?? 'Lab report parse failed'),
    );
  }

  /// PDF multimodal: extract lab metrics. Tries flash (accuracy) then flash-lite.
  Future<Either<Failure, List<ExtractedVital>>> analyzeLabReportPdf(
    Uint8List pdfBytes,
  ) async {
    final String prompt = labReportVisionPrompt();
    final List<GenerativeModel> order = <GenerativeModel>[
      _flashModel,
      _flashLiteModel,
    ];
    Object? lastError;
    for (final GenerativeModel model in order) {
      try {
        final GenerateContentResponse response = await model.generateContent(
          <Content>[
            Content.multi(<Part>[
              TextPart(prompt),
              DataPart('application/pdf', pdfBytes),
            ]),
          ],
          generationConfig: GenerationConfig(
            maxOutputTokens: _labReportMaxOutputTokens,
            temperature: 0,
          ),
        );
        if (identical(model, _flashLiteModel)) {
          await _usageTracker.record(
            AiUsageModelKind.flashLite,
            promptChars: prompt.length,
            responseChars: response.text?.length ?? 0,
          );
        } else if (identical(model, _flashModel)) {
          await _usageTracker.record(
            AiUsageModelKind.flash,
            promptChars: prompt.length,
            responseChars: response.text?.length ?? 0,
          );
        }
        final String? text = response.text;
        if (text == null || text.isEmpty) {
          lastError = 'Empty model response';
          continue;
        }
        if (!_looksLikeLabReportJson(text)) {
          lastError = 'Low-confidence lab JSON';
          continue;
        }
        final List<ExtractedVital> rows = _parseLabReportExtractedList(text);
        return Right<Failure, List<ExtractedVital>>(rows);
      } catch (e, st) {
        lastError = e;
        LoggerService.e('analyzeLabReportPdf', e, st);
      }
    }
    return Left<Failure, List<ExtractedVital>>(
      AiFailure(lastError?.toString() ?? 'Lab PDF parse failed'),
    );
  }

  /// Text-only lab parse (after local PDF text extraction).
  /// Always uses flash (accuracy) with flash-lite fallback. Full report text
  /// is sent without truncation — Gemini's context window handles it.
  Future<Either<Failure, List<ExtractedVital>>> analyzeLabReportText(
    String reportText,
  ) async {
    final String prompt = labReportTextPrompt(reportText);
    final List<GenerativeModel> order = <GenerativeModel>[
      _flashModel,
      _flashLiteModel,
    ];
    Object? lastError;
    for (final GenerativeModel model in order) {
      try {
        final GenerateContentResponse response = await model.generateContent(
          <Content>[Content.text(prompt)],
          generationConfig: GenerationConfig(
            maxOutputTokens: _labReportMaxOutputTokens,
            temperature: 0,
          ),
        );
        if (identical(model, _flashLiteModel)) {
          await _usageTracker.record(
            AiUsageModelKind.flashLite,
            promptChars: prompt.length,
            responseChars: response.text?.length ?? 0,
          );
        } else if (identical(model, _flashModel)) {
          await _usageTracker.record(
            AiUsageModelKind.flash,
            promptChars: prompt.length,
            responseChars: response.text?.length ?? 0,
          );
        }
        final String? text = response.text;
        if (text == null || text.isEmpty) {
          lastError = 'Empty model response';
          continue;
        }
        if (!_looksLikeLabReportJson(text)) {
          lastError = 'Low-confidence lab JSON';
          continue;
        }
        final List<ExtractedVital> rows = _parseLabReportExtractedList(text);
        if (rows.isEmpty) {
          lastError = 'Zero vitals parsed';
          continue;
        }
        return Right<Failure, List<ExtractedVital>>(rows);
      } catch (e, st) {
        lastError = e;
        LoggerService.e('analyzeLabReportText', e, st);
      }
    }
    return Left<Failure, List<ExtractedVital>>(
      AiFailure(lastError?.toString() ?? 'Lab text parse failed'),
    );
  }

  /// Maps OCR rows to [VitalEntry] for persistence (skips unknown / derived types).
  Future<Either<Failure, List<VitalEntry>>> analyzeLabReportAsVitalEntries(
    Uint8List imageBytes, {
    required String userId,
  }) async {
    final Either<Failure, List<ExtractedVital>> step = await analyzeLabReport(
      imageBytes,
    );
    return step.fold(Left<Failure, List<VitalEntry>>.new, (
      List<ExtractedVital> rows,
    ) {
      final List<VitalEntry> out = <VitalEntry>[];
      final int ts = DateTime.now().microsecondsSinceEpoch;
      int i = 0;
      for (final ExtractedVital ex in rows) {
        final VitalType? vt = mappedTypeFromExtracted(ex);
        if (vt == null) {
          continue;
        }
        final String id = 'lab-$userId-$ts-$i';
        i++;
        final VitalEntry? ve = extractedToVitalEntry(
          extracted: ex,
          type: vt,
          userId: userId,
          entryId: id,
        );
        if (ve != null) {
          out.add(ve);
        }
      }
      if (out.isEmpty) {
        return const Left<Failure, List<VitalEntry>>(
          AiFailure('No mappable vitals in lab report'),
        );
      }
      return Right<Failure, List<VitalEntry>>(out);
    });
  }

  /// Holistic vitals + medications narrative (Flash). [cacheUserId] is for Drift
  /// only — never sent to the model.
  Future<Either<Failure, String>> getHealthInsight({
    required String cacheUserId,
    required HealthSummary summary,
    required HealthUserProfileContext profile,
  }) async {
    final FitupDatabase? db = _db;
    if (db != null) {
      final HealthInsightCacheRow? row = await (db.select(
        db.healthInsightCache,
      )..where((t) => t.userId.equals(cacheUserId))).getSingleOrNull();
      if (row != null && row.expiresAt.isAfter(DateTime.now())) {
        return Right<Failure, String>(row.summaryText);
      }
    }
    final StringBuffer vitalsBuf = StringBuffer();
    for (final MapEntry<VitalType, VitalEntry?> e
        in summary.latestVitals.entries) {
      final VitalEntry? v = e.value;
      if (v == null) {
        continue;
      }
      if (v.type.isDerived && v.type != VitalType.bmi) {
        continue;
      }
      final RangeStatus st = VitalReferenceRanges.statusFor(v.type, v.value);
      vitalsBuf.writeln(
        '${v.type.displayName}: ${v.value} ${v.unit} (reference band: ${st.name})',
      );
    }
    if (vitalsBuf.isEmpty) {
      vitalsBuf.writeln('No recent vitals logged.');
    }
    final StringBuffer medBuf = StringBuffer();
    for (final MedicationLog m in summary.activeMedications) {
      medBuf.writeln(
        '${AiInputSanitizer.sanitizeContextSnippet(m.medicationName, maxLength: 120)} '
        '— ${AiInputSanitizer.sanitizeContextSnippet(m.dose, maxLength: 40)}, '
        '${AiInputSanitizer.sanitizeContextSnippet(m.frequency, maxLength: 80)}',
      );
    }
    if (medBuf.isEmpty) {
      medBuf.writeln('None listed.');
    }
    final String prompt = healthContextInsightPrompt(
      ageGroup: AiInputSanitizer.sanitizeContextSnippet(
        profile.ageGroupLabel,
        maxLength: 40,
      ),
      fitnessLevel: AiInputSanitizer.sanitizeContextSnippet(
        profile.fitnessLevel,
        maxLength: 40,
      ),
      vitalsLines: vitalsBuf.toString().trim(),
      medicationsLines: medBuf.toString().trim(),
      bodyMetricsLines: AiInputSanitizer.sanitizeContextSnippet(
        profile.bodyMetricsLines,
        maxLength: 220,
      ),
    );
    try {
      final GenerateContentResponse response = await _flashModel
          .generateContent(<Content>[Content.text(prompt)]);
      final String text =
          response.text?.trim() ?? 'No health insight available.';
      if (db != null) {
        await db
            .into(db.healthInsightCache)
            .insertOnConflictUpdate(
              HealthInsightCacheCompanion.insert(
                userId: cacheUserId,
                summaryText: text,
                expiresAt: DateTime.now().add(const Duration(hours: 4)),
              ),
            );
      }
      return Right<Failure, String>(text);
    } catch (e, st) {
      LoggerService.e('getHealthInsight', e, st);
      return Left<Failure, String>(AiFailure(e.toString()));
    }
  }

  /// Supportive screening reflection (Flash). No raw answers or user id in prompt.
  Future<Either<Failure, String>> getSurveyInsight({
    required SurveyType type,
    required SurveySeverity severity,
  }) async {
    final String prompt = surveyInsightPrompt(type, severity);
    try {
      final GenerateContentResponse response = await _flashModel
          .generateContent(<Content>[Content.text(prompt)]);
      final String? text = response.text;
      if (text == null || text.isEmpty) {
        return const Left<Failure, String>(AiFailure('Empty model response'));
      }
      return Right<Failure, String>(text.trim());
    } catch (e, st) {
      LoggerService.e('getSurveyInsight', e, st);
      return Left<Failure, String>(AiFailure(e.toString()));
    }
  }

  /// Cross-module wellbeing text (Flash). Labels only — no identifiers.
  Future<Either<Failure, String>> getMentalWellbeingInsight({
    required String moodLabel,
    required String sleepQualityLabel,
    required int activityMinutesThisWeek,
    required String surveySummaryLabel,
  }) async {
    final String safeMood = AiInputSanitizer.sanitizeContextSnippet(
      moodLabel,
      maxLength: 80,
    );
    final String safeSleep = AiInputSanitizer.sanitizeContextSnippet(
      sleepQualityLabel,
      maxLength: 80,
    );
    final String safeSurvey = AiInputSanitizer.sanitizeContextSnippet(
      surveySummaryLabel,
      maxLength: 120,
    );
    final String prompt = mentalWellbeingCrossPrompt(
      moodLine: safeMood,
      sleepLine: safeSleep,
      activityLine: '$activityMinutesThisWeek minutes this week',
      surveyLine: safeSurvey,
    );
    try {
      final GenerateContentResponse response = await _flashModel
          .generateContent(<Content>[
            Content.text(prompt),
          ], generationConfig: GenerationConfig(maxOutputTokens: 400));
      await _usageTracker.record(
        AiUsageModelKind.flash,
        promptChars: prompt.length,
        responseChars: response.text?.length ?? 0,
      );
      final String? text = response.text;
      if (text == null || text.isEmpty) {
        return const Left<Failure, String>(AiFailure('Empty model response'));
      }
      return Right<Failure, String>(text.trim());
    } catch (e, st) {
      LoggerService.e('getMentalWellbeingInsight', e, st);
      return Left<Failure, String>(AiFailure(e.toString()));
    }
  }

  /// Morning briefing text (Flash). [ctx] must be anonymized.
  Future<Either<Failure, String>> getDailyBriefing(HolisticContext ctx) async {
    final String contextBlock = buildHolisticPromptContext(ctx);
    const String system =
        'You are a holistic health coach assistant. Provide a warm, motivating '
        'morning briefing based on the user\'s health data. Use hedging language only. '
        'Never diagnose. Max 4 sentences. End with one specific action for today.';
    final String prompt =
        '$system\n\n$contextBlock\nWrite a morning briefing for today.';
    try {
      final GenerateContentResponse response = await _flashModel
          .generateContent(<Content>[
            Content.text(prompt),
          ], generationConfig: GenerationConfig(maxOutputTokens: 400));
      await _usageTracker.record(
        AiUsageModelKind.flash,
        promptChars: prompt.length,
        responseChars: response.text?.length ?? 0,
      );
      final String? text = response.text?.trim();
      if (text == null || text.isEmpty) {
        return const Left<Failure, String>(AiFailure('Empty model response'));
      }
      return Right<Failure, String>(text);
    } catch (e, st) {
      LoggerService.e('getDailyBriefing', e, st);
      return Left<Failure, String>(AiFailure(e.toString()));
    }
  }

  /// Weekly holistic report sections (Pro).
  Future<Either<Failure, WeeklyReportContent>> generateWeeklyReport(
    HolisticContext ctx,
  ) async {
    final String contextBlock = buildHolisticPromptContext(ctx);
    const String system =
        'You are a holistic health analyst. Provide a detailed weekly health report. '
        'Respond with JSON only (no markdown) using keys: executiveSummary, '
        'activityInsight, dietInsight, workoutInsight, healthInsight, mentalInsight, '
        'wins (array of strings), focusAreas (array of strings), goalProgress. '
        'Use hedging language. Never diagnose.';
    final String prompt =
        '$system\n\n$contextBlock\nGenerate a weekly holistic health report.';
    try {
      final GenerateContentResponse response = await _proModel.generateContent(
        <Content>[Content.text(prompt)],
        generationConfig: GenerationConfig(maxOutputTokens: 2048),
      );
      await _usageTracker.record(
        AiUsageModelKind.pro,
        promptChars: prompt.length,
        responseChars: response.text?.length ?? 0,
      );
      final String? raw = response.text?.trim();
      if (raw == null || raw.isEmpty) {
        return const Left<Failure, WeeklyReportContent>(
          AiFailure('Empty model response'),
        );
      }
      try {
        return Right<Failure, WeeklyReportContent>(
          parseWeeklyReportContentFromModel(raw),
        );
      } on FormatException catch (e) {
        LoggerService.e('generateWeeklyReport parse', e, StackTrace.current);
        return const Left<Failure, WeeklyReportContent>(
          AiFailure('Failed to parse weekly report'),
        );
      }
    } catch (e, st) {
      LoggerService.e('generateWeeklyReport', e, st);
      return Left<Failure, WeeklyReportContent>(AiFailure(e.toString()));
    }
  }

  /// Multi-turn coach chat (Flash).
  Future<Either<Failure, String>> chatWithAI(
    String message,
    HolisticContext ctx,
    List<ChatMessage> history, {
    String? moduleFocus,
  }) async {
    final String safe = AiInputSanitizer.sanitizeProfileText(
      message,
      maxLength: 1000,
    );
    final String contextBlock = buildHolisticPromptContext(ctx);
    const String system =
        'You are Fitup\'s AI health coach. You have access to the user\'s health '
        'summary below. Answer health and fitness questions helpfully, using hedging '
        'language ("consider", "you may want to"). Never diagnose or prescribe. '
        'If asked about medications, always say consult your doctor.\n\n';
    final StringBuffer convo = StringBuffer(system)..writeln(contextBlock);
    final String? focus = moduleFocus?.trim();
    if (focus != null && focus.isNotEmpty) {
      final String m = AiInputSanitizer.sanitizeContextSnippet(
        focus,
        maxLength: 80,
      );
      if (m.isNotEmpty) {
        convo.writeln('User focus area for this question: $m');
      }
    }
    final List<ChatMessage> tail = history.length > 10
        ? history.sublist(history.length - 10)
        : history;
    for (final ChatMessage m in tail) {
      convo.writeln(
        '[${m.role.name}]: ${m.role == ChatRole.user ? AiInputSanitizer.sanitizeProfileText(m.content, maxLength: 2000) : m.content}',
      );
    }
    convo.writeln('[user]: $safe');
    try {
      final GenerateContentResponse response = await _flashModel
          .generateContent(<Content>[
            Content.text(convo.toString()),
          ], generationConfig: GenerationConfig(maxOutputTokens: 800));
      await _usageTracker.record(
        AiUsageModelKind.flash,
        promptChars: convo.toString().length,
        responseChars: response.text?.length ?? 0,
      );
      final String? text = response.text?.trim();
      if (text == null || text.isEmpty) {
        return const Left<Failure, String>(AiFailure('Empty model response'));
      }
      return Right<Failure, String>(text);
    } catch (e, st) {
      LoggerService.e('chatWithAI', e, st);
      return Left<Failure, String>(AiFailure(e.toString()));
    }
  }

  /// Extra pattern strings beyond rule engine (Flash).
  Future<Either<Failure, List<String>>> detectConflictsWithAI(
    HolisticContext ctx,
    List<CorrelationAlert> ruleAlerts,
  ) async {
    final String contextBlock = buildHolisticPromptContext(ctx);
    final String titles = ruleAlerts
        .map((CorrelationAlert a) => a.title)
        .join(', ');
    final String prompt =
        'Identify any other health conflicts or patterns not already listed. '
        'Be brief. Return a JSON array of strings only. Max 3 items. Hedging language only.\n\n'
        '$contextBlock\nExisting alerts: $titles\nAre there any other notable patterns?';
    try {
      final GenerateContentResponse response = await _flashModel
          .generateContent(<Content>[
            Content.text(prompt),
          ], generationConfig: GenerationConfig(maxOutputTokens: 300));
      await _usageTracker.record(
        AiUsageModelKind.flash,
        promptChars: prompt.length,
        responseChars: response.text?.length ?? 0,
      );
      final String? raw = response.text?.trim();
      if (raw == null || raw.isEmpty) {
        return const Right<Failure, List<String>>(<String>[]);
      }
      return Right<Failure, List<String>>(_parseStringArray(raw));
    } catch (e, st) {
      LoggerService.e('detectConflictsWithAI', e, st);
      return Left<Failure, List<String>>(AiFailure(e.toString()));
    }
  }

  /// Suggestion + rationale, or null if model says on track (Flash).
  Future<Either<Failure, ({String suggestion, String rationale})?>>
  suggestGoalAdjustment(HolisticContext ctx) async {
    final String contextBlock = buildHolisticPromptContext(ctx);
    final String prompt =
        'Based on the user\'s health data, suggest whether their current goal needs '
        'adjusting. Return JSON only: null if on track, or '
        '{"suggestion":"...","rationale":"..."} if adjustment may help. '
        'Max 2 sentences per field. Hedging language only.\n\n$contextBlock';
    try {
      final GenerateContentResponse response = await _flashModel
          .generateContent(<Content>[
            Content.text(prompt),
          ], generationConfig: GenerationConfig(maxOutputTokens: 400));
      await _usageTracker.record(
        AiUsageModelKind.flash,
        promptChars: prompt.length,
        responseChars: response.text?.length ?? 0,
      );
      final String? raw = response.text?.trim();
      if (raw == null || raw.isEmpty) {
        return const Right<Failure, ({String suggestion, String rationale})?>(
          null,
        );
      }
      final ({String suggestion, String rationale})? parsed =
          _parseGoalAdjustmentResponse(raw);
      return Right<Failure, ({String suggestion, String rationale})?>(parsed);
    } catch (e, st) {
      LoggerService.e('suggestGoalAdjustment', e, st);
      return Left<Failure, ({String suggestion, String rationale})?>(
        AiFailure(e.toString()),
      );
    }
  }

  /// Holistic plan generation (Flash).
  Future<Either<Failure, HolisticPlanDraft>> generateHolisticPlan({
    required HolisticContext ctx,
    required DateTime startDate,
    required DateTime endDate,
    String? userPlanInput,
  }) async {
    final String contextBlock = buildHolisticPromptContext(ctx);
    const String system =
        'You are Fitup\'s holistic health coach. Generate a structured wellness plan for the given time window. '
        'Use hedging language only. Never diagnose or make medical claims. '
        'Respond with JSON only (no markdown) and no extra keys.';

    final String userInputBlock = (userPlanInput != null && userPlanInput.trim().isNotEmpty)
        ? '\nUser-selected plan constraints:\n${AiInputSanitizer.sanitizeContextSnippet(userPlanInput, maxLength: 3000)}\n'
        : '';

    final String prompt =
        '$system\n\n'
        'Time window: start=${startDate.toIso8601String().split("T").first}, end=${endDate.toIso8601String().split("T").first}\n\n'
        '$contextBlock\n\n'
        '$userInputBlock'
        'Return JSON only with this exact shape:\n'
        '{\n'
        '  "startDate":"YYYY-MM-DD",\n'
        '  "endDate":"YYYY-MM-DD",\n'
        '  "dailyTargets":{\n'
        '     "dailyStepGoal":int,\n'
        '     "dailyCalorieGoal":int,\n'
        '     "dailySleepGoalMinutes":int,\n'
        '     "dailyWaterGoalMl":int,\n'
        '     "dailyWorkoutGoalMinutes":int\n'
        '  },\n'
        '  "majorGoals":[string,...],\n'
        '  "modules":{\n'
        '     "activity":{ "summary":string },\n'
        '     "diet":{ "summary":string },\n'
        '     "workout":{ "summary":string },\n'
        '     "mental":{ "summary":string },\n'
        '     "health":{ "summary":string },\n'
        '     "community":{ "summary":string }\n'
        '  }\n'
        '}';

    try {
      final GenerateContentResponse response = await _flashModel
          .generateContent(<Content>[Content.text(prompt)],
              generationConfig: GenerationConfig(maxOutputTokens: 1800));
      await _usageTracker.record(
        AiUsageModelKind.flash,
        promptChars: prompt.length,
        responseChars: response.text?.length ?? 0,
      );
      final String? raw = response.text?.trim();
      if (raw == null || raw.isEmpty) {
        return const Left<Failure, HolisticPlanDraft>(
          AiFailure('Empty model response'),
        );
      }
      try {
        final HolisticPlanDraft draft = _parseHolisticPlanDraft(raw);
        return Right<Failure, HolisticPlanDraft>(draft);
      } catch (e, st) {
        LoggerService.e('generateHolisticPlan parse fallback', e, st);
        return Right<Failure, HolisticPlanDraft>(
          _fallbackHolisticPlanDraft(
            ctx: ctx,
            startDate: startDate,
            endDate: endDate,
            modelText: raw,
          ),
        );
      }
    } catch (e, st) {
      LoggerService.e('generateHolisticPlan', e, st);
      return Left<Failure, HolisticPlanDraft>(AiFailure(e.toString()));
    }
  }

  /// Updates the active holistic plan using user/module amendments (Flash).
  ///
  /// Important: keep `startDate`/`endDate` unchanged (no new plan reset) —
  /// this method only changes targets + module snapshots.
  Future<Either<Failure, HolisticPlanDraft>> updateHolisticPlanFromModule({
    required HolisticContext ctx,
    required HolisticPlan activePlan,
    required PlanModuleKey moduleKey,
    required String moduleAmendment,
  }) async {
    final String contextBlock = buildHolisticPromptContext(ctx);
    final String safeAmendment = AiInputSanitizer.sanitizeContextSnippet(
      moduleAmendment,
      maxLength: 800,
    );
    const String system =
        'You are Fitup\'s holistic health coach. Update the existing plan based on the user\'s module amendment. '
        'Keep the plan dates the same. Use hedging language only. Never diagnose or make medical claims. '
        'Return JSON only (no markdown) and no extra keys.';

    final String prompt =
        '$system\n\n'
        'Existing plan window: start=${activePlan.startDate.toIso8601String().split("T").first}, end=${activePlan.endDate.toIso8601String().split("T").first}\n'
        'Module being updated: ${moduleKey.key}\n'
        'User module amendment: $safeAmendment\n\n'
        '$contextBlock\n\n'
        'Return JSON with the same exact shape as generateHolisticPlan: '
        '{"startDate":"YYYY-MM-DD","endDate":"YYYY-MM-DD","dailyTargets":{...},"majorGoals":[...],"modules":{...}} '
        'and ensure startDate/endDate match the existing plan window.';

    try {
      final GenerateContentResponse response = await _flashModel
          .generateContent(<Content>[Content.text(prompt)],
              generationConfig: GenerationConfig(maxOutputTokens: 1800));
      await _usageTracker.record(
        AiUsageModelKind.flash,
        promptChars: prompt.length,
        responseChars: response.text?.length ?? 0,
      );
      final String? raw = response.text?.trim();
      if (raw == null || raw.isEmpty) {
        return const Left<Failure, HolisticPlanDraft>(
          AiFailure('Empty model response'),
        );
      }
      try {
        final HolisticPlanDraft draft = _parseHolisticPlanDraft(raw);
        return Right<Failure, HolisticPlanDraft>(draft);
      } catch (e, st) {
        LoggerService.e('updateHolisticPlanFromModule parse fallback', e, st);
        return Right<Failure, HolisticPlanDraft>(
          _fallbackHolisticPlanDraft(
            ctx: ctx,
            startDate: activePlan.startDate,
            endDate: activePlan.endDate,
            modelText: raw,
          ),
        );
      }
    } catch (e, st) {
      LoggerService.e('updateHolisticPlanFromModule', e, st);
      return Left<Failure, HolisticPlanDraft>(AiFailure(e.toString()));
    }
  }

  /// Suggests a daily plan nudge based on adherence (Flash).
  ///
  /// Returns `null` when the user is fully on track.
  Future<Either<Failure, ({String suggestion, String rationale})?>>
      suggestPlanNudge({
    required HolisticContext ctx,
    required HolisticPlan plan,
    required PlanDailyCheck check,
  }) async {
    if (check.onTrack) {
      return const Right<Failure, ({String suggestion, String rationale})?>(null);
    }

    final String contextBlock = buildHolisticPromptContext(ctx);
    const String system =
        'You are Fitup\'s daily wellness coach. Based on the user adherence, provide a short, supportive suggestion to get back on track. '
        'Use hedging language only. Never diagnose or make medical claims. '
        'Return JSON only with keys: suggestion, rationale.';

    final String prompt =
        '$system\n\n'
        '$contextBlock\n\n'
        'Active plan window: ${plan.startDate.toIso8601String().split("T").first} to ${plan.endDate.toIso8601String().split("T").first}\n'
        'Plan daily targets: steps=${plan.dailyTargets.dailyStepGoal}, calories=${plan.dailyTargets.dailyCalorieGoal}, sleepMinutes=${plan.dailyTargets.dailySleepGoalMinutes}, waterMl=${plan.dailyTargets.dailyWaterGoalMl}, workoutMinutes=${plan.dailyTargets.dailyWorkoutGoalMinutes}\n'
        'Adherence today: steps=${check.stepsCompleted}, calories=${check.caloriesCompleted}, sleepMinutes=${check.sleepCompleted}, waterMl=${check.waterCompleted}, workoutMinutes=${check.workoutCompleted}\n'
        'Major goals: ${plan.majorGoals.take(5).toList()}\n'
        'Respond with JSON only.';

    try {
      final GenerateContentResponse response = await _flashModel
          .generateContent(<Content>[Content.text(prompt)],
              generationConfig: GenerationConfig(maxOutputTokens: 600));
      await _usageTracker.record(
        AiUsageModelKind.flash,
        promptChars: prompt.length,
        responseChars: response.text?.length ?? 0,
      );
      final String? raw = response.text?.trim();
      if (raw == null || raw.isEmpty) {
        return const Left<Failure, ({String suggestion, String rationale})?>(
          AiFailure('Empty model response'),
        );
      }
      final ({String suggestion, String rationale}) parsed =
          _parseSuggestionRationale(raw);
      return Right<Failure, ({String suggestion, String rationale})?>(parsed);
    } catch (e, st) {
      LoggerService.e('suggestPlanNudge', e, st);
      return Left<Failure, ({String suggestion, String rationale})?>(
        AiFailure(e.toString()),
      );
    }
  }

  HolisticPlanDraft _parseHolisticPlanDraft(String raw) {
    final Map<String, dynamic> jsonMap = _decodeJsonObject(raw);

    final DateTime start = DateTime.parse(jsonMap['startDate'] as String);
    final DateTime end = DateTime.parse(jsonMap['endDate'] as String);

    final Map<String, dynamic> targets =
        (jsonMap['dailyTargets'] as Map).cast<String, dynamic>();
    final PlanTargets dailyTargets = PlanTargets(
      dailyStepGoal: (targets['dailyStepGoal'] as num).toInt(),
      dailyCalorieGoal: (targets['dailyCalorieGoal'] as num).toInt(),
      dailySleepGoalMinutes: (targets['dailySleepGoalMinutes'] as num).toInt(),
      dailyWaterGoalMl: (targets['dailyWaterGoalMl'] as num).toInt(),
      dailyWorkoutGoalMinutes:
          (targets['dailyWorkoutGoalMinutes'] as num).toInt(),
    );

    final List<String> majorGoals = (jsonMap['majorGoals'] as List<dynamic>)
        .map((dynamic e) => e.toString())
        .toList();

    final Map<String, dynamic> modules =
        (jsonMap['modules'] as Map).cast<String, dynamic>();
    final Map<PlanModuleKey, ModulePlan> modulePlans =
        <PlanModuleKey, ModulePlan>{};
    for (final MapEntry<String, dynamic> e in modules.entries) {
      final PlanModuleKey? key = (() {
        try {
          return PlanModuleKey.values.firstWhere((PlanModuleKey k) => k.key == e.key);
        } catch (_) {
          return null;
        }
      })();
      if (key == null) continue;
      final Map<String, dynamic> payload =
          (e.value as Map).cast<String, dynamic>();
      modulePlans[key] = ModulePlan(moduleKey: key, payload: payload);
    }

    // Ensure all expected modules exist (even if empty) so UI can render.
    for (final PlanModuleKey k in PlanModuleKey.values) {
      modulePlans.putIfAbsent(
        k,
        () => ModulePlan(
          moduleKey: k,
          payload: const <String, dynamic>{'summary': ''},
        ),
      );
    }

    return HolisticPlanDraft(
      startDate: start,
      endDate: end,
      dailyTargets: dailyTargets,
      majorGoals: majorGoals,
      modulePlans: modulePlans,
    );
  }

  Map<String, dynamic> _decodeJsonObject(String raw) {
    final String trimmed = raw.trim();
    try {
      final dynamic parsed = jsonDecode(trimmed);
      if (parsed is Map<String, dynamic>) {
        return parsed;
      }
      if (parsed is Map) {
        return parsed.cast<String, dynamic>();
      }
    } on Object {
      // Fall through to "extract JSON" strategy.
    }

    final int firstBrace = trimmed.indexOf('{');
    final int lastBrace = trimmed.lastIndexOf('}');
    if (firstBrace == -1 || lastBrace == -1 || lastBrace <= firstBrace) {
      throw const FormatException('No JSON object found');
    }
    final String slice = trimmed.substring(firstBrace, lastBrace + 1);
    final dynamic parsed = jsonDecode(slice);
    if (parsed is Map<String, dynamic>) {
      return parsed;
    }
    if (parsed is Map) {
      return parsed.cast<String, dynamic>();
    }
    throw const FormatException('Unexpected JSON shape');
  }

  HolisticPlanDraft _fallbackHolisticPlanDraft({
    required HolisticContext ctx,
    required DateTime startDate,
    required DateTime endDate,
    required String modelText,
  }) {
    final int stepGoal = (ctx.avgStepsLast7Days ?? 8000).round().clamp(
      5000,
      20000,
    );
    final int calorieGoal = (ctx.avgCaloriesLast7Days ?? 2200).round().clamp(
      1200,
      3500,
    );
    final int sleepGoal = ((ctx.sleepMinutesLastNight ?? 420)
            .clamp(360, 540))
        .toInt();
    final int waterGoal = (ctx.avgWaterMlLast7Days ?? 2500).round().clamp(
      1500,
      4500,
    );
    final int workoutGoal = ((ctx.activeMinutesYesterday ?? 45) + 15).clamp(
      20,
      120,
    );
    final String brief = modelText.trim().isEmpty
        ? 'Plan generated with safe defaults.'
        : modelText.trim().split('\n').first;
    final String primaryGoal = (ctx.primaryGoal ?? '').trim();

    final List<String> goals = <String>[
      if (primaryGoal.isNotEmpty) primaryGoal,
      'Build daily consistency',
      'Improve recovery quality',
    ];

    final Map<PlanModuleKey, ModulePlan> modulePlans =
        <PlanModuleKey, ModulePlan>{
      for (final PlanModuleKey key in PlanModuleKey.values)
        key: ModulePlan(
          moduleKey: key,
          payload: <String, dynamic>{
            'summary': brief,
          },
        ),
    };

    return HolisticPlanDraft(
      startDate: DateTime(startDate.year, startDate.month, startDate.day),
      endDate: DateTime(endDate.year, endDate.month, endDate.day),
      dailyTargets: PlanTargets(
        dailyStepGoal: stepGoal,
        dailyCalorieGoal: calorieGoal,
        dailySleepGoalMinutes: sleepGoal,
        dailyWaterGoalMl: waterGoal,
        dailyWorkoutGoalMinutes: workoutGoal,
      ),
      majorGoals: goals,
      modulePlans: modulePlans,
    );
  }

  ({String suggestion, String rationale}) _parseSuggestionRationale(
    String raw,
  ) {
    final Map<String, dynamic> jsonMap = _decodeJsonObject(raw);
    final String suggestion = (jsonMap['suggestion'] as String?)?.trim() ?? '';
    final String rationale = (jsonMap['rationale'] as String?)?.trim() ?? '';
    if (suggestion.isEmpty && rationale.isEmpty) {
      throw const FormatException('Missing suggestion/rationale');
    }
    return (suggestion: suggestion, rationale: rationale);
  }

  List<String> _parseStringArray(String raw) {
    String slice = raw.trim();
    final int lb = slice.indexOf('[');
    final int rb = slice.lastIndexOf(']');
    if (lb >= 0 && rb > lb) {
      slice = slice.substring(lb, rb + 1);
    }
    final Object? decoded = jsonDecode(slice);
    if (decoded is! List<dynamic>) {
      return <String>[];
    }
    return decoded.map((dynamic e) => e.toString()).take(3).toList();
  }

  ({String suggestion, String rationale})? _parseGoalAdjustmentResponse(
    String raw,
  ) {
    String slice = raw.trim().toLowerCase();
    if (slice == 'null' || slice == 'none') {
      return null;
    }
    int lb = raw.indexOf('{');
    int rb = raw.lastIndexOf('}');
    if (lb < 0 || rb <= lb) {
      return null;
    }
    slice = raw.substring(lb, rb + 1);
    final Object? decoded = jsonDecode(slice);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final String? s = decoded['suggestion']?.toString();
    final String? r = decoded['rationale']?.toString();
    if (s == null || r == null || s.isEmpty) {
      return null;
    }
    return (suggestion: s, rationale: r);
  }

  bool _looksLikeLabReportJson(String raw) {
    final String trimmed = raw.trim();
    final int start = trimmed.indexOf('[');
    final int end = trimmed.lastIndexOf(']');
    if (start < 0 || end <= start) {
      return false;
    }
    final String slice = trimmed.substring(start, end + 1);
    try {
      final Object? decoded = jsonDecode(slice);
      if (decoded is! List<dynamic>) {
        return false;
      }
      if (decoded.isEmpty) {
        return true;
      }
      final Object? first = decoded.first;
      if (first is! Map<String, dynamic>) {
        return false;
      }
      return first.containsKey('value') &&
          (first.containsKey('type') ||
              first.containsKey('metric_name') ||
              first.containsKey('metricName') ||
              first.containsKey('name'));
    } catch (_) {
      return false;
    }
  }

  List<ExtractedVital> _parseLabReportExtractedList(String raw) {
    String slice = raw.trim();
    final int lb = slice.indexOf('[');
    final int rb = slice.lastIndexOf(']');
    if (lb >= 0 && rb > lb) {
      slice = slice.substring(lb, rb + 1);
    } else if (lb >= 0) {
      slice = _repairTruncatedJsonArray(slice.substring(lb));
    }
    final Object? decoded = jsonDecode(slice);
    if (decoded is! List<dynamic>) {
      throw const FormatException('Expected JSON array');
    }
    final List<ExtractedVital> out = <ExtractedVital>[];
    for (final dynamic item in decoded) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final Object? typeRaw = item['type'];
      final Object? nameRaw =
          typeRaw ?? item['metric_name'] ?? item['metricName'] ?? item['name'];
      final Object? valRaw = item['value'];
      if (nameRaw == null || valRaw == null) {
        continue;
      }
      final double? val = _coerceDouble(valRaw);
      if (val == null) {
        continue;
      }
      final String? typeKeyRaw = typeRaw?.toString().trim();
      final String? typeKey = (typeKeyRaw != null && typeKeyRaw.isNotEmpty)
          ? typeKeyRaw
          : null;
      final VitalType? fromEnum = typeKey != null
          ? mapTypeEnumToVitalType(typeKey)
          : null;
      final String metricLabel = fromEnum != null
          ? fromEnum.displayName
          : nameRaw.toString();
      out.add(
        ExtractedVital(
          metricName: metricLabel,
          value: val,
          unit: item['unit']?.toString() ?? '',
          referenceRangeMentioned: item['reference_range_mentioned']
              ?.toString(),
          typeKey: typeKey,
        ),
      );
    }
    return out;
  }

  /// Attempts to repair a JSON array truncated mid-element by discarding
  /// the incomplete trailing object and closing the array.
  String _repairTruncatedJsonArray(String truncated) {
    final int lastCloseBrace = truncated.lastIndexOf('}');
    if (lastCloseBrace < 0) {
      return '[]';
    }
    final String upToLast = truncated.substring(0, lastCloseBrace + 1);
    final String candidate = '$upToLast]';
    try {
      jsonDecode(candidate);
      return candidate;
    } catch (_) {
      return '[]';
    }
  }

  double? _coerceDouble(Object? v) {
    if (v is num) {
      return v.toDouble();
    }
    if (v is String) {
      return double.tryParse(v.replaceAll(',', '').trim());
    }
    return null;
  }
}
