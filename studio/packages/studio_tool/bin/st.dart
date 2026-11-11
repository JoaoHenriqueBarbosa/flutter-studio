import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:studio_tool/studio_tool.dart';

/// Exit code that the BSD `sysexits` convention assigns to a usage error.
const _usageExitCode = 64;

/// Runs the `st` command with [arguments].
Future<void> main(List<String> arguments) async {
  const processRunner = SystemProcessRunner();
  const catalog = GateStepCatalog(processRunner);
  final gate = QualityGate(
    catalog.steps,
    requiredStepIds: catalog.requiredStepIds,
  );
  final runner = CommandRunner<int>('st', 'Development tool of Studio.')
    ..addCommand(VerifyCommand(gate, stdout))
    ..addCommand(GenerateCommand(processRunner, stdout));
  try {
    exitCode = await runner.run(arguments) ?? exitCode;
  } on UsageException catch (exception) {
    stderr.writeln(exception);
    exitCode = _usageExitCode;
  }
}
