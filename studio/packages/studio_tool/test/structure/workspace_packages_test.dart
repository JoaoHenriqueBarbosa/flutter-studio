import 'dart:io';

import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/structure_workspace.dart';

void main() {
  // Verifies: NFR-MNT-005
  test('WorkspacePackages lists the packages in name order', () {
    final sandbox = Directory.systemTemp.createTempSync('workspace_packages');
    addTearDown(() => sandbox.deleteSync(recursive: true));
    final workspace = createStructureWorkspace(
      sandbox,
      packages: {
        'studio_shell': [],
        'studio_core': ['studio_protocol'],
      },
    );
    final packages = WorkspacePackages(workspace);

    final directories = packages.directories;

    expect(directories.keys, ['studio_core', 'studio_shell']);
    expect(
      packages.manifestOf(directories.values.first),
      contains('  studio_protocol:\n'),
    );
    expect(packages.relative(directories.values.last), 'packages/studio_shell');
  });
}
