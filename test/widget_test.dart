// Smoke test — unauthenticated route shows login.

import 'package:fitup/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FitupApp shows login when not signed in', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FitupApp()));
    await tester.pumpAndSettle();
    expect(find.textContaining('Welcome'), findsWidgets);
  });
}
