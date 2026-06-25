import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../core/error/failures.dart';
import '../core/utils/url_launcher_util.dart';
import '../features/profile/domain/entities/user_profile.dart';
import 'logger_service.dart';

/// Client-only emergency SOS via SMS + optional emergency dial (Phase 9).
class SosService {
  /// Normalizes an input phone number to E.164 format (e.g. `+919876543210`).
  ///
  /// Strips all non-digit characters except a leading '+'. Returns `null` if
  /// the result is outside ITU E.164 limits (7..15 digits, excluding '+').
  static String? _normalizeToE164(
    String raw, {
    String defaultCountryCode = '91',
  }) {
    final String trimmedLeft = raw.trimLeft();
    final bool hasPlus = trimmedLeft.startsWith('+');
    final String digits = raw.replaceAll(RegExp(r'[^\d]'), '');

    late final String normalized;
    if (hasPlus) {
      normalized = '+$digits';
    } else if (digits.startsWith('0')) {
      // Trunk prefix — replace with country code.
      normalized = '+$defaultCountryCode${digits.substring(1)}';
    } else if (digits.length == 10) {
      // 10-digit local number — assume default country.
      normalized = '+$defaultCountryCode$digits';
    } else {
      // Already has country code without '+' (e.g. 9198...).
      normalized = '+$digits';
    }

    final int digitCount = normalized.replaceAll('+', '').length;
    if (digitCount < 7 || digitCount > 15) return null;
    return normalized;
  }

  @visibleForTesting
  static String? normalizeToE164ForTest(String raw,
      {String defaultCountryCode = '91'}) {
    return _normalizeToE164(raw, defaultCountryCode: defaultCountryCode);
  }

  /// Sends SMS to first emergency contact with maps link; then offers `tel:112` (India).
  Future<Either<Failure, Unit>> launchSos(UserProfile profile) async {
    if (kIsWeb) {
      return const Left<Failure, Unit>(
        PermissionFailure('SOS is not available on web'),
      );
    }
    if (profile.emergencyContacts.isEmpty) {
      return const Left<Failure, Unit>(SosFailure.noContactConfigured());
    }
    final String rawPhone = profile.emergencyContacts.first.phone.trim();
    if (rawPhone.isEmpty) {
      return Left<Failure, Unit>(SosFailure.invalidPhoneNumber(rawPhone));
    }

    final String? e164 =
        _normalizeToE164(rawPhone, defaultCountryCode: '91');
    if (e164 == null) {
      return Left<Failure, Unit>(SosFailure.invalidPhoneNumber(rawPhone));
    }

    try {
      final LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
      } catch (_) {
        pos = null;
      }
      final String mapsLink = pos != null
          ? 'https://maps.google.com/?q=${pos.latitude},${pos.longitude}'
          : 'Location unavailable';
      final String body =
          Uri.encodeComponent('Fitup SOS — $mapsLink');
      final Uri sms = Uri.parse('sms:$e164?body=$body');

      final Either<Failure, Unit> smsResult =
          await UrlLauncherUtil.launchTelOrSms(sms);
      if (smsResult.isLeft()) {
        return const Left<Failure, Unit>(SosFailure.launchFailed());
      }

      final Uri tel = Uri.parse('tel:112');
      final Either<Failure, Unit> telResult =
          await UrlLauncherUtil.launchTelOrSms(tel);
      if (telResult.isLeft()) {
        return const Left<Failure, Unit>(SosFailure.launchFailed());
      }

      return const Right<Failure, Unit>(unit);
    } catch (e, st) {
      LoggerService.e('SosService.launchSos', e, st);
      return const Left<Failure, Unit>(SosFailure.launchFailed());
    }
  }
}
