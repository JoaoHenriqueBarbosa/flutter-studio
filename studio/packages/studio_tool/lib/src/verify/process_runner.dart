import 'dart:io';

import 'tool_invocation.dart';
import 'tool_run.dart';

/// Runs the external tools of the quality gate.
///
/// The interface is the seam between the gate and the operating system, so
/// tests can replace the tools with a fake.
abstract interface class ProcessRunner {
  /// Runs [invocation] in [workingDirectory] and waits for it to end.
  ///
  /// Completes with `null` when the executable cannot be started, which is
  /// the case when the tool is not installed.
  Future<ToolRun?> run(
    ToolInvocation invocation, {
    required Directory workingDirectory,
  });
}
