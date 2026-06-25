import 'dart:async';
import 'dart:collection';

import 'package:dartz/dartz.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../services/ai_service.dart';
import '../../../../services/foreground_task_service.dart';
import '../../../../services/location_service.dart';
import '../../../../services/logger_service.dart';
import '../../../../services/models/ai_insight.dart';
import '../../../auth/domain/entities/fitup_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../fitcoins/domain/services/fitcoin_award_service.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_stats.dart';
import '../../domain/entities/sleep_log.dart';
import '../../domain/repositories/activity_repository.dart';

part 'activity_providers.g.dart';

/// Live tracking lifecycle for GPS sessions.
enum ActivityTrackingStatus {
  idle,
  active,
  paused,
  saving,

  /// Location permission not granted; [ActivityTrackingState.type] holds the
  /// activity the user chose (for retry).
  locationPermissionDenied,
}

/// Inferred GPS signal quality during an active session.
///
/// We infer "weak/lost" when we stop receiving location updates for a
/// threshold period (since the underlying stream only yields non-null
/// positions).
enum GpsSignalStatus { strong, weak, lost }

/// HUD state for the activity tracker.
class ActivityTrackingState {
  const ActivityTrackingState({
    required this.status,
    this.type,
    this.elapsed = Duration.zero,
    this.distanceMeters = 0,
    this.caloriesBurnt = 0,
    this.steps = 0,
    this.currentPace = 0,
    this.currentSpeedKmh = 0,
    this.avgSpeedKmh = 0,
    this.routePoints = const <LatLng>[],
    this.gpsSignal = GpsSignalStatus.strong,
    this.consecutiveFailedLocationFetches = 0,
    this.deadReckoningMeters = 0,
    this.fitcoinsEarned = 0,
  });

  final ActivityTrackingStatus status;
  final ActivityType? type;
  final Duration elapsed;
  final double distanceMeters;
  final double caloriesBurnt;
  final int steps;
  final double currentPace;
  final double currentSpeedKmh;
  final double avgSpeedKmh;
  final List<LatLng> routePoints;
  final GpsSignalStatus gpsSignal;
  final int consecutiveFailedLocationFetches;
  final double deadReckoningMeters;
  final int fitcoinsEarned;

  factory ActivityTrackingState.idle() =>
      const ActivityTrackingState(status: ActivityTrackingStatus.idle);

  ActivityTrackingState copyWith({
    ActivityTrackingStatus? status,
    ActivityType? type,
    Duration? elapsed,
    double? distanceMeters,
    double? caloriesBurnt,
    int? steps,
    double? currentPace,
    double? currentSpeedKmh,
    double? avgSpeedKmh,
    List<LatLng>? routePoints,
    GpsSignalStatus? gpsSignal,
    int? consecutiveFailedLocationFetches,
    double? deadReckoningMeters,
    int? fitcoinsEarned,
  }) {
    return ActivityTrackingState(
      status: status ?? this.status,
      type: type ?? this.type,
      elapsed: elapsed ?? this.elapsed,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      caloriesBurnt: caloriesBurnt ?? this.caloriesBurnt,
      steps: steps ?? this.steps,
      currentPace: currentPace ?? this.currentPace,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      routePoints: routePoints ?? this.routePoints,
      gpsSignal: gpsSignal ?? this.gpsSignal,
      consecutiveFailedLocationFetches:
          consecutiveFailedLocationFetches ??
          this.consecutiveFailedLocationFetches,
      deadReckoningMeters: deadReckoningMeters ?? this.deadReckoningMeters,
      fitcoinsEarned: fitcoinsEarned ?? this.fitcoinsEarned,
    );
  }
}

@riverpod
ActivityRepository activityRepository(Ref ref) => getIt<ActivityRepository>();

@riverpod
LocationService locationService(Ref ref) => getIt<LocationService>();

@riverpod
AiService aiService(Ref ref) => getIt<AiService>();

@riverpod
Stream<List<Activity>> todayActivities(Ref ref) {
  final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
  final FitupUser? user = auth.maybeWhen(
    data: (FitupUser? u) => u,
    orElse: () => null,
  );
  if (user == null) {
    return Stream<List<Activity>>.value(<Activity>[]);
  }
  return ref.read(activityRepositoryProvider).watchTodayActivities(user.id);
}

