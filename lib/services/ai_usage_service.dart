import 'package:shared_preferences/shared_preferences.dart';

/// Gemini model tier for local usage accounting (not sent to API).
enum AiUsageModelKind { flash, flashLite, pro }

/// Point-in-time stats for Settings and debugging.
class AiUsageSnapshot {
  const AiUsageSnapshot({
    required this.totalCalls,
    required this.flashCalls,
    required this.flashLiteCalls,
    required this.proCalls,
    required this.callsLastHour,
    required this.totalEstimatedPromptTokens,
    required this.totalEstimatedResponseTokens,
    required this.flashEstimatedTokens,
    required this.flashLiteEstimatedTokens,
    required this.proEstimatedTokens,
  });

  final int totalCalls;
  final int flashCalls;
  final int flashLiteCalls;
  final int proCalls;
  final int callsLastHour;
  final int totalEstimatedPromptTokens;
  final int totalEstimatedResponseTokens;
  final int flashEstimatedTokens;
  final int flashLiteEstimatedTokens;
  final int proEstimatedTokens;

  /// Soft guideline from product rules (client-side cost control).
  static const int suggestedHourlyLimit = 30;
}

/// Persists Gemini [generateContent] usage in SharedPreferences.
class AiUsageService {
  static const String _kTotal = 'fitup_ai_usage_total';
  static const String _kFlash = 'fitup_ai_usage_flash';
  static const String _kFlashLite = 'fitup_ai_usage_flash_lite';
  static const String _kPro = 'fitup_ai_usage_pro';
  static const String _kHourStartMs = 'fitup_ai_usage_hour_start_ms';
  static const String _kHourCount = 'fitup_ai_usage_hour_count';
  static const String _kPromptTokens = 'fitup_ai_usage_prompt_tokens';
  static const String _kResponseTokens = 'fitup_ai_usage_response_tokens';
  static const String _kFlashTokens = 'fitup_ai_usage_flash_tokens';
  static const String _kFlashLiteTokens = 'fitup_ai_usage_flash_lite_tokens';
  static const String _kProTokens = 'fitup_ai_usage_pro_tokens';

  static const int _hourMs = 60 * 60 * 1000;

  /// Records one successful API round-trip after [generateContent] returns.
  Future<void> record(
    AiUsageModelKind kind, {
    int promptChars = 0,
    int responseChars = 0,
  }) async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int startMs = p.getInt(_kHourStartMs) ?? 0;
    if (startMs == 0 || nowMs - startMs >= _hourMs) {
      await p.setInt(_kHourStartMs, nowMs);
      await p.setInt(_kHourCount, 0);
    }
    final int total = (p.getInt(_kTotal) ?? 0) + 1;
    await p.setInt(_kTotal, total);
    switch (kind) {
      case AiUsageModelKind.flash:
        await p.setInt(_kFlash, (p.getInt(_kFlash) ?? 0) + 1);
      case AiUsageModelKind.flashLite:
        await p.setInt(_kFlashLite, (p.getInt(_kFlashLite) ?? 0) + 1);
      case AiUsageModelKind.pro:
        await p.setInt(_kPro, (p.getInt(_kPro) ?? 0) + 1);
    }
    final int promptTokens = _estimateTokens(promptChars);
    final int responseTokens = _estimateTokens(responseChars);
    final int totalTokens = promptTokens + responseTokens;
    await p.setInt(_kPromptTokens, (p.getInt(_kPromptTokens) ?? 0) + promptTokens);
    await p.setInt(
      _kResponseTokens,
      (p.getInt(_kResponseTokens) ?? 0) + responseTokens,
    );
    switch (kind) {
      case AiUsageModelKind.flash:
        await p.setInt(_kFlashTokens, (p.getInt(_kFlashTokens) ?? 0) + totalTokens);
      case AiUsageModelKind.flashLite:
        await p.setInt(
          _kFlashLiteTokens,
          (p.getInt(_kFlashLiteTokens) ?? 0) + totalTokens,
        );
      case AiUsageModelKind.pro:
        await p.setInt(_kProTokens, (p.getInt(_kProTokens) ?? 0) + totalTokens);
    }
    await p.setInt(_kHourCount, (p.getInt(_kHourCount) ?? 0) + 1);
  }

  int _estimateTokens(int chars) {
    if (chars <= 0) return 0;
    return (chars / 4).ceil();
  }

  /// Reads counters. [callsLastHour] is 0 if the rolling hour has expired
  /// (without mutating stored prefs).
  Future<AiUsageSnapshot> getSnapshot() async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int startMs = p.getInt(_kHourStartMs) ?? 0;
    final int storedHourCount = p.getInt(_kHourCount) ?? 0;
    final bool windowExpired =
        startMs == 0 || nowMs - startMs >= _hourMs;
    final int callsLastHour = windowExpired ? 0 : storedHourCount;
    return AiUsageSnapshot(
      totalCalls: p.getInt(_kTotal) ?? 0,
      flashCalls: p.getInt(_kFlash) ?? 0,
      flashLiteCalls: p.getInt(_kFlashLite) ?? 0,
      proCalls: p.getInt(_kPro) ?? 0,
      callsLastHour: callsLastHour,
      totalEstimatedPromptTokens: p.getInt(_kPromptTokens) ?? 0,
      totalEstimatedResponseTokens: p.getInt(_kResponseTokens) ?? 0,
      flashEstimatedTokens: p.getInt(_kFlashTokens) ?? 0,
      flashLiteEstimatedTokens: p.getInt(_kFlashLiteTokens) ?? 0,
      proEstimatedTokens: p.getInt(_kProTokens) ?? 0,
    );
  }
}
