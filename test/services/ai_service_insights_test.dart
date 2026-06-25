import 'package:fitup/features/insights/domain/entities/holistic_context.dart';
import 'package:fitup/services/ai_input_sanitizer.dart';
import 'package:fitup/services/ai_service.dart';
import 'package:fitup/services/holistic_prompt_formatter.dart';
import 'package:fitup/services/models/weekly_report_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildHolisticPromptContext: does not contain userId, email, or DOB', () {
    const HolisticContext ctx = HolisticContext(
      ageGroup: '30s',
      gender: 'male',
      primaryGoal: 'Weight loss',
      stepsYesterday: 5000,
    );
    final String out = buildHolisticPromptContext(ctx);
    expect(out.toLowerCase(), isNot(contains('userid')));
    expect(out, isNot(contains('@')));
    expect(out.toLowerCase(), isNot(contains('dob')));
    expect(out.toLowerCase(), isNot(contains('date of birth')));
  });

  test('sanitizeProfileText truncates user chat input to 1000 chars max', () {
    final String raw = 'a' * 1500;
    final String s = AiInputSanitizer.sanitizeProfileText(
      raw,
      maxLength: 1000,
    );
    expect(s.length, 1000);
  });

  test('parseWeeklyReportContentFromModel throws on invalid JSON (AiService maps to AiFailure)',
      () {
    expect(
      () => parseWeeklyReportContentFromModel('not json at all'),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => parseWeeklyReportContentFromModel('[1,2,3]'),
      throwsA(isA<FormatException>()),
    );
  });

  test('weekly holistic analysis uses Pro model id constant', () {
    expect(AiService.weeklyHolisticModelId, 'gemini-1.5-pro');
  });
}