@riverpod
Future<ActivityStats> weeklyStats(Ref ref) async {
  final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
  final FitupUser? user = auth.maybeWhen(
    data: (FitupUser? u) => u,
    orElse: () => null,
  );
  if (user == null) {
    return ActivityStats.empty();
  }
  final DateTime now = DateTime.now();
  final Either<Failure, ActivityStats> result = await ref
      .read(activityRepositoryProvider)
      .getStats(user.id, now.subtract(const Duration(days: 7)), now);
  return result.fold((_) => ActivityStats.empty(), (ActivityStats s) => s);
}

final activityRangeProvider =
    FutureProvider.family<List<Activity>, ({DateTime from, DateTime to})>((
      Ref ref,
      ({DateTime from, DateTime to}) range,
    ) async {
      final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
      final FitupUser? user = auth.maybeWhen(
        data: (FitupUser? u) => u,
        orElse: () => null,
      );
      if (user == null) {
        return <Activity>[];
      }
      final Either<Failure, List<Activity>> result = await ref
          .read(activityRepositoryProvider)
          .getActivities(user.id, from: range.from, to: range.to);
      return result.fold(
        (Failure _) => <Activity>[],
        (List<Activity> data) => data,
      );
    });

/// Last [limit] GPS-tracked activities (newest first), excluding passive steps.
final recentTrackedActivitiesProvider = FutureProvider<List<Activity>>((
  Ref ref,
) async {
  const int limit = 5;
  final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
  final FitupUser? user = auth.maybeWhen(
    data: (FitupUser? u) => u,
    orElse: () => null,
  );
  if (user == null) {
    return <Activity>[];
  }
  final DateTime now = DateTime.now();
  final Either<Failure, List<Activity>> result = await ref
      .read(activityRepositoryProvider)
      .getActivities(
        user.id,
        from: now.subtract(const Duration(days: 365)),
        to: now,
      );
  return result.fold((Failure _) => <Activity>[], (List<Activity> list) {
    final List<Activity> tracked = list
        .where((Activity a) => !a.id.startsWith('passive_steps_'))
        .toList()
      ..sort((Activity a, Activity b) => b.startTime.compareTo(a.startTime));
    return tracked.take(limit).toList();
  });
});

final sleepRangeProvider =
    FutureProvider.family<List<SleepLog>, ({DateTime from, DateTime to})>((
      Ref ref,
      ({DateTime from, DateTime to}) range,
    ) async {
      final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
      final FitupUser? user = auth.maybeWhen(
        data: (FitupUser? u) => u,
        orElse: () => null,
      );
      if (user == null) {
        return <SleepLog>[];
      }
      final Either<Failure, List<SleepLog>> result = await ref
          .read(activityRepositoryProvider)
          .getSleepLogs(user.id, from: range.from, to: range.to);
      return result.fold(
        (Failure _) => <SleepLog>[],
        (List<SleepLog> data) => data,
      );
    });

@riverpod
Future<AiInsight> activityInsight(Ref ref, String? query) async {
  final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
  final FitupUser? user = auth.maybeWhen(
    data: (FitupUser? u) => u,
    orElse: () => null,
  );
  if (user == null) {
    throw Exception('Not logged in');
  }
  return ref.read(aiServiceProvider).getActivityInsight(user.id, query);
}

@riverpod
class ActivityTracker extends _$ActivityTracker {
  static const double _fallbackWeightKg = 70;
  static const int _maxDeadReckoningSeconds = 30;

  Timer? _timer;
  StreamSubscription<Position>? _locationSub;
  final List<LatLng> _routePoints = <LatLng>[];
  DateTime? _startTime;
  LatLng? _lastPoint;
  int _elapsedSeconds = 0;
  DateTime? _lastGpsUpdateAt;
  bool _hasAcquiredGpsOnce = false;
  int _gpsDropSeconds = 0;
  int _gpsDropInterruptions = 0;
  double _deadReckoningMeters = 0;
  double _lastKnownSpeedMps = 0;
  int _deadReckoningElapsed = 0;

  /// Rolling window of (timestamp, distanceAccumulated) for speed calculations.
  final Queue<(DateTime, double)> _speedSamples = Queue<(DateTime, double)>();

  final ForegroundTaskService _fgService = ForegroundTaskService();

  double get _weightKg {
    try {
      final UserProfile? profile = ref
          .read(userProfileProvider)
          .maybeWhen(data: (UserProfile p) => p, orElse: () => null);
      return profile?.weightKg ?? _fallbackWeightKg;
    } catch (_) {
      return _fallbackWeightKg;
    }
  }

