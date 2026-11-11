import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/fake_process_runner.dart';

void main() {
  // Verifies: NFR-MNT-005
  group('GateStepCatalog', () {
    final catalog = GateStepCatalog(FakeProcessRunner(const {}));

    test('requires the thirteen steps of the coding standard', () {
      expect(catalog.requiredStepIds, [
        'QG-01',
        'QG-02',
        'QG-03',
        'QG-04',
        'QG-05',
        'QG-06',
        'QG-07',
        'QG-08',
        'QG-09',
        'QG-10',
        'QG-11',
        'QG-12',
        'QG-13',
      ]);
    });

    test('builds only steps that the gate requires, once each', () {
      final ids = [for (final step in catalog.steps) step.id];

      expect(ids.toSet(), hasLength(ids.length));
      expect(catalog.requiredStepIds, containsAll(ids));
    });
  });
}
