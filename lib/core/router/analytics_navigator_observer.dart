import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../services/analytics_service.dart';

/// Logs screen views via [AnalyticsService.logScreen] on stack changes.
class FitupAnalyticsNavigatorObserver extends NavigatorObserver {
  FitupAnalyticsNavigatorObserver(this._analytics);

  final AnalyticsService _analytics;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _logRoute(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      _logRoute(previousRoute);
    }
  }

  void _logRoute(Route<dynamic> route) {
    if (route is! PageRoute) {
      return;
    }
    final String? name = route.settings.name;
    if (name == null || name.isEmpty) {
      return;
    }
    unawaited(_analytics.logScreen(name));
  }
}
