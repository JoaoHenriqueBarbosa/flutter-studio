import 'dart:io';

import '../verify/gate_step.dart';
import '../verify/step_outcome.dart';
import '../verify/step_status.dart';
import 'workspace_trace.dart';

/// Step QG-12 of the quality gate: every identifier that a test cites
/// exists, and every requirement of the increment has a test.
final class TraceStep implements GateStep {
  /// Creates the step.
  const TraceStep();

  @override
  String get id => 'QG-12';

  @override
  Future<StepOutcome> run(Directory workspace) async {
    try {
      final report = const WorkspaceTrace().read(workspace);
      if (report.isComplete) return const StepOutcome(StepStatus.passed);
      return StepOutcome(StepStatus.failed, detail: report.problems.join('\n'));
    } on FileSystemException catch (exception) {
      return StepOutcome(StepStatus.notRun, detail: '$exception');
    }
  }
}
