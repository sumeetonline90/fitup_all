import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LabScanScreen does not reference aiServiceProvider or AiService directly', () {
    final File f = File(
      'lib/features/health/presentation/screens/lab_scan_screen.dart',
    );
    expect(f.existsSync(), isTrue);
    final String s = f.readAsStringSync();
    expect(s.contains('aiServiceProvider'), isFalse);
    expect(s.contains('AiService'), isFalse);
  });
}
