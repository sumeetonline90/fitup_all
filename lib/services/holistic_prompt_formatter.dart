import 'package:fitup/features/insights/domain/entities/holistic_context.dart';

/// Anonymized structured text for Gemini (no userId / email / DOB).
String buildHolisticPromptContext(HolisticContext ctx) {
  final StringBuffer buf = StringBuffer();
  buf.writeln('User health snapshot (last 7 days, anonymized):');

  if (ctx.ageGroup != null) {
    buf.writeln('- Age group: ${ctx.ageGroup}');
  }
  if (ctx.gender != null) {
    buf.writeln('- Gender: ${ctx.gender}');
  }
  if (ctx.primaryGoal != null) {
    buf.writeln('- Primary goal: ${ctx.primaryGoal}');
  }
  if (ctx.bodyWeightKgLatest != null ||
      ctx.heightCmLatest != null ||
      ctx.bmiLatest != null) {
    buf.writeln('\nBody metrics:');
    if (ctx.bodyWeightKgLatest != null) {
      buf.writeln(
        '- Weight: ${ctx.bodyWeightKgLatest!.toStringAsFixed(1)} kg',
      );
    }
    if (ctx.heightCmLatest != null) {
      buf.writeln('- Height: ${ctx.heightCmLatest!.toStringAsFixed(0)} cm');
    }
    if (ctx.bmiLatest != null) {
      buf.writeln('- BMI: ${ctx.bmiLatest!.toStringAsFixed(1)} kg/m²');
    }
  }

  buf.writeln('\nActivity:');
  buf.writeln('- Steps yesterday: ${ctx.stepsYesterday ?? "not available"}');
  buf.writeln(
    '- Active minutes yesterday: ${ctx.activeMinutesYesterday ?? "not available"}',
  );
  buf.writeln(
    '- Sleep last night: ${ctx.sleepMinutesLastNight != null ? "${ctx.sleepMinutesLastNight! ~/ 60}h ${ctx.sleepMinutesLastNight! % 60}m" : "not available"}',
  );
  buf.writeln(
    '- Workout sessions this week: ${ctx.workoutSessionsThisWeek ?? "not available"}',
  );
  buf.writeln(
    '- Workout types: ${ctx.workoutTypesThisWeek.isEmpty ? "none" : ctx.workoutTypesThisWeek.join(", ")}',
  );
  if (ctx.wearableStepsToday != null) {
    buf.writeln('- Wearable steps today: ${ctx.wearableStepsToday}');
  }
  if (ctx.wearableHrvMsLatest != null) {
    buf.writeln(
      '- Latest HRV (wearable, ms): ${ctx.wearableHrvMsLatest!.toStringAsFixed(1)}',
    );
  }

  buf.writeln('\nDiet:');
  buf.writeln(
    '- Avg daily calories (7d): ${ctx.avgCaloriesLast7Days?.toStringAsFixed(0) ?? "not available"}',
  );
  buf.writeln(
    '- Avg protein/carbs/fat (7d): ${ctx.avgProteinGramsLast7Days?.toStringAsFixed(0) ?? "?"}g / ${ctx.avgCarbsGramsLast7Days?.toStringAsFixed(0) ?? "?"}g / ${ctx.avgFatGramsLast7Days?.toStringAsFixed(0) ?? "?"}g',
  );
  buf.writeln(
    '- Avg water intake (7d): ${ctx.avgWaterMlLast7Days?.toStringAsFixed(0) ?? "not available"} mL',
  );

  buf.writeln('\nCommunity events & duels:');
  buf.writeln(
    '- Joined events (public + private): ${ctx.joinedEventsCount ?? 0}',
  );
  buf.writeln(
    '- Active duels: ${ctx.activeChallengesCount ?? 0}',
  );
  if (ctx.activeCommunityTargets.isNotEmpty) {
    for (final String line in ctx.activeCommunityTargets.take(6)) {
      buf.writeln('- $line');
    }
  } else {
    buf.writeln('- No active community targets currently detected');
  }

  buf.writeln('\nHealth vitals (out-of-range only):');
  if (ctx.outOfRangeVitals.isEmpty) {
    buf.writeln('- All recent vitals within typical ranges');
  } else {
    for (final OutOfRangeVital v in ctx.outOfRangeVitals) {
      buf.writeln('- ${v.vitalName}: ${v.status}');
    }
  }
  if (ctx.activeMedicationNames.isNotEmpty) {
    buf.writeln(
      '- Active medications: ${ctx.activeMedicationNames.length} (count only)',
    );
  }
  if (ctx.avgBloodGlucoseLatest != null) {
    buf.writeln(
      '- Avg blood glucose (logged): ${ctx.avgBloodGlucoseLatest!.toStringAsFixed(0)} mg/dL',
    );
  }

  buf.writeln('\nMental wellbeing:');
  buf.writeln('- Today\'s mood: ${ctx.todayMood?.name ?? "not logged"}');
  buf.writeln(
    '- Stress level: ${ctx.stressLevel?.name ?? "not available"} (score: ${ctx.currentStressScore?.toStringAsFixed(0) ?? "N/A"}/100)',
  );
  if (ctx.phq9Severity != null || ctx.gad7Severity != null) {
    buf.writeln('- Mental health check-ins: completed recently');
  }

  return buf.toString();
}
