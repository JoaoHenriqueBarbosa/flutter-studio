import 'dart:io';

import 'package:args/command_runner.dart';

import '../verify/process_runner.dart';
import 'documentation_set.dart';

/// The `st docs` command, which generates the reference of each package
/// and of the `Studio` service (NFR-MNT-007).
final class DocsCommand extends Command<int> {
  /// Creates a command that runs its tools through [_runner] and reports
  /// to [_output].
  DocsCommand(this._runner, this._output) {
    argParser.addOption(
      _workspaceOption,
      defaultsTo: _currentDirectory,
      help: 'Root of the pub workspace of Studio.',
    );
  }

  static const _workspaceOption = 'workspace';

  static const _currentDirectory = '.';

  static const _successExitCode = 0;

  static const _failureExitCode = 1;

  final ProcessRunner _runner;

  final StringSink _output;

  @override
  String get name => 'docs';

  @override
  String get description =>
      'Generates the API reference into ${DocumentationSet.outputPath}.';

  /// Generates the documentation and completes with the exit code: zero
  /// when no generator reported a warning, one otherwise.
  @override
  Future<int> run() async {
    final workspacePath =
        argResults?.option(_workspaceOption) ?? _currentDirectory;
    try {
      final problems = await DocumentationSet(
        Directory(workspacePath),
        _runner,
      ).generate();
      problems.forEach(_output.writeln);
      return problems.isEmpty ? _successExitCode : _failureExitCode;
    } on FormatException catch (exception) {
      _output.writeln(exception);
      return _failureExitCode;
    } on FileSystemException catch (exception) {
      _output.writeln(exception);
      return _failureExitCode;
    }
  }
}