  @override
  ActivityTrackingState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _locationSub?.cancel();
      _locationSub = null;
      FlutterForegroundTask.removeTaskDataCallback(_onForegroundData);
    });
    return ActivityTrackingState.idle();
  }

  Future<void> retryAfterPermission() async {
    final ActivityType? type = state.type;
    if (state.status != ActivityTrackingStatus.locationPermissionDenied ||
        type == null) {
      return;
    }
    await startTracking(type);
  }

  Future<void> startTracking(ActivityType type) async {
    final LocationService loc = ref.read(locationServiceProvider);
    final bool ok = await loc.requestPermission();
    if (!ok) {
      state = ActivityTrackingState(
        status: ActivityTrackingStatus.locationPermissionDenied,
        type: type,
      );
      return;
    }

    _routePoints.clear();
    _lastPoint = null;
    _elapsedSeconds = 0;
    _lastGpsUpdateAt = null;
    _hasAcquiredGpsOnce = false;
    _gpsDropSeconds = 0;
    _gpsDropInterruptions = 0;
    _deadReckoningMeters = 0;
    _lastKnownSpeedMps = 0;
    _deadReckoningElapsed = 0;
    _speedSamples.clear();
    _startTime = DateTime.now();

    state = ActivityTrackingState(
      status: ActivityTrackingStatus.active,
      type: type,
      elapsed: Duration.zero,
      routePoints: const <LatLng>[],
      gpsSignal: GpsSignalStatus.weak,
      consecutiveFailedLocationFetches: 0,
    );

    // Start foreground service for background GPS
    try {
      FlutterForegroundTask.addTaskDataCallback(_onForegroundData);
      await _fgService.start();
    } catch (e, st) {
      LoggerService.e(
        'Failed to start foreground service, falling back',
        e,
        st,
      );
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status != ActivityTrackingStatus.active) return;
      _elapsedSeconds += 1;
      _emitHud(type);
    });

    await _locationSub?.cancel();
    _locationSub = loc.trackLocation().listen((Position p) {
      _onPosition(p, type);
    });
  }

  void _onForegroundData(Object data) {
    if (state.status != ActivityTrackingStatus.active || state.type == null)
      return;
    if (data is Map) {
      final double? lat = data['lat'] as double?;
      final double? lng = data['lng'] as double?;
      if (lat != null && lng != null) {
        final Position pos = Position(
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.now(),
          accuracy: (data['accuracy'] as double?) ?? 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: (data['speed'] as double?) ?? 0,
          speedAccuracy: 0,
        );
        _onPosition(pos, state.type!);
      }
    }
  }

  void _onPosition(Position p, ActivityType type) {
    if (state.status != ActivityTrackingStatus.active) return;

    _lastGpsUpdateAt = DateTime.now();
    _hasAcquiredGpsOnce = true;
    _deadReckoningElapsed = 0;

    if (p.speed > 0) {
      _lastKnownSpeedMps = p.speed;
    }

    final LatLng point = LatLng(p.latitude, p.longitude);
    _routePoints.add(point);

    if (_lastPoint != null) {
      final double d = LocationService.calculateDistance(_lastPoint!, point);
      final double newDist = state.distanceMeters + d;
      final double pace = type == ActivityType.cycle
          ? 0
          : LocationService.calculatePace(newDist, _elapsedSeconds);

      _speedSamples.add((DateTime.now(), newDist));
      _trimSpeedSamples();

      state = state.copyWith(
        distanceMeters: newDist,
        currentPace: pace,
        currentSpeedKmh: _computeCurrentSpeed(),
        avgSpeedKmh: _computeAvgSpeed(newDist),
        steps: _estimateSteps(newDist),
        caloriesBurnt: LocationService.calculateCalories(
          type,
          newDist,
          _weightKg,
        ),
        routePoints: List<LatLng>.from(_routePoints),
        gpsSignal: GpsSignalStatus.strong,
        consecutiveFailedLocationFetches: 0,
        deadReckoningMeters: _deadReckoningMeters,
      );
    } else {
      _speedSamples.add((DateTime.now(), state.distanceMeters));
      state = state.copyWith(
        routePoints: List<LatLng>.from(_routePoints),
        gpsSignal: GpsSignalStatus.strong,
        consecutiveFailedLocationFetches: 0,
      );
    }
    _lastPoint = point;

    _updateNotification();
  }

  void _emitHud(ActivityType type) {
    double dist = state.distanceMeters;
    final DateTime now = DateTime.now();
    final int secondsSinceGps = _lastGpsUpdateAt == null
        ? 999
        : now.difference(_lastGpsUpdateAt!).inSeconds;
    final GpsSignalStatus newSignal = secondsSinceGps >= 6
        ? GpsSignalStatus.lost
        : secondsSinceGps >= 3
        ? GpsSignalStatus.weak
        : GpsSignalStatus.strong;
    final int failedFetches = _lastGpsUpdateAt == null
        ? 0
        : (secondsSinceGps ~/ 3);

    if (_hasAcquiredGpsOnce) {
      final bool transitioningFromStrong =
          state.gpsSignal == GpsSignalStatus.strong &&
          newSignal != GpsSignalStatus.strong;
      if (transitioningFromStrong) {
        _gpsDropInterruptions += 1;
      }
      if (newSignal != GpsSignalStatus.strong) {
        _gpsDropSeconds += 1;
      }

      // Dead reckoning: extrapolate distance when GPS is weak/lost
      if (newSignal != GpsSignalStatus.strong &&
          _lastKnownSpeedMps > 0.3 &&
          _deadReckoningElapsed < _maxDeadReckoningSeconds) {
        _deadReckoningElapsed += 1;
        final double extrapolated = _lastKnownSpeedMps * 1.0;
        _deadReckoningMeters += extrapolated;
        dist = state.distanceMeters + extrapolated;
      }
    }

    final double pace = type == ActivityType.cycle
        ? 0
        : LocationService.calculatePace(dist, _elapsedSeconds);

    state = state.copyWith(
      elapsed: Duration(seconds: _elapsedSeconds),
      distanceMeters: dist,
      currentPace: pace,
      currentSpeedKmh: _computeCurrentSpeed(),
      avgSpeedKmh: _computeAvgSpeed(dist),
      steps: _estimateSteps(dist),
      caloriesBurnt: LocationService.calculateCalories(type, dist, _weightKg),
      routePoints: List<LatLng>.from(_routePoints),
      gpsSignal: newSignal,
      consecutiveFailedLocationFetches: failedFetches,
      deadReckoningMeters: _deadReckoningMeters,
    );
  }

  double _computeCurrentSpeed() {
    if (_speedSamples.length < 2) return 0;
    final (DateTime, double) oldest = _speedSamples.first;
    final (DateTime, double) newest = _speedSamples.last;
    final int diffSec = newest.$1.difference(oldest.$1).inSeconds;
    if (diffSec <= 0) return 0;
    final double diffDist = newest.$2 - oldest.$2;
    return (diffDist / diffSec) * 3.6;
  }

  double _computeAvgSpeed(double totalDist) {
    if (_elapsedSeconds <= 0) return 0;
    return (totalDist / _elapsedSeconds) * 3.6;
  }

  void _trimSpeedSamples() {
    final DateTime cutoff = DateTime.now().subtract(
      const Duration(seconds: 10),
    );
    while (_speedSamples.isNotEmpty &&
        _speedSamples.first.$1.isBefore(cutoff)) {
      _speedSamples.removeFirst();
    }
  }

  static int _estimateSteps(double distanceMeters) =>
      (distanceMeters / 0.78).round().clamp(0, 200000);

  void pauseTracking() {
    if (state.status != ActivityTrackingStatus.active) return;
    _timer?.cancel();
    _locationSub?.pause();
    state = state.copyWith(status: ActivityTrackingStatus.paused);
    _fgService.updateNotification(text: 'Activity paused');
  }

  void resumeTracking() {
    if (state.status != ActivityTrackingStatus.paused || state.type == null)
      return;
    final ActivityType type = state.type!;
    _lastGpsUpdateAt = DateTime.now();
    _deadReckoningElapsed = 0;
    state = state.copyWith(
      status: ActivityTrackingStatus.active,
      gpsSignal: GpsSignalStatus.weak,
      consecutiveFailedLocationFetches: 0,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status != ActivityTrackingStatus.active) return;
      _elapsedSeconds += 1;
      _emitHud(type);
    });
    _locationSub?.resume();
    _fgService.updateNotification(text: 'GPS tracking is active');
  }

  void cancelTracking() {
    _timer?.cancel();
    _locationSub?.cancel();
    _locationSub = null;
    FlutterForegroundTask.removeTaskDataCallback(_onForegroundData);
    _routePoints.clear();
    _lastPoint = null;
    _startTime = null;
    _elapsedSeconds = 0;
    _lastGpsUpdateAt = null;
    _hasAcquiredGpsOnce = false;
    _gpsDropSeconds = 0;
    _gpsDropInterruptions = 0;
    _deadReckoningMeters = 0;
    _lastKnownSpeedMps = 0;
    _deadReckoningElapsed = 0;
    _speedSamples.clear();
    state = ActivityTrackingState.idle();
    _fgService.stop();
  }

  Future<Activity?> stopAndSave() async {
    final ActivityType? type = state.type;
    if (type == null || _startTime == null) return null;

    state = state.copyWith(status: ActivityTrackingStatus.saving);
    _timer?.cancel();
    await _locationSub?.cancel();
    _locationSub = null;
    FlutterForegroundTask.removeTaskDataCallback(_onForegroundData);
    await _fgService.stop();

    final AsyncValue<FitupUser?> auth = ref.read(authStateProvider);
    final FitupUser? user = auth.maybeWhen(
      data: (FitupUser? u) => u,
      orElse: () => null,
    );
    if (user == null) {
      state = ActivityTrackingState.idle();
      return null;
    }

    final DateTime end = DateTime.now();
    final int duration = _elapsedSeconds > 0
        ? _elapsedSeconds
        : end.difference(_startTime!).inSeconds;
    final double dist = state.distanceMeters;
    final double weight = _weightKg;
    final double avgSpeed = dist > 0 && duration > 0
        ? (dist / 1000) / (duration / 3600)
        : 0;

    final Activity activity = Activity(
      id: '${user.id}_${end.millisecondsSinceEpoch}',
      userId: user.id,
      type: type,
      startTime: _startTime!,
      endTime: end,
      distanceMeters: dist,
      durationSeconds: duration > 0 ? duration : 1,
      caloriesBurnt: LocationService.calculateCalories(type, dist, weight),
      routePoints: List<LatLng>.from(_routePoints),
      steps: type == ActivityType.cycle ? null : state.steps,
      avgPace: type == ActivityType.cycle
          ? null
          : LocationService.calculatePace(dist, duration > 0 ? duration : 1),
      avgSpeed: avgSpeed > 0 ? avgSpeed : null,
      gpsDropSeconds: _gpsDropSeconds,
      gpsDropInterruptions: _gpsDropInterruptions,
      deadReckoningMeters: _deadReckoningMeters,
    );

    final int fitcoins = FitcoinAwardService.calculateActivityReward(activity);

    final Either<Failure, Activity> result = await ref
        .read(activityRepositoryProvider)
        .saveActivity(activity);

    _resetInternalState();

    return result.fold((_) => null, (Activity a) {
      state = state.copyWith(fitcoinsEarned: fitcoins);
      return a;
    });
  }

  void _resetInternalState() {
    _routePoints.clear();
    _startTime = null;
    _lastPoint = null;
    _elapsedSeconds = 0;
    _lastGpsUpdateAt = null;
    _hasAcquiredGpsOnce = false;
    _gpsDropSeconds = 0;
    _gpsDropInterruptions = 0;
    _deadReckoningMeters = 0;
    _lastKnownSpeedMps = 0;
    _deadReckoningElapsed = 0;
    _speedSamples.clear();
    state = ActivityTrackingState.idle();
  }

  void _updateNotification() {
    final double km = state.distanceMeters / 1000;
    final int mins = _elapsedSeconds ~/ 60;
    _fgService.updateNotification(
      text: '${km.toStringAsFixed(2)} km • ${mins}m elapsed',
    );
  }
}

