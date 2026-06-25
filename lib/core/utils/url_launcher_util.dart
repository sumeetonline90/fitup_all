import 'package:dartz/dartz.dart';
import 'package:url_launcher/url_launcher.dart';

import '../error/failures.dart';

/// Central URL launcher with safety checks.
///
/// - `launch` is HTTPS-only to prevent `javascript:` / `data:` style URIs.
/// - `launchTelOrSms` allows only `tel:` and `sms:` (used by SOS).
class UrlLauncherUtil {
  const UrlLauncherUtil._();

  static Future<Either<Failure, Unit>> launch(String rawUrl) async {
    final Uri? uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) {
      return Left(UrlFailure('Invalid URL: $rawUrl'));
    }
    if (uri.scheme != 'https') {
      return Left(
        UrlFailure('Only https:// URLs are permitted. Got: ${uri.scheme}'),
      );
    }

    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) return Left(UrlFailure('Could not open URL'));
      return const Right(unit);
    } catch (_) {
      return Left(const UrlFailure('URL launch error'));
    }
  }

  static Future<Either<Failure, Unit>> launchTelOrSms(Uri uri) async {
    if (uri.scheme != 'tel' && uri.scheme != 'sms') {
      return Left(const UrlFailure('Only tel: and sms: allowed here'));
    }

    try {
      final bool launched = await launchUrl(uri);
      if (!launched) return Left(const UrlFailure('Could not open dialler'));
      return const Right(unit);
    } catch (_) {
      return Left(const UrlFailure('Launch error'));
    }
  }
}

