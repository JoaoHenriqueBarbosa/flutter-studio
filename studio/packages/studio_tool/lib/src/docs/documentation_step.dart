import 'dart:io';

import '../verify/gate_step.dart';
import '../verify/process_runner.dart';
import '../verify/step_outcome.dart';
import '../verify/step_status.dart';
import 'documentation_set.dart';

/// Step QG-11 of the quality gate: the reference of every package and of
/// the `Studio` service is generated without a warning.
final class DocumentationStep implements GateStep {
  /// Creates the step, which runs its tools through [_runner].
  const DocumentationStep(this._runner);

  final ProcessRunner _runner;

  @override
  String get id => 'QG-11';

  @override
  Future<StepOutcome> run(Directory workspace) async {
    try {
      final problems = await DocumentationSet(workspace, _runner).generate();
      return problems.isEmpty
          ? const StepOutcome(StepStatus.passed)
          : StepOutcome(StepStatus.failed, detail: problems.join('\n'));
    } on FormatException catch (exception) {
      return StepOutcome(StepStatus.failed, detail: '$exception');
    } on FileSystemException catch (exception) {
      return StepOutcome(StepStatus.notRun, detail: '$exception');
    }
  }
}
