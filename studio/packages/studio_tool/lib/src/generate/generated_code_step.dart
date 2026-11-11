import 'dart:io';

import 'package:path/path.dart' as path;

import '../verify/gate_step.dart';
import '../verify/process_runner.dart';
import '../verify/step_outcome.dart';
import '../verify/step_status.dart';
import 'generate_command.dart';
import 'protocol_package.dart';

/// Step QG-09 of the quality gate: the versioned generated code is what the
/// contract produces, and the contract follows the naming convention.
final class GeneratedCodeStep implements GateStep {
  /// Creates the step, which formats through [_runner].
  const GeneratedCodeStep(this._runner);

  final ProcessRunner _runner;

  @override
  String get id => 'QG-09';

  @override
  Future<StepOutcome> run(Directory workspace) async {
    final package = ProtocolPackage(
      path.join(workspace.path, GenerateCommand.protocolPackagePath),
      _runner,
    );
    try {
      final differing = await package.findDifferences();
      return differing.isEmpty
          ? const StepOutcome(StepStatus.passed)
          : StepOutcome(
              StepStatus.failed,
              detail: 'Stale generated files:\n${differing.join('\n')}',
            );
    } on FormatException catch (exception) {
      return StepOutcome(StepStatus.failed, detail: '$exception');
    } on FileSystemException catch (exception) {
      return StepOutcome(StepStatus.notRun, detail: '$exception');
    }
  }
}
