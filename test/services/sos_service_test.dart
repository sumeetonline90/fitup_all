import 'package:fitup/core/error/failures.dart';
import 'package:fitup/features/profile/domain/entities/emergency_contact.dart';
import 'package:fitup/features/profile/domain/entities/user_profile.dart';
import 'package:fitup/services/sos_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SosService', () {
    final SosService sos = SosService();

    test('returns SosFailure.noContactConfigured when no emergency contacts',
        () async {
      const UserProfile p = UserProfile(
        userId: 'u1',
        email: 'a@b.com',
        emergencyContacts: <EmergencyContact>[],
      );
      final result = await sos.launchSos(p);
      expect(result.isLeft(), isTrue);
      result.fold(
        (Failure f) => expect(f, isA<SosFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('returns SosFailure.invalidPhoneNumber when contact phone is empty',
        () async {
      const UserProfile p = UserProfile(
        userId: 'u1',
        email: 'a@b.com',
        emergencyContacts: <EmergencyContact>[
          EmergencyContact(name: 'x', phone: '  ', relationship: 'friend'),
        ],
      );
      final result = await sos.launchSos(p);
      expect(result.isLeft(), isTrue);
      result.fold(
        (Failure f) => expect(f, isA<SosFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('normalizeToE164ForTest strips prefixes and returns E.164', () {
      expect(
        SosService.normalizeToE164ForTest('+91 98765 43210'),
        '+919876543210',
      );
      expect(
        SosService.normalizeToE164ForTest('09876543210'),
        '+919876543210',
      );
      expect(
        SosService.normalizeToE164ForTest('9876543210'),
        '+919876543210',
      );
    });

    test('normalizeToE164ForTest returns null for too-short inputs', () {
      expect(SosService.normalizeToE164ForTest('12345'), isNull);
    });
  });
}
