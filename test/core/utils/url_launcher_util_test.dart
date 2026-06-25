import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitup/core/utils/url_launcher_util.dart';
import 'package:fitup/core/error/failures.dart';

void main() {
  group('UrlLauncherUtil', () {
    test('rejects non-https URL schemes', () async {
      final Either<Failure, Unit> res = await UrlLauncherUtil.launch(
        'http://example.com',
      );
      expect(res.isLeft(), isTrue);
      res.fold((Failure f) => expect(f, isA<UrlFailure>()), (_) {});
    });

    test('rejects javascript: URLs', () async {
      final Either<Failure, Unit> res = await UrlLauncherUtil.launch(
        'javascript:alert(1)',
      );
      expect(res.isLeft(), isTrue);
      res.fold((Failure f) => expect(f, isA<UrlFailure>()), (_) {});
    });

    test('rejects data: URLs', () async {
      final Either<Failure, Unit> res = await UrlLauncherUtil.launch(
        'data:text/html,<h1>nope</h1>',
      );
      expect(res.isLeft(), isTrue);
      res.fold((Failure f) => expect(f, isA<UrlFailure>()), (_) {});
    });

    test('rejects unparseable URLs', () async {
      final Either<Failure, Unit> res = await UrlLauncherUtil.launch(
        'not a url',
      );
      expect(res.isLeft(), isTrue);
      res.fold((Failure f) => expect(f, isA<UrlFailure>()), (_) {});
    });

    test('launchTelOrSms rejects non-tel/sms URIs', () async {
      final Either<Failure, Unit> res = await UrlLauncherUtil.launchTelOrSms(
        Uri.parse('mailto:test@example.com'),
      );
      expect(res.isLeft(), isTrue);
      res.fold((Failure f) => expect(f, isA<UrlFailure>()), (_) {});
    });
  });
}

