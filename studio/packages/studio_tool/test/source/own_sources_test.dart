import 'dart:io';

import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/source_workspace.dart';

void main() {
  // Verifies: NFR-MNT-005
  test('OwnSources reads the Dart files of the source directories', () {
    final sandbox = Directory.systemTemp.createTempSync('own_sources');
    addTearDown(() => sandbox.deleteSync(recursive: true));
    final workspace = createSourceWorkspace(
      sandbox,
      sources: {
        'lib/a.dart': 'final a = 1;\n',
        'test/a_test.dart': '${OwnSources.generatedHeader}\nfinal b = 2;\n',
        'build/out.dart': 'final c = 3;\n',
        'lib/notes.txt': 'not code\n',
      },
    );

    final files = OwnSources(workspace).read();

    expect(files.map((file) => file.relativePath), [
      'packages/core/lib/a.dart',
      'packages/core/test/a_test.dart',
    ]);
    expect(files.map((file) => file.isGenerated), [false, true]);
    expect(files.first.lines, ['final a = 1;']);
  });
}
