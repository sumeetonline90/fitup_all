import 'dart:async';

import 'package:fitup/core/theme/app_colors.dart';
import 'package:fitup/features/insights/domain/entities/chat_message.dart';
import 'package:fitup/features/insights/domain/entities/correlation_alert.dart';
import 'package:fitup/features/insights/domain/entities/daily_briefing.dart';
import 'package:fitup/features/insights/presentation/providers/insights_providers.dart';
import 'package:fitup/features/insights/presentation/screens/ai_chat_screen.dart';
import 'package:fitup/features/insights/presentation/widgets/chat_bubble.dart';
import 'package:fitup/features/insights/presentation/widgets/correlation_alert_card.dart';
import 'package:fitup/features/insights/presentation/widgets/daily_briefing_card.dart';
import 'package:fitup/shared/widgets/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CorrelationAlertCard shows amber border for warning severity',
      (WidgetTester tester) async {
    final CorrelationAlert alert = CorrelationAlert(
      id: '1',
      type: AlertType.conflict,
      severity: AlertSeverity.warning,
      title: 'Test title',
      message: 'Test message body',
      modules: <String>['Activity'],
      generatedAt: DateTime(2025),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CorrelationAlertCard(alert: alert),
        ),
      ),
    );
    final DecoratedBox box = tester.widget<DecoratedBox>(
      find.byKey(const Key('correlation-accent-border')),
    );
    final BoxDecoration d = box.decoration as BoxDecoration;
    final BorderSide left = (d.border! as Border).left;
    expect(left.color, AppColors.warningAmber);
  });

  testWidgets('CorrelationAlertCard dismiss button calls onDismiss',
      (WidgetTester tester) async {
    int calls = 0;
    final CorrelationAlert alert = CorrelationAlert(
      id: 'x',
      type: AlertType.recommendation,
      severity: AlertSeverity.info,
      title: 'T',
      message: 'M',
      modules: <String>[],
      generatedAt: DateTime(2025),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CorrelationAlertCard(
            alert: alert,
            onDismiss: () => calls++,
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets('ChatBubble renders user text right-aligned', (WidgetTester tester) async {
    final ChatMessage msg = ChatMessage(
      id: '1',
      role: ChatRole.user,
      content: 'Hello',
      timestamp: DateTime(2025, 1, 1, 12),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatBubble(message: msg),
        ),
      ),
    );
    final Row row = tester.widget<Row>(find.byType(Row));
    expect(row.mainAxisAlignment, MainAxisAlignment.end);
  });

  testWidgets('AiChatScreen disables send button when input is empty',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          insightChatMessagesProvider.overrideWith(
            (Ref ref) => Future<List<ChatMessage>>.value(<ChatMessage>[]),
          ),
          aiChatDisclaimerCollapsedProvider.overrideWith(
            _CollapsedDisclaimerNotifier.new,
          ),
        ],
        child: const MaterialApp(home: AiChatScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final IconButton send = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.send_rounded),
    );
    expect(send.onPressed, isNull);
  });

  testWidgets('AiChatScreen shows disclaimer on first launch (empty history)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          insightChatMessagesProvider.overrideWith(
            (Ref ref) => Future<List<ChatMessage>>.value(<ChatMessage>[]),
          ),
          aiChatDisclaimerCollapsedProvider.overrideWith(
            _OpenDisclaimerNotifier.new,
          ),
        ],
        child: const MaterialApp(home: AiChatScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('AI responses are general wellness guidance'),
      findsOneWidget,
    );
  });

  testWidgets('DailyBriefingCard shows shimmer while loading',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyBriefingProvider.overrideWith(_PendingDailyBriefingNotifier.new),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DailyBriefingCard()),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(ShimmerLoading), findsWidgets);
  });
}

class _CollapsedDisclaimerNotifier extends AiChatDisclaimerNotifier {
  @override
  Future<bool> build() async => true;
}

class _OpenDisclaimerNotifier extends AiChatDisclaimerNotifier {
  @override
  Future<bool> build() async => false;
}

class _PendingDailyBriefingNotifier extends DailyBriefingNotifier {
  @override
  Future<DailyBriefing> build() => Completer<DailyBriefing>().future;
}
