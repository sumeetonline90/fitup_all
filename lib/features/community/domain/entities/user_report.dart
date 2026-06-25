import 'report_reason.dart';

class UserReport {
  const UserReport({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String reporterId;
  final String reportedUserId;
  final ReportReason reason;
  final DateTime createdAt;
}
