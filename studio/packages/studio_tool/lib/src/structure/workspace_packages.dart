import 'dart:io';

import 'package:path/path.dart' as path;

/// The packages of a workspace of Studio, as directories on disk.
final class WorkspacePackages {
  /// Creates the view of the packages under [_workspace].
  const WorkspacePackages(this._workspace);

  static const _manifestFileName = 'pubspec.yaml';

  final Directory _workspace;

  /// The directory of each package, by package name, in name order.
  ///
  /// Throws a [FileSystemException] when the workspace has no packages.
  Map<String, Directory> get directories {
    final found =
        Directory(path.join(_workspace.path, 'packages'))
            .listSync()
            .whereType<Directory>()
            .where(
              (directory) =>
                  File(path.join(directory.path, _manifestFileName))
                      .existsSync(),
            )
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    return {
      for (final directory in found) path.basename(directory.path): directory,
    };
  }

  /// Returns the text of the manifest of the package in [directory].
  String manifestOf(Directory directory) =>
      File(path.join(directory.path, _manifestFileName)).readAsStringSync();

  /// Returns the path of [file] relative to the workspace.
  String relative(FileSystemEntity file) =>
      path.relative(file.path, from: _workspace.path);
}
