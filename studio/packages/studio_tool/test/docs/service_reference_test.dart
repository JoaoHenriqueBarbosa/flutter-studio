import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/sample_contract.dart';

void main() {
  // Verifies: NFR-MNT-007
  test('ServiceReference describes methods, events, errors and types', () {
    final reference = const ServiceReference().render(sampleContract);

    expect(reference, startsWith('# Sample service 1.2.3\n\nA sample.\n'));
    expect(reference, contains('### rename\n\nRenames a thing.\n'));
    expect(reference, contains('- `thing` (`Thing`): The thing to rename.'));
    expect(reference, contains('- `label` (`String`, optional): The new'));
    expect(reference, contains('Result: `Thing`.\n\nErrors: `NotFound`.'));
    expect(reference, contains('```json\n{\n  "name": "one",'));
    expect(reference, contains('### renamed\n\nA thing was renamed. Data: '));
    expect(reference, contains('- `-32001` `NotFound`. Data: The label.'));
    expect(
      reference,
      contains('The kind of a thing. One of: `small`, `large`.'),
    );
  });
}
