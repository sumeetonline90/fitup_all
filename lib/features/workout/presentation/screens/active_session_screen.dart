import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/domain/entities/fitup_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/workout.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../providers/workout_providers.dart';

/// Live workout session: timer, sets, rest, exercise list.
class ActiveSessionScreen extends ConsumerStatefulWidget {
  const ActiveSessionScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<ActiveSessionScreen> createState() =>
      _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen> {
  final TextEditingController _reps = TextEditingController();
  final TextEditingController _weight = TextEditingController();
  bool _started = false;

  WorkoutLog _workoutLogFromFitcoinUpdateFailure(
    FitcoinUpdateFailure f,
  ) {
    final ActiveSessionState s = ref.read(activeSessionProvider);
    final WorkoutSession? session = s.session;
    final String? userId = s.userId;
    final DateTime? startTime = s.sessionStartTime;

    // This screen only handles FitcoinUpdateFailure when we already have
    // enough session data to build the completed WorkoutLog.
    if (session == null || userId == null || startTime == null) {
      throw StateError('Missing session context for FitcoinUpdateFailure');
    }

    final List<String> parts = f.savedWorkoutLogId.split('_w_');
    final int? endMillis = parts.isNotEmpty
        ? int.tryParse(parts.last)
        : int.tryParse(f.savedWorkoutLogId);
    final DateTime endTime = endMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(endMillis)
        : DateTime.now();

    final double cal = (s.elapsedSeconds / 60 * 8)
        .clamp(40, 9999)
        .toDouble();

    return WorkoutLog(
      id: f.savedWorkoutLogId,
      userId: userId,
      sessionId: session.id,
      sessionName: session.name,
      startTime: startTime,
      endTime: endTime,
      completedSets: s.completedSets,
      totalCaloriesBurnt: cal,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBegin());
  }

  Future<void> _tryBegin() async {
    if (_started) {
      return;
    }
    final AsyncValue<FitupUser?> auth = ref.read(authStateProvider);
    final FitupUser? user = auth.maybeWhen(
      data: (FitupUser? u) => u,
      orElse: () => null,
    );
    if (user == null) {
      return;
    }
    final Either<Failure, WorkoutPlan?> planRes =
        await ref.read(workoutRepositoryProvider).getActiveWorkoutPlan(user.id);
    final WorkoutPlan? plan = planRes.fold((_) => null, (WorkoutPlan? p) => p);
    if (plan == null || !mounted) {
      return;
    }
    WorkoutSession? session;
    for (final WorkoutSession s in plan.sessions) {
      if (s.id == widget.sessionId) {
        session = s;
        break;
      }
    }
    session ??=
        plan.sessions.isNotEmpty ? plan.sessions.first : null;
    if (session == null) {
      return;
    }
    ref.read(activeSessionProvider.notifier).beginSession(session, user.id);
    _started = true;
    _syncFieldsFromState();
  }

  void _syncFieldsFromState() {
    final SessionExercise? ex =
        ref.read(activeSessionProvider).currentExercise;
    if (ex != null) {
      _reps.text = '${ex.reps ?? 10}';
      _weight.text =
          ex.weightKg != null ? ex.weightKg!.toStringAsFixed(1) : '20.0';
    }
  }

  @override
  void dispose() {
    _reps.dispose();
    _weight.dispose();
    super.dispose();
  }

  String _formatMmSs(int totalSec) {
    final int m = totalSec ~/ 60;
    final int s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmFinish() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: Text('Finish session?', style: AppTextStyles.headlineMedium),
        content: Text(
          'End this workout and save what you logged so far?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AppTextStyles.labelSmall),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Finish',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      ref.read(activeSessionProvider.notifier).finishEarly();
      await _persistAndExit();
    }
  }

  void _handleFinishEither(Either<Failure, WorkoutLog> r) {
    r.fold(
      (Failure f) {
        if (f is FitcoinUpdateFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                f.message ?? 'Fitcoins will sync shortly.',
              ),
            ),
          );
          context.pushReplacement(
            '/workout/complete',
            extra: _workoutLogFromFitcoinUpdateFailure(f),
          );
          ref.read(activeSessionProvider.notifier).reset();
          return;
        }
        _showWorkoutSaveFailureSnackBar();
      },
      (WorkoutLog log) {
        context.pushReplacement('/workout/complete', extra: log);
        ref.read(activeSessionProvider.notifier).reset();
      },
    );
  }

  void _showWorkoutSaveFailureSnackBar() {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 10),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                "Couldn't save workout. Your session data is kept locally. "
                'Try again or close to discard.',
                style: AppTextStyles.bodySmall,
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                context.pop();
                ref.read(activeSessionProvider.notifier).reset();
              },
              child: Text('Discard', style: AppTextStyles.labelSmall),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () async {
            final Either<Failure, WorkoutLog> r =
                await ref.read(activeSessionProvider.notifier).retrySave();
            if (!context.mounted) {
              return;
            }
            _handleFinishEither(r);
          },
        ),
      ),
    );
  }

  Future<void> _persistAndExit() async {
    final Either<Failure, WorkoutLog> r =
        await ref.read(activeSessionProvider.notifier).finishSession();
    if (!mounted) {
      return;
    }
    _handleFinishEither(r);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<FitupUser?>>(authStateProvider, (
      AsyncValue<FitupUser?>? prev,
      AsyncValue<FitupUser?> next,
    ) {
      if (next.hasValue && next.value != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _tryBegin());
      }
    });
    ref.listen<ActiveSessionState>(activeSessionProvider, (
      ActiveSessionState? prev,
      ActiveSessionState next,
    ) {
      if (prev != null &&
          prev.exerciseIndex != next.exerciseIndex &&
          !next.isResting) {
        _syncFieldsFromState();
      }
    });

    final ActiveSessionState state = ref.watch(activeSessionProvider);
    final WorkoutSession? session = state.session;

    if (session == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Session unavailable',
                  style: AppTextStyles.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Open a workout from your active plan.',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'Back',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final int elapsed = state.elapsedSeconds;
    final bool resting = state.isResting;
    final int restLeft = state.restSecondsRemaining;
    final SessionExercise? ex = state.currentExercise;

    if (ex == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final int setOf = ex.sets;
    final int setNum = state.currentSet.clamp(1, setOf);
    final double exProgress =
        (state.exerciseIndex + setNum / setOf) / session.exercises.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: <Widget>[
                  Semantics(
                    button: true,
                    label: 'Close workout',
                    child: IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close),
                      onPressed: _confirmFinish,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      session.name,
                      style: AppTextStyles.headlineMedium.copyWith(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Text(
              _formatMmSs(elapsed),
              style: AppTextStyles.displayLarge.copyWith(fontSize: 44),
              textAlign: TextAlign.center,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: <Widget>[
                  Text(
                    'Exercise ${state.exerciseIndex + 1} of ${session.exercises.length}',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: exProgress.clamp(0.0, 1.0),
                    backgroundColor: AppColors.surfaceContainerHighest,
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ),
            if (resting)
              Expanded(
                child: _RestOverlay(
                  seconds: restLeft,
                  totalSeconds: ex.restSeconds,
                  onSkip: () =>
                      ref.read(activeSessionProvider.notifier).skipRest(),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    GlassCard(
                      glowColor: AppColors.secondary,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            ex.exerciseName,
                            style: AppTextStyles.headlineMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Set $setNum of $setOf',
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: TextField(
                                  controller: _reps,
                                  keyboardType: TextInputType.number,
                                  style: AppTextStyles.bodyLarge,
                                  decoration: InputDecoration(
                                    labelText: 'Reps',
                                    labelStyle: AppTextStyles.bodySmall,
                                    filled: true,
                                    fillColor: AppColors.surfaceContainerHigh,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _weight,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  style: AppTextStyles.bodyLarge,
                                  decoration: InputDecoration(
                                    labelText: 'Weight (kg)',
                                    labelStyle: AppTextStyles.bodySmall,
                                    filled: true,
                                    fillColor: AppColors.surfaceContainerHigh,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Semantics(
                            button: true,
                            label: 'Mark set complete',
                            child: NeonButton(
                              label: 'Mark set complete',
                              icon: Icons.check,
                              onPressed: resting
                                  ? null
                                  : () async {
                                      final int? r =
                                          int.tryParse(_reps.text.trim());
                                      final double? w = double.tryParse(
                                        _weight.text.trim(),
                                      );
                                      if (r == null || w == null) {
                                        return;
                                      }
                                      final WorkoutLog? done = await ref
                                          .read(activeSessionProvider.notifier)
                                          .completeSet(
                                            reps: r,
                                            weightKg: w,
                                          );
                                      if (!context.mounted) {
                                        return;
                                      }
                                      if (done == null) {
                                        final Failure? err =
                                            ref.read(activeSessionProvider)
                                                .saveError;
                                        if (err != null &&
                                            err is! FitcoinUpdateFailure) {
                                          _showWorkoutSaveFailureSnackBar();
                                        }
                                        return;
                                      }
                                      final Failure? postErr =
                                          ref.read(activeSessionProvider)
                                              .saveError;
                                      if (postErr is FitcoinUpdateFailure) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              postErr.message ??
                                                  'Fitcoins will sync shortly.',
                                            ),
                                          ),
                                        );
                                      }
                                      HapticFeedback.mediumImpact();
                                      context.pushReplacement(
                                        '/workout/complete',
                                        extra: done,
                                      );
                                      ref
                                          .read(activeSessionProvider.notifier)
                                          .reset();
                                    },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Material(
              color: AppColors.surfaceContainer,
              child: ListTile(
                leading: const Icon(Icons.list_alt, color: AppColors.secondary),
                title: Text(
                  'Exercise list & skip',
                  style: AppTextStyles.bodyLarge,
                ),
                trailing: const Icon(Icons.expand_less),
                onTap: () => _showExerciseSheet(context, state),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Semantics(
                button: true,
                label: 'Finish workout session',
                child: NeonButton(
                  label: 'Finish session',
                  icon: Icons.flag,
                  onPressed: _confirmFinish,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExerciseSheet(BuildContext context, ActiveSessionState session) {
    final WorkoutSession? s = session.session;
    if (s == null) {
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (BuildContext ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (_, ScrollController c) => ListView(
          controller: c,
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text('Session exercises', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 12),
            ...List<Widget>.generate(s.exercises.length, (int i) {
              final SessionExercise e = s.exercises[i];
              final bool current = i == session.exerciseIndex;
              return ListTile(
                title: Text(
                  e.exerciseName,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: current ? AppColors.secondary : AppColors.onSurface,
                  ),
                ),
                subtitle: Text(
                  '${e.sets} sets',
                  style: AppTextStyles.bodySmall,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(activeSessionProvider.notifier).goToExercise(i);
                  _syncFieldsFromState();
                },
              );
            }),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(activeSessionProvider.notifier).skipCurrentExercise();
                _syncFieldsFromState();
              },
              icon: const Icon(Icons.skip_next, color: AppColors.tertiary),
              label: Text(
                'Skip current exercise',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.tertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestOverlay extends StatelessWidget {
  const _RestOverlay({
    required this.seconds,
    required this.totalSeconds,
    required this.onSkip,
  });

  final int seconds;
  final int totalSeconds;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final int t = totalSeconds <= 0 ? 1 : totalSeconds;
    final double pulse = 140 + (t - seconds).clamp(0, t).toDouble() * 0.4;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Resting…', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 16),
          Semantics(
            label: 'Rest timer $seconds seconds',
            child: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: pulse.clamp(120, 190),
                    height: pulse.clamp(120, 190),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.6),
                        width: 4,
                      ),
                    ),
                  ),
                  Text(
                    '${seconds}s',
                    style: AppTextStyles.displayLarge.copyWith(fontSize: 36),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Semantics(
            button: true,
            label: 'Skip rest timer',
            child: TextButton(
              onPressed: onSkip,
              child: Text(
                'Skip rest',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.secondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
