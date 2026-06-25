import 'package:fitup/features/mental_wellbeing/domain/entities/meditation_sound.dart';
import 'package:fitup/features/mental_wellbeing/presentation/screens/meditation_timer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('MeditationTimer completion does not double-dispose pulse controller',
      (WidgetTester tester) async {
    final GoRouter router = GoRouter(
      initialLocation: '/t',
      routes: <RouteBase>[
        GoRoute(
          path: '/t',
          builder: (BuildContext context, GoRouterState state) =>
              const MeditationTimerScreen(
            totalSeconds: 1,
            sound: MeditationSound.silent,
          ),
        ),
        GoRoute(
          path: '/mental/meditation/complete',
          builder: (BuildContext context, GoRouterState state) =>
              const Scaffold(body: Text('complete')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
