import 'package:fitup/core/theme/app_colors.dart';
import 'package:fitup/features/mental_wellbeing/presentation/widgets/stress_score_gauge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StressScoreGauge uses red arc color when score > 75',
      (WidgetTester tester) async {
    expect(stressGaugeArcColorForScore(90), AppColors.error);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StressScoreGauge(score: 90),
        ),
      ),
    );
    expect(find.byType(StressScoreGauge), findsOneWidget);
  });
}
