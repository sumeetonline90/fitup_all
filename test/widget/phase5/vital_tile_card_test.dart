import 'package:fitup/features/health/domain/entities/vital_status.dart';
import 'package:fitup/features/health/domain/entities/vital_type.dart';
import 'package:fitup/features/health/presentation/health_ui_models.dart';
import 'package:fitup/features/health/presentation/widgets/vital_status_colors.dart';
import 'package:fitup/features/health/presentation/widgets/vital_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('VitalTileCard shows amber indicator when value is borderline',
      (WidgetTester tester) async {
    const VitalSummaryTile tile = VitalSummaryTile(
      type: VitalType.fastingBloodSugar,
      latestValue: 105,
      recordedAt: null,
      status: VitalStatus.borderline,
      hasData: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VitalTileCard(
            tile: tile,
            onTap: _noop,
          ),
        ),
      ),
    );
    final Color expected = vitalStatusColor(VitalStatus.borderline);
    final Finder dotFinder = find.byWidgetPredicate(
      (Widget w) {
        if (w is! Container) {
          return false;
        }
        final Decoration? d = w.decoration;
        return d is BoxDecoration && d.shape == BoxShape.circle;
      },
    );
    expect(dotFinder, findsOneWidget);
    final Container dot = tester.widget<Container>(dotFinder);
    final BoxDecoration? dec = dot.decoration as BoxDecoration?;
    expect(dec?.color, expected);
  });
}

void _noop() {}
