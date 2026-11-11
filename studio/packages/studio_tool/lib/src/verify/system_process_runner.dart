import 'dart:io';

import 'process_runner.dart';
import 'tool_invocation.dart';
import 'tool_run.dart';

/// A [ProcessRunner] that starts real processes of the operating system.
final class SystemProcessRunner implements ProcessRunner {
  /// Creates a runner that resolves executables through `PATH`.
  const SystemProcessRunner();

  @override
  Future<ToolRun?> run(
    ToolInvocation invocation, {
    required Directory workingDirectory,
  }) async {
    try {
      final result = await Process.run(
        invocation.executable,
        invocation.arguments,
        workingDirectory: workingDirectory.path,
        environment: invocation.environment,
      );
      return ToolRun(
        exitCode: result.exitCode,
        output: '${result.stdout}${result.stderr}',
      );
    } on ProcessException {
      return null;
    }
  }
}
