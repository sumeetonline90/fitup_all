import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/google_map_dark_style.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/entities/fitup_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../community/presentation/providers/community_providers.dart';
import '../../../fitcoins/domain/entities/fitcoin_wallet.dart';
import '../../../../services/google_maps_web_loader.dart';
import '../../../../shared/widgets/fitup_logo.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/activity_type.dart';
import 'activity_session_metrics.dart';

/// Top row: Fitup branding + Fitcoin balance (matches module header style).
class ActivitySummaryTopRow extends ConsumerWidget {
  const ActivitySummaryTopRow({super.key, this.leading});

  /// e.g. back button on detail screens.
  final Widget? leading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FitcoinWallet> fitcoinWallet =
        ref.watch(fitcoinWalletStreamProvider);
    final NumberFormat fcFmt = NumberFormat('#,###');
    final String balance = fitcoinWallet.maybeWhen(
      data: (FitcoinWallet w) => fcFmt.format(w.balance),
      orElse: () => '—',
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (leading != null) leading!,
          const FitupLogo(size: 34),
          const SizedBox(width: 10),
          Text(
            'Fitup',
            style: AppTextStyles.headlineLarge.copyWith(fontSize: 24),
          ),
          if (!kIsWeb) ...<Widget>[
            const Spacer(),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Image.asset(
                        'assets/images/fitcoins.png',
                        width: 20,
                        height: 20,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.monetization_on_outlined,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$balance FC',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "SESSION COMPLETE" badge + motivational headline.
class ActivitySessionHeadline extends StatelessWidget {
  const ActivitySessionHeadline({
    super.key,
    required this.badge,
    required this.headline,
  });

  final String badge;
  final String headline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GlassCard(
        borderRadius: 28,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              badge,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.onSurfaceVariant,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              headline,
              style: AppTextStyles.headlineLarge.copyWith(
                fontSize: 22,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Map + LOCATION strip (mock-style).
class ActivitySessionMapCard extends StatefulWidget {
  const ActivitySessionMapCard({
    super.key,
    required this.routePoints,
    required this.activityType,
    required this.locationName,
    this.onMapCreated,
    this.height = 200,
  });

  final List<LatLng> routePoints;
  final ActivityType activityType;
  final String locationName;
  final void Function(GoogleMapController)? onMapCreated;
  final double height;

  @override
  State<ActivitySessionMapCard> createState() => _ActivitySessionMapCardState();
}

class _ActivitySessionMapCardState extends State<ActivitySessionMapCard> {
  bool _webMapsReady = !kIsWeb;
  bool _webMapsFailed = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb && widget.routePoints.isNotEmpty) {
      ensureGoogleMapsWebScript().then((_) {
        if (mounted) {
          setState(() => _webMapsReady = true);
        }
      }).catchError((_) {
        if (mounted) {
          setState(() => _webMapsFailed = true);
        }
      });
    }
  }

  Future<void> _fitBounds(GoogleMapController c) async {
    final List<LatLng> pts = widget.routePoints;
    if (pts.length >= 2) {
      final double minLat =
          pts.map((LatLng e) => e.latitude).reduce(math.min);
      final double maxLat =
          pts.map((LatLng e) => e.latitude).reduce(math.max);
      final double minLng =
          pts.map((LatLng e) => e.longitude).reduce(math.min);
      final double maxLng =
          pts.map((LatLng e) => e.longitude).reduce(math.max);
      await c.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          48,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<LatLng> pts = widget.routePoints;
    final Set<Polyline> lines = <Polyline>{
      if (pts.length >= 2)
        Polyline(
          polylineId: const PolylineId('route'),
          points: pts,
          color: AppColors.secondary,
          width: 4,
        ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              height: widget.height,
              child: pts.isEmpty
                  ? _MapPlaceholder(empty: true)
                  : kIsWeb && !_webMapsReady
                  ? _MapPlaceholder(
                      empty: false,
                      loading: !_webMapsFailed,
                      failed: _webMapsFailed,
                    )
                  : GoogleMap(
                      style: kGoogleMapDarkStyleJson,
                      initialCameraPosition: CameraPosition(
                        target: pts.first,
                        zoom: 14,
                      ),
                      onMapCreated: (GoogleMapController c) async {
                        await _fitBounds(c);
                        widget.onMapCreated?.call(c);
                      },
                      polylines: lines,
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      mapToolbarEnabled: false,
                      compassEnabled: false,
                    ),
            ),
            ColoredBox(
              color: AppColors.surfaceContainer.withValues(alpha: 0.95),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.secondary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'LOCATION',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.locationName,
                            style: AppTextStyles.headlineMedium.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bento metric grid — same layout for saved sessions and live HUD.
class ActivitySessionBentoGrid extends StatelessWidget {
  const ActivitySessionBentoGrid({
    super.key,
    required this.type,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.caloriesBurnt,
    this.steps,
    this.avgPaceMinPerKm,
    this.avgSpeedKmh,
    this.currentPaceMinPerKm,
    this.currentSpeedKmh,
    this.isLive = false,
    this.hideDurationTile = false,
  });

  final ActivityType type;
  final int durationSeconds;
  final double distanceMeters;
  final double caloriesBurnt;
  final int? steps;
  final double? avgPaceMinPerKm;
  final double? avgSpeedKmh;
  final double? currentPaceMinPerKm;
  final double? currentSpeedKmh;
  final bool isLive;

  /// When true, omit the duration row (e.g. live HUD shows a large timer above).
  final bool hideDurationTile;

  @override
  Widget build(BuildContext context) {
    final String durationStr =
        ActivitySessionMetrics.durationHms(durationSeconds);
    final String distStr =
        ActivitySessionMetrics.distanceLabel(type, distanceMeters);
    final String calStr = '${caloriesBurnt.round()} kcal';

    final String primaryValue = _primaryValue();

    final String primaryLabel = ActivitySessionMetrics.primaryMetricLabel(type);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _BentoTile(
                  icon: Icons.speed_rounded,
                  iconColor: AppColors.secondary,
                  label: primaryLabel,
                  value: primaryValue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BentoTile(
                  icon: Icons.route_rounded,
                  iconColor: const Color(0xFFBEEA63),
                  label: ActivitySessionMetrics.distanceColumnLabel(type),
                  value: distStr,
                ),
              ),
            ],
          ),
          if (!hideDurationTile) ...<Widget>[
            const SizedBox(height: 12),
            _BentoTile(
              icon: Icons.timer_outlined,
              iconColor: AppColors.tertiary,
              label: 'DURATION',
              value: durationStr,
              wide: true,
            ),
          ],
          if (type == ActivityType.run || type == ActivityType.walk) ...<Widget>[
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _BentoTile(
                    icon: Icons.directions_walk_rounded,
                    iconColor: const Color(0xFFE8D44D),
                    label: 'STEPS',
                    value: steps != null ? _formatSteps(steps!) : '—',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BentoTile(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: AppColors.tertiary,
                    label: 'CALORIES',
                    value: calStr,
                  ),
                ),
              ],
            ),
          ],
          if (type == ActivityType.cycle || type == ActivityType.swim) ...<Widget>[
            const SizedBox(height: 12),
            _BentoTile(
              icon: Icons.local_fire_department_rounded,
              iconColor: AppColors.tertiary,
              label: 'CALORIES',
              value: calStr,
              wide: true,
            ),
          ],
        ],
      ),
    );
  }

  String _primaryValue() {
    switch (type) {
      case ActivityType.run:
      case ActivityType.walk:
        final double pace = isLive
            ? (currentPaceMinPerKm ?? 0)
            : (avgPaceMinPerKm ??
                (distanceMeters > 1
                    ? (durationSeconds / 60.0) / (distanceMeters / 1000.0)
                    : 0));
        return ActivitySessionMetrics.formatPaceMinPerKm(pace);
      case ActivityType.cycle:
        final double? spd = isLive ? currentSpeedKmh : avgSpeedKmh;
        if (spd != null && spd > 0) {
          return '${spd.toStringAsFixed(1)} km/h';
        }
        return '—';
      case ActivityType.swim:
        return ActivitySessionMetrics.formatPaceMinPer100m(
          ActivitySessionMetrics.swimPaceMinPer100m(
            distanceMeters,
            durationSeconds,
          ),
        );
    }
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

class _BentoTile extends StatelessWidget {
  const _BentoTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.wide = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final Widget inner = GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment:
            wide ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment:
                wide ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: <Widget>[
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.6,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            textAlign: wide ? TextAlign.center : TextAlign.start,
            style: AppTextStyles.displayLarge.copyWith(
              fontSize: wide ? 26 : 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
    return inner;
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({
    required this.empty,
    this.loading = false,
    this.failed = false,
  });

  final bool empty;
  final bool loading;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceContainerHigh,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (loading)
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.map_outlined,
                size: 40,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            const SizedBox(height: 8),
            Text(
              empty
                  ? 'No route preview'
                  : failed
                  ? 'Map could not load'
                  : 'Loading map…',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Build headline from auth user + activity type.
String activitySummaryFirstName(WidgetRef ref) {
  final FitupUser? user = ref.watch(authStateProvider).maybeWhen(
        data: (FitupUser? u) => u,
        orElse: () => null,
      );
  if (user?.displayName != null && user!.displayName!.trim().isNotEmpty) {
    return user.displayName!.split(' ').first;
  }
  if (user?.email.isNotEmpty ?? false) {
    return user!.email.split('@').first;
  }
  return 'there';
}
