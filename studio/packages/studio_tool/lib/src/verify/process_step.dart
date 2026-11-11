import 'dart:io';

import 'package:path/path.dart' as path;

import 'gate_step.dart';
import 'process_runner.dart';
import 'step_outcome.dart';
import 'step_status.dart';
import 'tool_invocation.dart';

/// A [GateStep] that passes when every one of its tools exits with zero.
final class ProcessStep implements GateStep {
  /// Creates a step that runs [invocations] in order through [_runner].
  ///
  /// When [requiredFile] is given, the step applies only to a workspace that
  /// has that file, named relative to the workspace root.
  const ProcessStep(
    this._runner, {
    required this.id,
    required this.invocations,
    this.requiredFile,
  });

  final ProcessRunner _runner;

  @override
  final String id;

  /// Command lines of the step. The first one that fails ends the step.
  final List<ToolInvocation> invocations;

  /// File that tells whether the workspace has code for this step to check,
  /// or `null` when the step always applies.
  final String? requiredFile;

  @override
  Future<StepOutcome> run(Directory workspace) async {
    final requiredFile = this.requiredFile;
    if (requiredFile != null &&
        !File(path.join(workspace.path, requiredFile)).existsSync()) {
      return StepOutcome(
        StepStatus.notApplicable,
        detail: 'The workspace has no $requiredFile.',
      );
    }
    for (final invocation in invocations) {
      final run = await _runner.run(invocation, workingDirectory: workspace);
      if (run == null) {
        return StepOutcome(
          StepStatus.notRun,
          detail: '${invocation.executable} is not installed.',
        );
      }
      if (run.exitCode != 0) {
        return StepOutcome(StepStatus.failed, detail: run.output);
      }
    }
    return const StepOutcome(StepStatus.passed);
  }
}
