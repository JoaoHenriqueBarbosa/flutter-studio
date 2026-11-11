import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

void main() {
  // Verifies: NFR-MNT-005
  test('StepStatus approves only a step that passed or does not apply', () {
    final approving = [
      for (final status in StepStatus.values)
        if (status.approves) status,
    ];

    expect(approving, [StepStatus.passed, StepStatus.notApplicable]);
  });
}
