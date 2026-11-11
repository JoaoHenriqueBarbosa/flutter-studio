import 'dart:io';

import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/structure_workspace.dart';

void main() {
  // Verifies: NFR-MNT-005
  test('DependencyGraphCheck names each edge outside the graph', () {
    final sandbox = Directory.systemTemp.createTempSync('dependency_graph');
    addTearDown(() => sandbox.deleteSync(recursive: true));
    final workspace = createStructureWorkspace(
      sandbox,
      packages: {
        'studio_protocol': ['studio_core'],
        'studio_core': ['studio_protocol', 'devtools_app'],
        'studio_shell': ['studio_core', 'studio_tool'],
        'studio_extra': [],
      },
    );

    expect(const DependencyGraphCheck().problemsIn(workspace), [
      'studio_core depends on devtools_app, outside the dependency graph.',
      'studio_extra is not a package of the dependency graph.',
      'studio_protocol depends on studio_core, outside the dependency graph.',
      'studio_shell depends on studio_tool, outside the dependency graph.',
    ]);
  });
}
