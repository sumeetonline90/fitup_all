import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/constants/google_map_dark_style.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../services/location_service.dart';
import '../../../../services/sos_service.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../domain/entities/activity.dart';
import '../providers/activity_providers.dart';

/// Live GPS HUD — Stitch `live_activity_tracker` wired to [activityTrackerProvider].
class LiveTrackingScreen extends ConsumerStatefulWidget {
  const LiveTrackingScreen({super.key, required this.initialType});

  final ActivityType initialType;

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  GoogleMapController? _mapController;
  DateTime? _lastCameraFollowAt;
  LatLng? _lastCameraAnchor;
  int? _countdownSeconds;
  Timer? _countdownTimer;
  bool _sessionFinished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 3-second countdown before starting tracking so the user can prepare.
      setState(() {
        _countdownSeconds = 3;
      });
      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        final int current = _countdownSeconds ?? 0;
        if (current <= 1) {
          t.cancel();
          setState(() {
            _countdownSeconds = null;
          });
          ref
              .read(activityTrackerProvider.notifier)
              .startTracking(widget.initialType);
        } else {
          setState(() {
            _countdownSeconds = current - 1;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    if (!_sessionFinished) {
      ref.read(activityTrackerProvider.notifier).cancelTracking();
    }
    super.dispose();
  }

  void _maybeFollowCamera(LatLng last) {
    final DateTime now = DateTime.now();
    double movedM = 0;
    if (_lastCameraAnchor != null) {
      movedM = LocationService.calculateDistance(_lastCameraAnchor!, last);
    }
    final bool timeOk =
        _lastCameraFollowAt == null ||
        now.difference(_lastCameraFollowAt!) >= const Duration(seconds: 10);
    final bool distOk = movedM >= 50.0;
    if (_lastCameraAnchor == null || timeOk || distOk) {
      _lastCameraFollowAt = now;
      _lastCameraAnchor = last;
      _mapController?.animateCamera(CameraUpdate.newLatLng(last));
    }
  }

  String _formatDuration(Duration d) {
    final int totalSeconds = d.inSeconds;
    final int h = totalSeconds ~/ 3600;
    final int m = (totalSeconds % 3600) ~/ 60;
    final int s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  String _formatPace(double minPerKm) {
    if (minPerKm <= 0) {
      return '—';
    }
    final int m = minPerKm.floor();
    final int sec = ((minPerKm - m) * 60).round().clamp(0, 59);
    return '$m:${sec.toString().padLeft(2, '0')} /km';
  }

  bool get _showSteps => widget.initialType != ActivityType.cycle;

  Future<void> _confirmStop() async {
    final bool? ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text('Stop activity?', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Your session will be saved to your journal.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.tertiary,
                        ),
                        child: const Text('Stop'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (ok == true && mounted) {
      final Activity? saved = await ref
          .read(activityTrackerProvider.notifier)
          .stopAndSave();
      if (!mounted) {
        return;
      }
      if (saved != null) {
        final int fitcoins = ref.read(activityTrackerProvider).fitcoinsEarned;
        ref
            .read(lastActivitySessionResultProvider.notifier)
            .publish(saved, fitcoinsEarned: fitcoins);
        ref.invalidate(recentTrackedActivitiesProvider);
        _sessionFinished = true;
        context.go(
          '/activity/complete',
          extra: <String, dynamic>{'activity': saved, 'fitcoins': fitcoins},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save activity. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _confirmBack() async {
    final bool? leave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainer,
          title: Text('Leave tracking?', style: AppTextStyles.headlineMedium),
          content: Text(
            'Your session will not be saved.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Leave',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
    if (leave == true && mounted) {
      ref.read(activityTrackerProvider.notifier).cancelTracking();
      context.pop();
    }
  }

  void _leavePermissionDenied() {
    ref.read(activityTrackerProvider.notifier).cancelTracking();
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ActivityTrackingStatus status = ref.watch(
      activityTrackerProvider.select((ActivityTrackingState s) => s.status),
    );

    ref.listen<List<LatLng>>(
      activityTrackerProvider.select(
        (ActivityTrackingState s) => s.routePoints,
      ),
      (List<LatLng>? previous, List<LatLng> next) {
        if (next.isEmpty) {
          return;
        }
        _maybeFollowCamera(next.last);
      },
    );

    if (status == ActivityTrackingStatus.locationPermissionDenied) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: 'Close',
                    onPressed: _leavePermissionDenied,
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Location permission required',
                  style: AppTextStyles.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Location permission is required for tracking. '
                  'Tap below to open Settings and enable location, then try again.',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                NeonButton(
                  label: 'Open Settings',
                  icon: Icons.settings_rounded,
                  onPressed: () async {
                    await Geolocator.openAppSettings();
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref
                      .read(activityTrackerProvider.notifier)
                      .retryAfterPermission(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: BorderSide(
                      color: AppColors.secondary.withValues(alpha: 0.35),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    'Try again',
                    style: AppTextStyles.button.copyWith(
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

    final bool showLive =
        status == ActivityTrackingStatus.active ||
        status == ActivityTrackingStatus.paused;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (kIsWeb)
            ColoredBox(
              color: AppColors.surfaceContainerHigh,
              child: Center(
                child: Text(
                  'Map preview\nConfigure Google Maps for web',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            )
          else
            _LiveMapLayer(
              onControllerReady: (GoogleMapController c) {
                _mapController = c;
              },
            ),
          if (_countdownSeconds != null)
            Positioned.fill(
              child: Container(
                color: AppColors.background.withValues(alpha: 0.7),
                child: Center(
                  child: GlassCard(
                    borderRadius: 20,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text('Starting in', style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 8),
                        Text(
                          '${_countdownSeconds ?? 0}',
                          style: AppTextStyles.headlineMedium.copyWith(
                            fontSize: 44,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.sizeOf(context).height * 0.15,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: GlassCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        tooltip: 'Close',
                        onPressed: _confirmBack,
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.onSurface,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _TypeLabel(type: widget.initialType)),
                      if (showLive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              _LiveDot(),
                              const SizedBox(width: 6),
                              Text(
                                'LIVE',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top:
                MediaQuery.paddingOf(context).top +
                MediaQuery.sizeOf(context).height * 0.15,
            right: 16,
            child: GlassCard(
              borderRadius: 999,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              glowColor: AppColors.tertiary,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.tertiary,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '— bpm',
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontSize: 14,
                      color: AppColors.tertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: DraggableScrollableSheet(
              initialChildSize: 0.40,
              minChildSize: 0.28,
              maxChildSize: 0.85,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                    return _LiveHudSheet(
                      scrollController: scrollController,
                      initialType: widget.initialType,
                      showSteps: _showSteps,
                      formatDuration: _formatDuration,
                      formatPace: _formatPace,
                      formatSteps: _formatSteps,
                      onConfirmStop: _confirmStop,
                    );
                  },
            ),
          ),
          if (!kIsWeb)
            Positioned(
              left: 16,
              bottom: MediaQuery.sizeOf(context).height * 0.42,
              child: Tooltip(
                message: 'Long-press for emergency SOS (SMS + 112)',
                child: Material(
                  color: AppColors.error.withValues(alpha: 0.92),
                  shape: const CircleBorder(),
                  elevation: 6,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onLongPress: () async {
                      final UserProfile? profile = ref
                          .read(userProfileProvider)
                          .maybeWhen(
                            data: (UserProfile p) => p,
                            orElse: () => null,
                          );
                      if (profile == null || !context.mounted) {
                        return;
                      }
                      final result = await getIt<SosService>().launchSos(
                        profile,
                      );
                      if (!context.mounted) {
                        return;
                      }
                      result.fold(
                        (Failure f) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('$f')));
                        },
                        (_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('SOS actions triggered'),
                            ),
                          );
                        },
                      );
                    },
                    child: const SizedBox(
                      width: 56,
                      height: 56,
                      child: Icon(Icons.sos, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatSteps(int n) {
    final String s = n.toString();
    final StringBuffer buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final int fromEnd = s.length - i;
      if (i > 0 && fromEnd % 3 == 0) {
        buf.write(',');
      }
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

/// Map + overlays; watches only [ActivityTrackingState.routePoints].
class _LiveMapLayer extends ConsumerStatefulWidget {
  const _LiveMapLayer({required this.onControllerReady});

  final void Function(GoogleMapController) onControllerReady;

  @override
  ConsumerState<_LiveMapLayer> createState() => _LiveMapLayerState();
}

class _LiveMapLayerState extends ConsumerState<_LiveMapLayer> {
  bool _mapError = false;

  @override
  Widget build(BuildContext context) {
    final List<LatLng> points = ref.watch(
      activityTrackerProvider.select(
        (ActivityTrackingState s) => s.routePoints,
      ),
    );

    if (points.isEmpty) {
      return ColoredBox(
        color: AppColors.surfaceContainerHigh,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const CircularProgressIndicator(color: AppColors.secondary),
              const SizedBox(height: 16),
              Text('Acquiring GPS…', style: AppTextStyles.bodyLarge),
            ],
          ),
        ),
      );
    }

    if (_mapError) {
      return ColoredBox(
        color: AppColors.surfaceContainerHigh,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.map_outlined,
                size: 48,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text('Map unavailable', style: AppTextStyles.bodyLarge),
              const SizedBox(height: 4),
              Text(
                'Tracking continues in background',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final Set<Polyline> polylines = <Polyline>{
      if (points.length >= 2)
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: AppColors.secondary,
          width: 4,
        ),
    };

    final LatLng markerPos = points.last;
    final Set<Marker> markers = <Marker>{
      Marker(
        markerId: const MarkerId('user'),
        position: markerPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
      ),
    };

    final CameraPosition initialCam = CameraPosition(
      target: markerPos,
      zoom: 14.8,
    );

    return _MapErrorBoundary(
      onError: () {
        if (mounted) {
          setState(() => _mapError = true);
        }
      },
      child: GoogleMap(
        style: kGoogleMapDarkStyleJson,
        initialCameraPosition: initialCam,
        onMapCreated: (GoogleMapController c) {
          widget.onControllerReady(c);
          c.animateCamera(CameraUpdate.newLatLng(markerPos));
        },
        polylines: polylines,
        markers: markers,
        myLocationEnabled: !kIsWeb,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: false,
      ),
    );
  }
}

class _MapErrorBoundary extends StatefulWidget {
  const _MapErrorBoundary({required this.child, required this.onError});

  final Widget child;
  final VoidCallback onError;

  @override
  State<_MapErrorBoundary> createState() => _MapErrorBoundaryState();
}

class _MapErrorBoundaryState extends State<_MapErrorBoundary> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const SizedBox.shrink();
    }
    return widget.child;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (!_hasError) {
        _hasError = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onError();
        });
      }
      return const SizedBox.shrink();
    };
  }
}

/// Bottom sheet metrics; watches HUD fields only (not every route tick).
class _LiveHudSheet extends ConsumerWidget {
  const _LiveHudSheet({
    required this.scrollController,
    required this.initialType,
    required this.showSteps,
    required this.formatDuration,
    required this.formatPace,
    required this.formatSteps,
    required this.onConfirmStop,
  });

  final ScrollController scrollController;
  final ActivityType initialType;
  final bool showSteps;
  final String Function(Duration) formatDuration;
  final String Function(double) formatPace;
  final String Function(int) formatSteps;
  final Future<void> Function() onConfirmStop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (
      Duration elapsed,
      double distanceMeters,
      double caloriesBurnt,
      int steps,
      double currentPace,
      double currentSpeedKmh,
      double avgSpeedKmh,
      ActivityTrackingStatus status,
      GpsSignalStatus gpsSignal,
    ) = ref.watch(
      activityTrackerProvider.select(
        (ActivityTrackingState s) => (
          s.elapsed,
          s.distanceMeters,
          s.caloriesBurnt,
          s.steps,
          s.currentPace,
          s.currentSpeedKmh,
          s.avgSpeedKmh,
          s.status,
          s.gpsSignal,
        ),
      ),
    );

    final bool paused = status == ActivityTrackingStatus.paused;
    final double km = distanceMeters / 1000;
    final String paceLabel = initialType == ActivityType.cycle
        ? '${currentSpeedKmh.toStringAsFixed(1)} km/h'
        : formatPace(currentPace);

    return GlassCard(
      borderRadius: 24,
      padding: EdgeInsets.zero,
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: <Widget>[
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            formatDuration(elapsed),
            textAlign: TextAlign.center,
            style: AppTextStyles.displayLarge.copyWith(
              fontSize: 48,
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (gpsSignal != GpsSignalStatus.strong) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    (gpsSignal == GpsSignalStatus.lost
                            ? AppColors.error
                            : AppColors.warningAmber)
                        .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color:
                      (gpsSignal == GpsSignalStatus.lost
                              ? AppColors.error
                              : AppColors.warningAmber)
                          .withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.gps_off,
                    size: 14,
                    color: gpsSignal == GpsSignalStatus.lost
                        ? AppColors.error
                        : AppColors.warningAmber,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    gpsSignal == GpsSignalStatus.lost
                        ? 'GPS lost — estimating'
                        : 'GPS weak',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: gpsSignal == GpsSignalStatus.lost
                          ? AppColors.error
                          : AppColors.warningAmber,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Row 1: Distance & Pace/Speed
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricColumn(
                  label: 'Distance',
                  value: '${km.toStringAsFixed(2)} km',
                ),
              ),
              Expanded(
                child: _MetricColumn(
                  label: initialType == ActivityType.cycle ? 'Speed' : 'Pace',
                  value: paceLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Avg Speed & Calories
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricColumn(
                  label: 'Avg Speed',
                  value: avgSpeedKmh > 0
                      ? '${avgSpeedKmh.toStringAsFixed(1)} km/h'
                      : '—',
                ),
              ),
              Expanded(
                child: _MetricColumn(
                  label: 'Calories',
                  value: caloriesBurnt.round().toString(),
                ),
              ),
            ],
          ),
          if (showSteps) ...<Widget>[
            const SizedBox(height: 12),
            // Row 3: Steps (centered)
            _MetricColumn(label: 'Steps', value: formatSteps(steps)),
          ],
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: _CircleAction(
                  tooltip: paused ? 'Resume' : 'Pause',
                  color: AppColors.secondary,
                  icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  onPressed: () {
                    if (paused) {
                      ref
                          .read(activityTrackerProvider.notifier)
                          .resumeTracking();
                    } else {
                      ref
                          .read(activityTrackerProvider.notifier)
                          .pauseTracking();
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _CircleAction(
                  tooltip: 'Stop',
                  color: AppColors.tertiary,
                  icon: Icons.stop_rounded,
                  onPressed: onConfirmStop,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeLabel extends StatelessWidget {
  const _TypeLabel({required this.type});

  final ActivityType type;

  @override
  Widget build(BuildContext context) {
    return Text(
      type.label,
      style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
    );
  }
}

class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(
              AppColors.error,
              AppColors.error.withValues(alpha: 0.25),
              _c.value,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.5 * _c.value),
                blurRadius: 8,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(label, style: AppTextStyles.labelSmall),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMedium.copyWith(
            fontSize: 16,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.tooltip,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.6)),
              color: color.withValues(alpha: 0.12),
              boxShadow: <BoxShadow>[
                BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 16),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 32),
          ),
        ),
      ),
    );
  }
}
