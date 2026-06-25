/// Sanitize free-form user text before sending to Gemini (PII + prompt-injection).
class AiInputSanitizer {
  AiInputSanitizer._();

  static final RegExp _email = RegExp(r'[\w.-]+@[\w.-]+\.\w+');
  static final RegExp _phone = RegExp(r'\+?\d[\d\s\-]{8,}\d');

  /// User meal descriptions / voice logging.
  static String sanitizeMealDescription(String raw) {
    return _sanitize(raw, maxLength: 500);
  }

  /// Shorter snippets for secondary context lines (activity, health blurbs).
  static String sanitizeContextSnippet(String? raw, {int maxLength = 800}) {
    if (raw == null || raw.isEmpty) {
      return '';
    }
    return _sanitize(raw, maxLength: maxLength);
  }

  /// Profile / plan text from user-editable fields.
  static String sanitizeProfileText(String raw, {int maxLength = 2000}) {
    return _sanitize(raw, maxLength: maxLength);
  }

  static String _sanitize(String raw, {required int maxLength}) {
    var s = raw;
    if (s.length > maxLength) {
      s = s.substring(0, maxLength);
    }
    s = s.replaceAll(_email, '[email]');
    s = s.replaceAll(_phone, '[phone]');
    s = _truncateAtInjectionMarkers(s);
    return s.trim();
  }

  /// Removes trailing content after likely jailbreak / instruction-injection cues.
  static String _truncateAtInjectionMarkers(String input) {
    final String lower = input.toLowerCase();
    const List<String> markers = <String>[
      'ignore previous',
      'forget previous',
      'disregard previous',
      'ignore all prior',
      'system:',
      'assistant:',
      '### instruction',
      'you are now',
    ];
    int cut = input.length;
    for (final String m in markers) {
      final int i = lower.indexOf(m);
      if (i >= 0 && i < cut) {
        cut = i;
      }
    }
    return input.substring(0, cut).trimRight();
  }
}
