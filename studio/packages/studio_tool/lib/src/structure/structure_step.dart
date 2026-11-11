import 'dart:io';

import 'package:path/path.dart' as path;

import '../verify/gate_step.dart';
import '../verify/step_outcome.dart';
import '../verify/step_status.dart';
import 'dependency_graph_check.dart';
import 'package_anatomy_check.dart';
import 'source_layout_check.dart';
import 'structure_check.dart';

/// Step QG-08 of the quality gate: the structure of the own code.
///
/// It runs the checks that are built: the dependency graph, the anatomy of
/// each package, the mirror of the tests, the names with no content, the
/// writes outside the document store and the pinned version of the SDK.
/// Still not built: `unsafe` outside its crates, for there is no Rust
/// code, and generated output under version control.
final class StructureStep implements GateStep {
  /// Creates the step with its [checks].
  const StructureStep({
    this.checks = const [
      DependencyGraphCheck(),
      PackageAnatomyCheck(),
      SourceLayoutCheck(),
    ],
  });

  /// File of the workspace that pins the version of Flutter (CS-ASC-010).
  static const _versionFile = 'flutter-version.txt';

  /// The checks of the step, run in order.
  final List<StructureCheck> checks;

  @override
  String get id => 'QG-08';

  @override
  Future<StepOutcome> run(Directory workspace) async {
    try {
      final problems = [
        for (final check in checks) ...check.problemsIn(workspace),
        if (!File(path.join(workspace.path, _versionFile)).existsSync())
          'The workspace does not pin the version of Flutter.',
      ];
      return problems.isEmpty
          ? const StepOutcome(StepStatus.passed)
          : StepOutcome(StepStatus.failed, detail: problems.join('\n'));
    } on FileSystemException catch (exception) {
      return StepOutcome(StepStatus.notRun, detail: '$exception');
    }
  }
}
