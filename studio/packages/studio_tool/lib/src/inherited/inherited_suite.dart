import 'dart:io';

import 'package:path/path.dart' as path;

import '../verify/process_runner.dart';
import '../verify/tool_invocation.dart';

/// The tests that came with the code inherited from DevTools, which have
/// to keep passing with the patches of Studio on top (NFR-MNT-004).
final class InheritedSuite {
  /// Creates the suite of the repository at [_repositoryPath], run with
  /// the tools that [_runner] starts.
  ///
  /// [searchPath] is the value of `PATH` in this process, to which the
  /// suite puts the candidate SDK in front.
  const InheritedSuite(
    this._repositoryPath,
    this._runner, {
    required this.searchPath,
  });

  /// The inherited packages whose tests run on the Dart VM, by path
  /// relative to the repository, each with the tool that runs its tests:
  /// `flutter` for a Flutter package, `dart` for a package of pure Dart.
  static const testTools = {
    'packages/devtools_app': 'flutter',
    'packages/devtools_app_shared': 'flutter',
    'packages/devtools_extensions': 'flutter',
    'packages/devtools_shared': 'dart',
  };

  /// Directory of the candidate SDK that the upstream pins, which the `dt`
  /// tool installs (ADR-0014).
  static const _sdkPath = 'tool/flutter-sdk';

  /// Variable from which the tools of Dart learn where the Flutter SDK is.
  static const _flutterRootVariable = 'FLUTTER_ROOT';

  static const _searchPathVariable = 'PATH';

  final String _repositoryPath;

  /// Where this process looks for executables.
  final String searchPath;

  final ProcessRunner _runner;

  /// Runs the tests of each inherited package and completes with one line
  /// for each package whose tests did not all pass. The list is empty when
  /// the whole suite passes.
  Future<List<String>> run() async {
    final sdkPath = path.normalize(path.absolute(_repositoryPath, _sdkPath));
    final problems = <String>[];
    for (final MapEntry(key: packagePath, value: tool) in testTools.entries) {
      final result = await _runner.run(
        ToolInvocation(
          path.join(sdkPath, 'bin', tool),
          const ['test'],
          // This process may run under another Flutter SDK. Tools and tests
          // that find it, by its root or on the path, resolve the packages
          // of the inherited workspace with it and rewrite the lock file.
          environment: {
            _flutterRootVariable: sdkPath,
            _searchPathVariable: [
              path.join(sdkPath, 'bin'),
              searchPath,
            ].join(Platform.isWindows ? ';' : ':'),
          },
        ),
        workingDirectory: Directory(path.join(_repositoryPath, packagePath)),
      );
      if (result == null) {
        problems.add('$packagePath: the candidate SDK is not installed.');
      } else if (result.exitCode != 0) {
        final lastLines = result.output.trimRight().split('\n').reversed;
        problems.add('$packagePath: ${lastLines.take(3).join(' | ')}');
      }
    }
    return problems;
  }
}
