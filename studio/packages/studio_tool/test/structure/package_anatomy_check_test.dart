import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

import '../support/structure_workspace.dart';

void main() {
  // Verifies: NFR-MNT-005
  test('PackageAnatomyCheck names what a package lacks or has too much', () {
    final sandbox = Directory.systemTemp.createTempSync('package_anatomy');
    addTearDown(() => sandbox.deleteSync(recursive: true));
    final workspace = createStructureWorkspace(
      sandbox,
      packages: {'studio_core': [], 'studio_shell': [], 'studio_tool': []},
      files: {
        'packages/studio_core/lib/studio_core.dart':
            "export 'src/a.dart';\n\nfinal b = 2;\n",
        'packages/studio_shell/analysis_options.yaml':
            'include: ../../analysis_options.yaml\nlinter:\n  rules: []\n',
      },
    );
    final tool = path.join(workspace.path, 'packages', 'studio_tool');
    File(path.join(tool, 'README.md')).deleteSync();
    File(path.join(tool, 'lib', 'studio_tool.dart')).deleteSync();

    expect(const PackageAnatomyCheck().problemsIn(workspace), [
      'lib/studio_core.dart of studio_core has more than exports.',
      'studio_shell declares analysis rules of its own.',
      'studio_tool has no README.md.',
      'studio_tool has no public library lib/studio_tool.dart.',
    ]);
  });
}
