import 'dart:async';

import 'package:web/web.dart' as web;

import '../core/constants/env_config.dart';

/// Injects the Google Maps JavaScript API using the build-time API key.
Future<void> ensureGoogleMapsWebScript() async {
  if (web.document.getElementById('google-maps-script') != null) {
    return;
  }
  final Completer<void> completer = Completer<void>();
  final web.HTMLScriptElement script =
      web.document.createElement('script') as web.HTMLScriptElement;
  script.id = 'google-maps-script';
  script.async = true;
  script.src =
      'https://maps.googleapis.com/maps/api/js?key=${EnvConfig.googleMapsApiKey}';
  script.onLoad.listen((_) {
    if (!completer.isCompleted) {
      completer.complete();
    }
  });
  script.onError.listen((_) {
    if (!completer.isCompleted) {
      completer.completeError(
        StateError('Failed to load Google Maps JavaScript API'),
      );
    }
  });
  web.document.head!.appendChild(script);
  return completer.future;
}
