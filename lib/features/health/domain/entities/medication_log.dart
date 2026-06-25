import 'medication_reminder_time.dart';

class MedicationLog {
  const MedicationLog({
    required this.id,
    required this.userId,
    required this.medicationName,
    required this.dose,
    required this.frequency,
    required this.isActive,
    required this.startDate,
    this.reminderTime,
    this.endDate,
  });

  final String id;
  final String userId;
  final String medicationName;
  final String dose;
  final String frequency;
  final MedicationReminderTime? reminderTime;
  final bool isActive;
  final DateTime startDate;
  final DateTime? endDate;
}
