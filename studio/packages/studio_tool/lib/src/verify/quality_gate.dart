import 'dart:io';

import 'gate_step.dart';
import 'step_outcome.dart';
import 'step_status.dart';

/// The quality gate: every required step, run one after the other.
///
/// The steps run in sequence because the tools compete for the same build
/// directories.
final class QualityGate {
  /// Creates a gate that runs [_steps] and answers for [requiredStepIds].
  const QualityGate(this._steps, {required this.requiredStepIds});

  final List<GateStep> _steps;

  /// Identifiers of all the steps the gate must report, in report order.
  ///
  /// A required identifier with no step among the ones given to the
  /// constructor is reported as [StepStatus.notRun], so a step that is not
  /// built yet rejects the change instead of being skipped.
  final List<String> requiredStepIds;

  /// Runs the steps on [workspace] and completes with one outcome for each
  /// required identifier.
  Future<Map<String, StepOutcome>> run(Directory workspace) async {
    final outcomes = {
      for (final id in requiredStepIds)
        id: const StepOutcome(
          StepStatus.notRun,
          detail: 'No step is registered for this identifier.',
        ),
    };
    for (final step in _steps) {
      outcomes[step.id] = await step.run(workspace);
    }
    return outcomes;
  }
}
