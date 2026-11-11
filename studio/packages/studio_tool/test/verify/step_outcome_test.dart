import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

void main() {
  // Verifies: NFR-MNT-005
  group('StepOutcome', () {
    test('is equal to an outcome with the same status and detail', () {
      const outcome = StepOutcome(StepStatus.failed, detail: 'One issue.');
      const same = StepOutcome(StepStatus.failed, detail: 'One issue.');
      const other = StepOutcome(StepStatus.failed, detail: 'Two issues.');

      expect(outcome, same);
      expect(outcome.hashCode, same.hashCode);
      expect(outcome, isNot(other));
    });
  });
}
