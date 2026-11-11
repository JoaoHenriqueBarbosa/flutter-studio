import 'dart:io';

import 'package:studio_tool/studio_tool.dart';

/// A [ProcessRunner] that answers from a table and records what it ran.
final class FakeProcessRunner implements ProcessRunner {
  /// Creates a runner that answers each executable with the run stored for
  /// it in [_runs]. An executable that has no entry counts as not installed.
  FakeProcessRunner(this._runs);

  final Map<String, ToolRun> _runs;

  /// Command lines received so far, in order.
  final commandLines = <String>[];

  @override
  Future<ToolRun?> run(
    ToolInvocation invocation, {
    required Directory workingDirectory,
  }) {
    commandLines.add('$invocation');
    return Future.value(_runs[invocation.executable]);
  }
}
