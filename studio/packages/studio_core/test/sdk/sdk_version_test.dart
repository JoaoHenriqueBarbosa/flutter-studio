import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/studio_core.dart';

void main() {
  // Verifies: FR-PRJ-003
  group('SdkVersion.tryParse', () {
    test('reads a stable version', () {
      expect(SdkVersion.tryParse('3.47.9'), const SdkVersion(3, 47, 9));
    });

    test('ignores the pre-release suffix', () {
      expect(
        SdkVersion.tryParse('3.50.0-1.0.pre-437'),
        const SdkVersion(3, 50, 0),
      );
    });

    test('returns null for text that is not a version', () {
      expect(SdkVersion.tryParse('stable'), isNull);
      expect(SdkVersion.tryParse('3.47'), isNull);
    });
  });
}
