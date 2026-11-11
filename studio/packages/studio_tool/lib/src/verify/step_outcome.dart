import 'step_status.dart';

/// Result of one step of the quality gate.
final class StepOutcome {
  /// Creates the outcome of a step that ended with [status].
  const StepOutcome(this.status, {this.detail = ''});

  /// How the step ended.
  final StepStatus status;

  /// What the step reported: the tool output for a failure, or the reason
  /// why the step did not check anything. Empty when the step passed.
  final String detail;

  @override
  bool operator ==(Object other) =>
      other is StepOutcome && other.status == status && other.detail == detail;

  @override
  int get hashCode => Object.hash(status, detail);

  @override
  String toString() => 'StepOutcome(${status.name}, $detail)';
}
