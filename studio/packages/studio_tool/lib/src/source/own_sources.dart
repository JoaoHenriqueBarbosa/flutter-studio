import 'dart:io';

import 'package:path/path.dart' as path;

/// One Dart file of the own code: its path relative to the workspace, its
/// lines, and whether a generator wrote it.
typedef SourceFile = ({
  String relativePath,
  List<String> lines,
  bool isGenerated,
});

/// The Dart files of the own code of a workspace of Studio, which the
/// checks of the quality gate read (CS-ASC-001).
final class OwnSources {
  /// Creates the reader of the sources under [_workspace].
  const OwnSources(this._workspace);

  /// First line of every generated file (CS-DRY-012).
  static const generatedHeader = '// GENERATED CODE - DO NOT MODIFY BY HAND';

  /// Directories of a package that hold own code.
  static const _sourceDirectories = ['bin', 'lib', 'test', 'tool'];

  final Directory _workspace;

  /// Reads every Dart file under the source directories of each package,
  /// in path order.
  ///
  /// Throws a [FileSystemException] when the workspace has no packages.
  List<SourceFile> read() {
    final packages = Directory(path.join(_workspace.path, 'packages'));
    final files = [
      for (final package in packages.listSync().whereType<Directory>())
        for (final name in _sourceDirectories)
          ..._dartFilesUnder(Directory(path.join(package.path, name))),
    ]..sort((a, b) => a.path.compareTo(b.path));
    return [for (final file in files) _read(file)];
  }

  Iterable<File> _dartFilesUnder(Directory directory) => directory.existsSync()
      ? directory
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
      : const [];

  SourceFile _read(File file) {
    final lines = file.readAsLinesSync();
    return (
      relativePath: path.relative(file.path, from: _workspace.path),
      lines: lines,
      isGenerated: lines.firstOrNull?.startsWith(generatedHeader) ?? false,
    );
  }
}
