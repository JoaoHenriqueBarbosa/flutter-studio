/// What an external tool produced when it ran to completion.
final class ToolRun {
  /// Creates the record of a run that ended with [exitCode].
  const ToolRun({required this.exitCode, required this.output});

  /// Exit code of the process. Zero means success.
  final int exitCode;

  /// Standard output followed by standard error.
  final String output;
}
