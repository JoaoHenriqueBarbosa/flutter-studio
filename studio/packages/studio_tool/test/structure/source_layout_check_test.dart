import 'dart:io';

import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/structure_workspace.dart';

void main() {
  // Verifies: NFR-MNT-005
  test('SourceLayoutCheck names tests, names and writes out of place', () {
    final sandbox = Directory.systemTemp.createTempSync('source_layout');
    addTearDown(() => sandbox.deleteSync(recursive: true));
    const core = 'packages/studio_core';
    final workspace = createStructureWorkspace(
      sandbox,
      packages: {'studio_core': [], 'studio_tool': []},
      files: {
        '$core/test/edit/pipeline_test.dart': 'void main() {}\n',
        '$core/test/support/fake_test.dart': 'void main() {}\n',
        '$core/lib/src/string_utils.dart': 'final u = 1;\n',
        '$core/lib/src/exporter.dart': "void f(f) => f.writeAsString('x');\n",
        '$core/lib/src/document/document_store.dart':
            "void g(f) => f.writeAsString('x');\n",
        'packages/studio_tool/lib/src/writer.dart':
            "void h(f) => f.writeAsStringSync('x');\n",
      },
    );

    expect(
      const SourceLayoutCheck().problemsIn(workspace).join('\n'),
      '''
$core/lib/src/exporter.dart writes to a file outside the document store.
$core/lib/src/string_utils.dart has a name with no content.
$core/test/edit/pipeline_test.dart mirrors no file: $core/lib/src/edit/pipeline.dart.''',
    );
  });
}
