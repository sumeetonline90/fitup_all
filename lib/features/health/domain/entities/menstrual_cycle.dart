import 'flow_intensity.dart';

class MenstrualCycle {
  const MenstrualCycle({
    required this.id,
    required this.userId,
    required this.cycleStart,
    this.cycleEnd,
    this.cycleLength,
    this.flowIntensity,
    this.symptoms = const <String>[],
    this.notes,
  });

  final String id;
  final String userId;
  final DateTime cycleStart;
  final DateTime? cycleEnd;
  final int? cycleLength;
  final FlowIntensity? flowIntensity;
  final List<String> symptoms;
  final String? notes;
}
