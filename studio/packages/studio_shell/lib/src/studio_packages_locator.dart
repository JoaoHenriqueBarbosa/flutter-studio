import 'dart:io';

import 'package:path/path.dart' as path;

/// Finds the directory with the sources that Studio compiles with the SDK
/// of the project: the design agent and the contract it depends on.
///
/// An installed Studio carries the sources beside its executable. A build
/// made inside the repository finds them in the repository.
final class StudioPackagesLocator {
  /// Creates a locator that reads the override from [_environment].
  const StudioPackagesLocator(this._environment);

  /// Variable that names the directory, when it is not beside the
  /// executable.
  static const environmentVariable = 'STUDIO_PACKAGES_PATH';

  static const _agentPackageName = 'studio_design_agent';

  static const _packagesDirectoryName = 'packages';

  final Map<String, String> _environment;

  /// Returns the directory that holds the agent package, looked for in the
  /// environment and then from the directory of [executablePath] upwards,
  /// or `null` when it is not found.
  String? locate(String executablePath) {
    final configured = _environment[environmentVariable];
    if (configured != null) return _holdsAgent(configured) ? configured : null;
    var directory = path.dirname(path.absolute(executablePath));
    while (true) {
      final candidates = [
        directory,
        path.join(directory, _packagesDirectoryName),
      ];
      final found = candidates.where(_holdsAgent).firstOrNull;
      final parent = path.dirname(directory);
      if (found != null || parent == directory) return found;
      directory = parent;
    }
  }

  bool _holdsAgent(String directory) =>
      File(path.join(directory, _agentPackageName, 'pubspec.yaml'))
          .existsSync();
}
