import 'dart:io';

import 'package:path/path.dart' as path;

/// Mark that the sources of a test carry inside each word that the checks
/// of the gate look for, so that the test file itself passes the checks.
const mask = '@';

/// Creates under [parent] a workspace whose package `core` has the Dart
/// files of [sources], by path relative to the package and with every
/// [mask] taken out, and returns the workspace directory. [waivers] is the
/// content of the registry of waivers, and [hasLicenseHeader] tells whether
/// the header has a text.
Directory createSourceWorkspace(
  Directory parent, {
  required Map<String, String> sources,
  String? waivers,
  bool hasLicenseHeader = true,
}) {
  final workspace = Directory(path.join(parent.path, 'studio'))..createSync();
  for (final MapEntry(key: relativePath, value: source) in sources.entries) {
    File(path.join(workspace.path, 'packages', 'core', relativePath))
      ..createSync(recursive: true)
      ..writeAsStringSync(source.replaceAll(mask, ''));
  }
  File(path.join(parent.path, 'PATCHES.md'))
      .writeAsStringSync('| Commit base | `${'a' * 40}`, de 10/11/2026 |\n');
  if (waivers != null) {
    File(path.join(parent.path, 'docs', 'engineering', 'waivers.md'))
      ..createSync(recursive: true)
      ..writeAsStringSync(waivers);
  }
  if (hasLicenseHeader) {
    File(path.join(workspace.path, 'license-header.txt'))
        .writeAsStringSync('// Header.\n');
  }
  return workspace;
}
