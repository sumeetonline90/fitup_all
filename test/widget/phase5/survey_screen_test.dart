import 'package:fitup/features/mental_wellbeing/domain/entities/survey_type.dart';
import 'package:fitup/features/mental_wellbeing/presentation/screens/survey_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SurveyScreen advances to next question on answer selection',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SurveyScreen(type: SurveyType.phq9),
        ),
      ),
    );
    expect(find.textContaining('Question 1 of 9'), findsOneWidget);
    await tester.tap(find.text('Several days').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Question 2 of 9'), findsOneWidget);
  });
}
