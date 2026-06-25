import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/domain/entities/fitup_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/holistic_context.dart';
import '../../domain/services/holistic_context_builder.dart';

part 'insight_providers.g.dart';

FitupUser? _user(Ref ref) => switch (ref.watch(authStateProvider)) {
  AsyncData<FitupUser?>(:final value) => value,
  _ => null,
};

/// Registered [HolisticContextBuilder] (parallel repo reads, no AI).
@riverpod
HolisticContextBuilder holisticContextBuilder(Ref ref) =>
    getIt<HolisticContextBuilder>();

/// Anonymized cross-module snapshot for AI prompts. Invalidates when auth changes.
@riverpod
Future<HolisticContext> holisticContext(Ref ref) async {
  final FitupUser? u = _user(ref);
  if (u == null) {
    throw StateError('Not signed in');
  }
  final HolisticContextBuilder builder = ref.watch(
    holisticContextBuilderProvider,
  );
  return builder.buildFor(u.id);
}
