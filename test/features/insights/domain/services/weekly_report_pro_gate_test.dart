import 'package:fitup/features/insights/domain/services/weekly_report_pro_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Sunday allows auto Pro without Remote Config', () {
    const WeeklyReportProGate gate = WeeklyReportProGate();
    final DateTime sunday = DateTime(2026, 3, 22); // Sunday
    expect(gate.shouldAllowAutoPro(sunday), isTrue);
  });

  test('Monday does not allow auto Pro unless Remote Config', () {
    const WeeklyReportProGate gate = WeeklyReportProGate();
    final DateTime monday = DateTime(2026, 3, 23);
    expect(gate.shouldAllowAutoPro(monday), isFalse);
  });

  test('Remote Config flag allows auto Pro on any weekday', () {
    const WeeklyReportProGate gate = WeeklyReportProGate(
      remoteConfigAllowsAutoPro: true,
    );
    expect(gate.shouldAllowAutoPro(DateTime(2026, 3, 23)), isTrue);
  });
}
