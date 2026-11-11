import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;

import '../verify/process_runner.dart';
import 'protocol_package.dart';

/// The `st generate` command, which writes the code derived from the
/// contract of the `Studio` service (ADR-0013).
final class GenerateCommand extends Command<int> {
  /// Creates a command that formats through [_runner] and reports to
  /// [_output].
  GenerateCommand(this._runner, this._output) {
    argParser
      ..addOption(
        _workspaceOption,
        defaultsTo: _currentDirectory,
        help: 'Root of the pub workspace of Studio.',
      )
      ..addFlag(
        _checkFlag,
        negatable: false,
        help: 'Writes nothing and fails when a generated file is stale.',
      );
  }

  /// Path of the protocol package, relative to the workspace root.
  static const protocolPackagePath = 'packages/studio_protocol';

  static const _workspaceOption = 'workspace';

  static const _checkFlag = 'check';

  static const _currentDirectory = '.';

  static const _successExitCode = 0;

  static const _failureExitCode = 1;

  final ProcessRunner _runner;

  final StringSink _output;

  @override
  String get name => 'generate';

  @override
  String get description =>
      'Generates the Dart code of studio_protocol from studio.openrpc.json.';

  /// Generates, or only compares when `--check` is given, and completes
  /// with the exit code: zero on success, one for an invalid contract or a
  /// stale file.
  @override
  Future<int> run() async {
    final workspacePath =
        argResults?.option(_workspaceOption) ?? _currentDirectory;
    final package = ProtocolPackage(
      path.join(workspacePath, protocolPackagePath),
      _runner,
    );
    try {
      if (argResults?.flag(_checkFlag) ?? false) {
        final differing = await package.findDifferences();
        differing.forEach(_output.writeln);
        return differing.isEmpty ? _successExitCode : _failureExitCode;
      }
      await package.generate();
      return _successExitCode;
    } on FormatException catch (exception) {
      _output.writeln(exception);
      return _failureExitCode;
    }
  }
}
