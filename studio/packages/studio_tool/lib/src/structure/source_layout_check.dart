import 'dart:io';

import 'package:path/path.dart' as path;

import '../source/own_sources.dart';
import 'structure_check.dart';

/// Checks where the own Dart files are and how they are named: every test
/// mirrors a file of `lib/src/`, no name is empty of content, and only the
/// document store writes to files (section 2.2, CS-NAM-012, CS-DSN-003).
final class SourceLayoutCheck implements StructureCheck {
  /// Creates the check.
  const SourceLayoutCheck();

  static const _testSuffix = '_test.dart';

  /// Directory of the shared infrastructure of the tests of a package,
  /// which mirrors no file.
  static const _supportDirectory = 'support';

  /// Words that say nothing about what a file or a type holds.
  static final _emptyName = RegExp(
    r'(^|_)(manager|helper|utils?|misc|common)(_|\.dart$)',
  );

  static final _fileWrite = RegExp(
    r'\.(writeAsString|writeAsBytes|writeAsStringSync|writeAsBytesSync)\(',
  );

  /// The files of the shell and of the core that may write to disk: the
  /// document store, for the files of the project, and the generator of
  /// the host project, which writes under `.dart_tool/`.
  static const _writers = {
    'packages/studio_core/lib/src/document/document_store.dart',
    'packages/studio_core/lib/src/host/design_host_project.dart',
  };

  static const _productPackages = ['studio_core', 'studio_shell'];

  @override
  List<String> problemsIn(Directory workspace) {
    final files = OwnSources(workspace).read();
    final paths = {for (final file in files) file.relativePath};
    return [for (final file in files) ..._problemsOf(file, paths)];
  }

  Iterable<String> _problemsOf(SourceFile file, Set<String> paths) sync* {
    final filePath = file.relativePath;
    if (_emptyName.hasMatch(path.basename(filePath))) {
      yield '$filePath has a name with no content.';
    }
    final parts = path.split(filePath);
    // Parts: `packages`, the package, the source directory, and the rest.
    const packageIndex = 1;
    const directoryIndex = 2;
    final rest = parts.sublist(directoryIndex + 1);
    final isTest =
        parts[directoryIndex] == 'test' &&
        filePath.endsWith(_testSuffix) &&
        rest.first != _supportDirectory;
    if (isTest) {
      final mirrored = path.joinAll([
        ...parts.take(directoryIndex),
        'lib',
        'src',
        ...rest,
      ]);
      final source =
          '${mirrored.substring(0, mirrored.length - _testSuffix.length)}.dart';
      if (!paths.contains(source)) yield '$filePath mirrors no file: $source.';
    }
    final writesOutsideStore =
        _productPackages.contains(parts[packageIndex]) &&
        parts[directoryIndex] == 'lib' &&
        !_writers.contains(filePath) &&
        file.lines.any(_fileWrite.hasMatch);
    if (writesOutsideStore) {
      yield '$filePath writes to a file outside the document store.';
    }
  }
}
