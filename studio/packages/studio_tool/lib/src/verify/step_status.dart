/// How one step of the quality gate ended.
enum StepStatus {
  /// The step ran and found no violation.
  passed(approves: true),

  /// The step has nothing to check in the workspace.
  notApplicable(approves: true),

  /// The step ran and found at least one violation.
  failed(approves: false),

  /// The step could not run, so nothing is known about the code.
  notRun(approves: false);

  const StepStatus({required this.approves});

  /// Whether a step that ended this way lets the gate approve the change.
  final bool approves;
}
