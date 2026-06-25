enum AlertType { conflict, encouragement, recommendation }

enum AlertSeverity { info, warning, critical }

class CorrelationAlert {
  const CorrelationAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.modules,
    required this.generatedAt,
    this.isDismissed = false,
  });

  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final List<String> modules;
  final DateTime generatedAt;
  final bool isDismissed;

  CorrelationAlert copyWith({bool? isDismissed}) {
    return CorrelationAlert(
      id: id,
      type: type,
      severity: severity,
      title: title,
      message: message,
      modules: modules,
      generatedAt: generatedAt,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }
}
