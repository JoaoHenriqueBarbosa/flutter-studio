import 'dart:io';

import 'package:path/path.dart' as path;

import '../source/own_sources.dart';
import '../verify/gate_step.dart';
import '../verify/step_outcome.dart';
import '../verify/step_status.dart';
import 'waiver_registry.dart';

/// Step QG-13 of the quality gate: every suppression cites a waiver of the
/// registry, and every waiver of the registry is valid and in use
/// (CS-ASC-003, CS-GOV-001, CS-GOV-002).
final class WaiverStep implements GateStep {
  /// Creates the step, which takes [_today] as the current date.
  const WaiverStep(this._today);

  /// Where the registry is, relative to the workspace.
  static const _registryPath = '../docs/engineering/waivers.md';

  static final _suppression = RegExp(r'//\s*ignore(_for_file)?:');

  static final _waiver = RegExp(WaiverRegistry.identifierPattern);

  final DateTime Function() _today;

  @override
  String get id => 'QG-13';

  @override
  Future<StepOutcome> run(Directory workspace) async {
    try {
      final registry = WaiverRegistry.read(
        File(path.join(workspace.path, _registryPath)),
      );
      final cited = <String>{};
      final problems = [
        for (final file in OwnSources(workspace).read())
          if (!file.isGenerated) ..._problemsIn(file, registry, cited),
        for (final id in registry.validUntil.keys)
          if (registry.isExpired(id, _today()))
            '$id is past its validity.'
          else if (!cited.contains(id))
            '$id is in the registry and no code cites it.',
      ];
      return problems.isEmpty
          ? const StepOutcome(StepStatus.passed)
          : StepOutcome(StepStatus.failed, detail: problems.join('\n'));
    } on FileSystemException catch (exception) {
      return StepOutcome(StepStatus.notRun, detail: '$exception');
    }
  }

  /// Returns the problems of the suppressions of [file], and adds to
  /// [cited] the waivers that its suppressions cite.
  Iterable<String> _problemsIn(
    SourceFile file,
    WaiverRegistry registry,
    Set<String> cited,
  ) sync* {
    for (final (index, line) in file.lines.indexed) {
      final suppression = _suppression.firstMatch(line);
      if (suppression == null) continue;
      final place = '${file.relativePath}:${index + 1}';
      if (suppression.group(1) != null) {
        yield '$place suppresses a whole file that is not generated.';
        continue;
      }
      final justification = index == 0 ? '' : file.lines[index - 1];
      final id = _waiver.firstMatch(justification)?.group(0);
      if (id == null) {
        yield '$place suppresses a diagnostic and cites no waiver.';
      } else if (!registry.contains(id)) {
        yield '$place cites $id, which is not in the registry.';
      } else {
        cited.add(id);
      }
    }
  }
}
