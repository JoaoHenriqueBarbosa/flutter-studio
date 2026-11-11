import 'dart:io';

import 'package:path/path.dart' as path;

import 'structure_check.dart';
import 'workspace_packages.dart';

/// Checks that every package has the files of section 2.2 of the coding
/// standard, and that its public library only exports (CS-ASC-009,
/// CS-QLT-002).
final class PackageAnatomyCheck implements StructureCheck {
  /// Creates the check.
  const PackageAnatomyCheck();

  static const _requiredFiles = [
    'README.md',
    'CHANGELOG.md',
    'analysis_options.yaml',
  ];

  /// The lines that a public library may have besides its exports: the
  /// library directive, comments and the continuation of an export.
  static final _libraryLine = RegExp(r"^(export '|library;|//|    |$)");

  static final _ownRule = RegExp(r'^linter:', multiLine: true);

  @override
  List<String> problemsIn(Directory workspace) {
    final packages = WorkspacePackages(workspace);
    return [
      for (final MapEntry(key: name, value: directory)
          in packages.directories.entries)
        ..._problemsOf(name, directory),
    ];
  }

  Iterable<String> _problemsOf(String name, Directory directory) sync* {
    for (final fileName in _requiredFiles) {
      if (!File(path.join(directory.path, fileName)).existsSync()) {
        yield '$name has no $fileName.';
      }
    }
    final options = File(path.join(directory.path, 'analysis_options.yaml'));
    if (options.existsSync() && _ownRule.hasMatch(options.readAsStringSync())) {
      yield '$name declares analysis rules of its own.';
    }
    final library = File(path.join(directory.path, 'lib', '$name.dart'));
    if (!library.existsSync()) {
      yield '$name has no public library lib/$name.dart.';
    } else if (!library.readAsLinesSync().every(_libraryLine.hasMatch)) {
      yield 'lib/$name.dart of $name has more than exports.';
    }
  }
}
