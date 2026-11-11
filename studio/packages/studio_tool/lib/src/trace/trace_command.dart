import 'dart:io';

import 'package:args/command_runner.dart';

import 'workspace_trace.dart';

/// The `st trace` command, which prints the traceability matrix between
/// requirements and tests.
final class TraceCommand extends Command<int> {
  /// Creates a command that reports to [_output].
  TraceCommand(this._output) {
    argParser
      ..addOption(
        _workspaceOption,
        defaultsTo: _currentDirectory,
        help: 'Root of the pub workspace of Studio.',
      )
      ..addFlag(
        _checkFlag,
        negatable: false,
        help: 'Fails when the trace has an unknown identifier or a gap.',
      );
  }

  static const _workspaceOption = 'workspace';

  static const _checkFlag = 'check';

  static const _currentDirectory = '.';

  static const _successExitCode = 0;

  static const _failureExitCode = 1;

  final StringSink _output;

  @override
  String get name => 'trace';

  @override
  String get description =>
      'Prints which tests verify each requirement of the SRS.';

  /// Prints the matrix and completes with the exit code: one when `--check`
  /// is given and the trace is not complete, zero otherwise.
  @override
  Future<int> run() async {
    final workspacePath =
        argResults?.option(_workspaceOption) ?? _currentDirectory;
    try {
      final report = const WorkspaceTrace().read(Directory(workspacePath));
      _output.writeln(report.describe());
      final isChecking = argResults?.flag(_checkFlag) ?? false;
      return isChecking && !report.isComplete
          ? _failureExitCode
          : _successExitCode;
    } on FileSystemException catch (exception) {
      _output.writeln(exception);
      return _failureExitCode;
    }
  }
}
