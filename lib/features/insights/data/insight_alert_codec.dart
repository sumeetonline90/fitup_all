import 'dart:convert';

import 'package:fitup/features/insights/domain/entities/correlation_alert.dart';

String encodeCorrelationAlerts(List<CorrelationAlert> alerts) =>
    jsonEncode(alerts.map(_alertToMap).toList());

List<CorrelationAlert> decodeCorrelationAlerts(String raw) {
  final Object? d = jsonDecode(raw);
  if (d is! List<dynamic>) {
    return <CorrelationAlert>[];
  }
  return d
      .map((dynamic e) {
        if (e is Map<String, dynamic>) {
          return _alertFromMap(e);
        }
        return null;
      })
      .whereType<CorrelationAlert>()
      .toList();
}

Map<String, dynamic> _alertToMap(CorrelationAlert a) {
  return <String, dynamic>{
    'id': a.id,
    'type': a.type.name,
    'severity': a.severity.name,
    'title': a.title,
    'message': a.message,
    'modules': a.modules,
    'generatedAt': a.generatedAt.toIso8601String(),
    'isDismissed': a.isDismissed,
  };
}

CorrelationAlert _alertFromMap(Map<String, dynamic> m) {
  return CorrelationAlert(
    id: m['id'] as String? ?? '',
    type: AlertType.values.firstWhere(
      (AlertType t) => t.name == (m['type'] as String? ?? 'recommendation'),
      orElse: () => AlertType.recommendation,
    ),
    severity: AlertSeverity.values.firstWhere(
      (AlertSeverity s) => s.name == (m['severity'] as String? ?? 'info'),
      orElse: () => AlertSeverity.info,
    ),
    title: m['title'] as String? ?? '',
    message: m['message'] as String? ?? '',
    modules:
        (m['modules'] as List<dynamic>?)
            ?.map((dynamic e) => e.toString())
            .toList() ??
        const <String>[],
    generatedAt:
        DateTime.tryParse(m['generatedAt'] as String? ?? '') ?? DateTime.now(),
    isDismissed: m['isDismissed'] as bool? ?? false,
  );
}
