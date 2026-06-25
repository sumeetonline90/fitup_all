import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injection.dart';
import '../../../../services/ai_usage_service.dart';

part 'ai_usage_provider.g.dart';

/// Loads persisted Gemini usage for Settings.
@riverpod
Future<AiUsageSnapshot> aiUsageSnapshot(Ref ref) {
  return getIt<AiUsageService>().getSnapshot();
}
