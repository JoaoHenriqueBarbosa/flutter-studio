import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/studio_core.dart';

void main() {
  // Verifies: NFR-FLEX-001
  group('SdkVersionWindow', () {
    const window = SdkVersionWindow([
      (major: 3, minor: 44),
      (major: 3, minor: 47),
    ]);

    test('contains any patch of its release lines', () {
      expect(window.contains(const SdkVersion(3, 44, 0)), isTrue);
      expect(window.contains(const SdkVersion(3, 47, 9)), isTrue);
    });

    test('does not contain older or newer release lines', () {
      expect(window.contains(const SdkVersion(3, 41, 2)), isFalse);
      expect(window.contains(const SdkVersion(3, 50, 0)), isFalse);
    });

    test('is described by its release lines', () {
      expect('$window', '3.44, 3.47');
    });
  });
}
