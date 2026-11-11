import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/sample_contract.dart';

void main() {
  // Verifies: NFR-MNT-006
  test('ConstantsEmitter writes the names and numbers of the contract', () {
    final files = ConstantsEmitter(sampleContract).emit();

    expect(files.keys, [
      'sample_contract.dart',
      'sample_method.dart',
      'sample_event.dart',
      'sample_error_code.dart',
    ]);
    expect(
      files['sample_contract.dart'],
      allOf(
        contains("static const version = '1.2.3';"),
        contains("static const serviceName = 'Sample';"),
      ),
    );
    expect(
      files['sample_method.dart'],
      contains('  /// Renames a thing.\n  rename,'),
    );
    expect(files['sample_event.dart'], contains('  renamed,'));
    expect(
      files['sample_error_code.dart'],
      contains("  /// Comes with: the label.\n  notFound(-32001, 'NotFound');"),
    );
  });
}
