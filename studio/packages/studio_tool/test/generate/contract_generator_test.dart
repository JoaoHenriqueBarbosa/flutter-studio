import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/sample_contract.dart';

void main() {
  // Verifies: NFR-MNT-006
  test('ContractGenerator writes one file for each part and the library', () {
    final files = const ContractGenerator().generate(
      sampleContract,
      handwrittenSources: ['src/sample_fault.dart'],
    );

    expect(files.keys, [
      'src/generated/thing.dart',
      'src/generated/kind.dart',
      'src/generated/sample_contract.dart',
      'src/generated/sample_method.dart',
      'src/generated/sample_event.dart',
      'src/generated/sample_error_code.dart',
      'src/generated/sample_agent_extension.dart',
      'src/generated/sample_api.dart',
      'src/generated/sample_client.dart',
      'src/generated/sample_dispatcher.dart',
      'studio_protocol.dart',
    ]);
    expect(
      files['studio_protocol.dart'],
      allOf(
        startsWith(generatedHeader),
        contains("export 'src/generated/kind.dart';\n"),
        contains("export 'src/sample_fault.dart';\n"),
      ),
    );
  });
}
