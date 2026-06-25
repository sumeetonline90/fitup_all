import 'dart:convert';

import '../../domain/entities/holistic_plan.dart';

/// Converts AI module summary payloads into human-readable text.
///
/// Handles cases where model output is wrapped in markdown code fences like:
/// ```json ... ``` or where summary contains nested JSON objects.
String formatPlanSummary(Object? rawSummary) {
  if (rawSummary == null) {
    return 'No summary yet.';
  }

  String text = rawSummary.toString().trim();
  if (text.isEmpty) {
    return 'No summary yet.';
  }

  // Remove markdown fencing artifacts often returned by models.
  text = text
      .replaceAll('```json', '')
      .replaceAll('```JSON', '')
      .replaceAll('```', '')
      .trim();
  if (text.isEmpty || text.toLowerCase() == 'json') {
    return 'Summary is being prepared.';
  }
  if (text == '{' || text == '[') {
    return 'Plan summary available after next refresh.';
  }

  // Try parse object/array payloads and surface useful prose.
  if (text.startsWith('{') || text.startsWith('[')) {
    try {
      final dynamic decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        final Object? nestedSummary = decoded['summary'];
        if (nestedSummary != null &&
            nestedSummary.toString().trim().isNotEmpty) {
          return nestedSummary.toString().trim();
        }
        final Iterable<MapEntry<String, dynamic>> entries = decoded.entries
            .where((e) => e.value != null && e.value.toString().trim().isNotEmpty)
            .take(3);
        if (entries.isNotEmpty) {
          return entries.map((e) => '${e.key}: ${e.value}').join(' • ');
        }
      } else if (decoded is List<dynamic>) {
        final List<String> lines = decoded
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .take(3)
            .toList();
        if (lines.isNotEmpty) {
          return lines.join(' • ');
        }
      }
    } catch (_) {
      // If it looks like structured payload but parsing fails,
      // do not leak raw JSON fragments in UI.
      return 'Plan summary available after next refresh.';
    }
  }

  return text;
}

/// Builds actionable checklist lines for each module from holistic targets.
List<String> modulePlanChecklist({
  required HolisticPlan plan,
  required PlanModuleKey moduleKey,
}) {
  final String summary = formatPlanSummary(plan.modulePlans[moduleKey]?.payload['summary']);
  final List<String> lines = <String>[];
  if (!summary.toLowerCase().contains('summary is being prepared') &&
      !summary.toLowerCase().contains('plan summary available after next refresh')) {
    lines.add(summary);
  }

  switch (moduleKey) {
    case PlanModuleKey.activity:
      lines.add('Walk at least ${plan.dailyTargets.dailyStepGoal} steps daily.');
      lines.add(
        'Stay active for about ${plan.dailyTargets.dailyWorkoutGoalMinutes} minutes each day.',
      );
      break;
    case PlanModuleKey.diet:
      lines.add('Aim for around ${plan.dailyTargets.dailyCalorieGoal} kcal per day.');
      lines.add('Drink at least ${plan.dailyTargets.dailyWaterGoalMl} ml water daily.');
      break;
    case PlanModuleKey.workout:
      lines.add(
        'Complete about ${plan.dailyTargets.dailyWorkoutGoalMinutes} minutes of workout daily.',
      );
      lines.add('Keep intensity progressive and consistent through the week.');
      break;
    case PlanModuleKey.mental:
      lines.add('Target ${plan.dailyTargets.dailySleepGoalMinutes} minutes of sleep daily.');
      lines.add('Add a short mindfulness or breathing session each day.');
      break;
    case PlanModuleKey.health:
      lines.add('Track key vitals regularly and monitor trends weekly.');
      lines.add('Support recovery with sleep and hydration consistency.');
      break;
    case PlanModuleKey.community:
      lines.add('Engage with at least one challenge or event every week.');
      lines.add('Use community accountability to improve consistency.');
      break;
  }

  return lines.take(3).toList();
}
