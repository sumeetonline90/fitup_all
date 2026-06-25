/// When [getWeeklyReport] may call Gemini Pro without an explicit user tap.
///
/// ADR-016: Pro only for weekly report; avoid Pro on passive `ref.watch` except
/// Sunday auto or Remote Config (product-controlled).
class WeeklyReportProGate {
  const WeeklyReportProGate({
    this.remoteConfigAllowsAutoPro = false,
  });

  /// Wire to Firebase Remote Config when available (`insights_weekly_pro_auto`).
  final bool remoteConfigAllowsAutoPro;

  /// Sunday end-of-week refresh is allowed without an extra tap.
  bool shouldAllowAutoPro(DateTime now) =>
      remoteConfigAllowsAutoPro || now.weekday == DateTime.sunday;
}
