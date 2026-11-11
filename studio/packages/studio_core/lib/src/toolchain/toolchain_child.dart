import 'dart:io';

/// A tool of the project SDK that the supervisor keeps running.
abstract interface class ToolchainChild {
  /// Name that identifies the child among the ones of a supervisor.
  String get name;

  /// Path of the executable to start.
  String get executablePath;

  /// Arguments for the executable.
  List<String> get arguments;

  /// Prepares a process that has just started, the first one or a
  /// replacement after an unexpected end.
  ///
  /// Completes when the tool is ready for use: connections made, and
  /// whatever the previous process had registered registered again.
  Future<void> attach(Process process);
}
