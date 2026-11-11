import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/studio_core.dart';

void main() {
  group('RunTarget', () {
    // Verifies: FR-HST-002
    test('the design host is the test device of the SDK', () {
      const target = RunTarget.designHost();

      expect(target.deviceId, 'flutter-tester');
      expect(target.toolArguments, ['--show-test-device']);
    });

    // Verifies: FR-RUN-001, FR-HST-005
    test('a device is named as the flutter tool names it', () {
      expect(RunTarget.desktop().deviceId, Platform.operatingSystem);
      expect(const RunTarget.device('emulator-5554').toolArguments, isEmpty);
      expect(
        const RunTarget.device('flutter-tester'),
        const RunTarget.designHost(),
      );
    });
  });
}
