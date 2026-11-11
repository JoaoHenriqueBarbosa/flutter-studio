import 'dart:io';

import 'package:path/path.dart' as path;

/// Creates under [parent] a workspace with documents that define three
/// requirements and one decision, and one test file with [testSource].
/// Returns the workspace directory.
Directory createTraceWorkspace(
  Directory parent, {
  required String testSource,
  String currentIncrement = 'F1',
}) {
  final workspace = Directory(path.join(parent.path, 'studio'))..createSync();
  File(path.join(parent.path, 'docs', 'requirements', 'srs.md'))
    ..createSync(recursive: true)
    ..writeAsStringSync('''
| ID | Requisito | Inc. | Ver. |
| --- | --- | --- | --- |
| FR-DOC-001 | Texto. | F0 | T |
| FR-DOC-002 | Texto. | F1, F5 | T, D |
| FR-CNV-001 | Texto. | F2 | T |
| IR-006 | Texto. | F0 | I |
| DC-01 | Uma restrição. |
''');
  File(path.join(parent.path, 'docs', 'decisions', 'README.md'))
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '| [ADR-0004](0004.md) | Funil | Aceita | 11/11/2026 |\n',
    );
  File(path.join(workspace.path, 'current-increment.txt'))
      .writeAsStringSync('$currentIncrement\n');
  File(path.join(workspace.path, 'packages', 'core', 'test', 'store_test.dart'))
    ..createSync(recursive: true)
    ..writeAsStringSync(testSource);
  return workspace;
}