/// Payload for the post-save summary screen ([go_router] [extra] can be lost).
class ActivitySessionResult {
  const ActivitySessionResult({
    required this.activity,
    this.fitcoinsEarned = 0,
  });

  final Activity activity;
  final int fitcoinsEarned;
}

/// Holds the most recently finished GPS session for summary navigation.
final NotifierProvider<LastActivitySessionResultNotifier, ActivitySessionResult?>
lastActivitySessionResultProvider =
    NotifierProvider<LastActivitySessionResultNotifier, ActivitySessionResult?>(
      LastActivitySessionResultNotifier.new,
    );

class LastActivitySessionResultNotifier extends Notifier<ActivitySessionResult?> {
  @override
  ActivitySessionResult? build() => null;

  void publish(Activity activity, {int fitcoinsEarned = 0}) {
    state = ActivitySessionResult(
      activity: activity,
      fitcoinsEarned: fitcoinsEarned,
    );
  }

  void clear() => state = null;
}

/// Activity chosen from the recent list (survives shell [go_router] [extra] loss).
final NotifierProvider<SelectedActivityDetailNotifier, Activity?>
selectedActivityDetailProvider =
    NotifierProvider<SelectedActivityDetailNotifier, Activity?>(
      SelectedActivityDetailNotifier.new,
    );

class SelectedActivityDetailNotifier extends Notifier<Activity?> {
  @override
  Activity? build() => null;

  void select(Activity activity) => state = activity;

  void clear() => state = null;
}
