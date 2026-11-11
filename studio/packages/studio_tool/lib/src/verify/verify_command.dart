import 'dart:io';

import 'package:args/command_runner.dart';

import 'quality_gate.dart';
import 'step_outcome.dart';

/// The `st verify` command, which runs the quality gate (NFR-MNT-005).
final class VerifyCommand extends Command<int> {
  /// Creates a command that runs [_gate] and writes the report to [_output].
  VerifyCommand(this._gate, this._output) {
    argParser.addOption(
      _workspaceOption,
      defaultsTo: _currentDirectory,
      help: 'Root of the pub workspace of Studio.',
    );
  }

  static const _workspaceOption = 'workspace';

  static const _currentDirectory = '.';

  static const _approvedExitCode = 0;

  static const _rejectedExitCode = 1;

  final QualityGate _gate;

  final StringSink _output;

  @override
  String get name => 'verify';

  @override
  String get description =>
      'Runs the quality gate of the coding standard on the own code.';

  /// Runs the gate and completes with the exit code: zero when every step
  /// approves, one otherwise.
  @override
  Future<int> run() async {
    final workspacePath =
        argResults?.option(_workspaceOption) ?? _currentDirectory;
    final outcomes = await _gate.run(Directory(workspacePath));
    outcomes.forEach(_writeOutcome);
    final approved = outcomes.values.every(
      (outcome) => outcome.status.approves,
    );
    _output.writeln(
      approved ? 'Quality gate approved.' : 'Quality gate rejected.',
    );
    return approved ? _approvedExitCode : _rejectedExitCode;
  }

  void _writeOutcome(String id, StepOutcome outcome) {
    _output.writeln('$id ${outcome.status.name}');
    final detail = outcome.detail.trimRight();
    if (detail.isNotEmpty) _output.writeln(detail);
  }
}
