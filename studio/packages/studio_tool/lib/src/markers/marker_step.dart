import 'dart:io';

import 'package:path/path.dart' as path;

import '../source/own_sources.dart';
import '../verify/gate_step.dart';
import '../verify/process_runner.dart';
import '../verify/step_outcome.dart';
import '../verify/step_status.dart';
import '../verify/tool_invocation.dart';

/// Step QG-10 of the quality gate: the markers in the own code and in the
/// commit messages (CS-ASC-006, CS-ASC-007, CS-ASC-012, CS-CMT-009).
///
/// Two parts of the step in the coding standard are not built: the license
/// header, whose text depends on the license of the product, and the
/// literals of protocol and of interface. While the header has no text the
/// step does not approve.
final class MarkerStep implements GateStep {
  /// Creates the step, which reads the commit messages through [_runner].
  const MarkerStep(this._runner);

  /// File of the workspace with the text of the license header.
  static const _headerFile = 'license-header.txt';

  /// File of the repository with the base commit of the fork.
  static const _patchesPath = '../PATCHES.md';

  static final _baseCommit = RegExp(r'Commit base \| `([0-9a-f]{40})`');

  /// The marker of pending work, written in two pieces so that this file
  /// passes its own check.
  static const _pendingMarker =
      'TO'
      'DO';

  static final _validPending = RegExp(
    '// $_pendingMarker\\([\\w-]+\\): .+, https://\\S+\\.\$',
  );

  static final _pending = RegExp('\\b$_pendingMarker\\b');

  /// What may not reach the main branch, with the reason shown for each.
  static final _forbidden = {
    RegExp(
      '\\b(FIX'
      'ME|HA'
      'CK|XX'
      'X)\\b',
    ): 'uses a marker that is not allowed',
    RegExp(r'\b(print|debugPrint)\('): 'prints',
    RegExp(r'\bUnimplementedError\b'): 'has an unimplemented path',
    RegExp(r'\bskip:\s'): 'skips a test',
  };

  static final _attribution = RegExp(
    'co-authored-by|generated with',
    caseSensitive: false,
  );

  final ProcessRunner _runner;

  @override
  String get id => 'QG-10';

  @override
  Future<StepOutcome> run(Directory workspace) async {
    try {
      final problems = [
        for (final file in OwnSources(workspace).read())
          if (!file.isGenerated) ..._problemsIn(file),
        ...await _commitProblems(workspace),
      ];
      if (problems.isNotEmpty) {
        return StepOutcome(StepStatus.failed, detail: problems.join('\n'));
      }
      return File(path.join(workspace.path, _headerFile)).existsSync()
          ? const StepOutcome(StepStatus.passed)
          : const StepOutcome(
              StepStatus.notRun,
              detail:
                  'The license header has no text yet, so it is not checked.',
            );
    } on FileSystemException catch (exception) {
      return StepOutcome(StepStatus.notRun, detail: '$exception');
    }
  }

  Iterable<String> _problemsIn(SourceFile file) sync* {
    for (final (index, line) in file.lines.indexed) {
      final place = '${file.relativePath}:${index + 1}';
      if (_pending.hasMatch(line) && !_validPending.hasMatch(line.trimLeft())) {
        yield '$place has a marker of pending work without owner and issue.';
      }
      for (final MapEntry(key: pattern, value: reason) in _forbidden.entries) {
        if (pattern.hasMatch(line)) yield '$place $reason.';
      }
    }
  }

  String _attributionProblem(String message) {
    final commit = message.trim().split(' ').first;
    return 'Commit $commit attributes the work to a tool.';
  }

  /// Completes with one problem for each commit of Studio whose message
  /// attributes the work to a tool.
  Future<List<String>> _commitProblems(Directory workspace) async {
    final patches = File(path.join(workspace.path, _patchesPath));
    final base = _baseCommit.firstMatch(patches.readAsStringSync())?.group(1);
    if (base == null) return ['PATCHES.md does not name the base commit.'];
    final run = await _runner.run(
      ToolInvocation('git', ['log', '--format=%h %B%x00', '$base..HEAD']),
      workingDirectory: workspace,
    );
    if (run == null || run.exitCode != 0) {
      return ['The commit messages could not be read.'];
    }
    return [
      for (final message in run.output.split('\x00'))
        if (_attribution.hasMatch(message)) _attributionProblem(message),
    ];
  }
}
