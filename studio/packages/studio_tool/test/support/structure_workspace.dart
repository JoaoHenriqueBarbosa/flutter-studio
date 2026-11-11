import 'dart:io';

import 'package:path/path.dart' as path;

/// Creates under [parent] a workspace with one well-formed package for
/// each name in [packages], each with the dependencies given for it, and
/// returns the workspace directory. [files] are extra files, by path
/// relative to the workspace.
Directory createStructureWorkspace(
  Directory parent, {
  required Map<String, List<String>> packages,
  Map<String, String> files = const {},
}) {
  final workspace = Directory(path.join(parent.path, 'studio'))..createSync();
  File(path.join(workspace.path, 'flutter-version.txt')).writeAsStringSync('3');
  void write(String relativePath, String content) =>
      File(path.join(workspace.path, relativePath))
        ..createSync(recursive: true)
        ..writeAsStringSync(content);
  for (final MapEntry(key: name, value: dependencies) in packages.entries) {
    final root = path.join('packages', name);
    final dependencyLines = [
      for (final dependency in dependencies) '  $dependency:\n',
    ].join();
    write(
      path.join(root, 'pubspec.yaml'),
      'name: $name\ndependencies:\n  path: ^1.9.0\n$dependencyLines',
    );
    write(path.join(root, 'README.md'), '# $name\n');
    write(path.join(root, 'CHANGELOG.md'), '# Changelog\n');
    write(
      path.join(root, 'analysis_options.yaml'),
      'include: ../../analysis_options.yaml\n',
    );
    write(
      path.join(root, 'lib', '$name.dart'),
      "/// A package.\nlibrary;\n\nexport 'src/a.dart';\n",
    );
    write(path.join(root, 'lib', 'src', 'a.dart'), 'final a = 1;\n');
    write(path.join(root, 'test', 'a_test.dart'), 'void main() {}\n');
  }
  files.forEach(write);
  return workspace;
}
