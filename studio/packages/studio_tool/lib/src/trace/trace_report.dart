import 'identifier_catalog.dart';
import 'requirement.dart';
import 'test_trace.dart';

/// The comparison between what the tests say they verify and what the
/// documents define.
final class TraceReport {
  /// Compares [_trace] with [_catalog], for the requirements that enter up
  /// to the increment [currentIncrement], such as `F1`.
  TraceReport(this._catalog, this._trace, {required this.currentIncrement});

  final IdentifierCatalog _catalog;

  final TestTrace _trace;

  /// The increment under construction. A requirement of a later increment
  /// may still be without a test.
  final String currentIncrement;

  /// The identifiers that a test cites and no document defines, each with
  /// the test files that cite it.
  Map<String, Set<String>> get unknownIdentifiers => {
    for (final MapEntry(key: id, value: tests)
        in _trace.testsByIdentifier.entries)
      if (!_catalog.identifiers.contains(id)) id: tests,
  };

  /// The requirements verified by test that enter up to
  /// [currentIncrement] and that no test cites, in document order.
  List<String> get untestedRequirements => [
    for (final requirement in _catalog.requirements)
      if (requirement.isTested &&
          requirement.increment.compareTo(currentIncrement) <= 0 &&
          !_trace.testsByIdentifier.containsKey(requirement.id))
        requirement.id,
  ];

  /// Whether no test cites an unknown identifier and no requirement of the
  /// increment lacks a test.
  bool get isComplete =>
      unknownIdentifiers.isEmpty && untestedRequirements.isEmpty;

  /// One line for each unknown identifier, and one for the requirements
  /// without a test. Empty when the trace is complete.
  List<String> get problems => [
    for (final MapEntry(key: id, value: tests) in unknownIdentifiers.entries)
      'Unknown identifier $id in ${tests.join(', ')}',
    if (untestedRequirements case [_, ...] && final untested)
      'Without test up to $currentIncrement: ${untested.join(', ')}',
  ];

  /// The matrix of each requirement with the number of test files that
  /// verify it, followed by the problems, as text for a terminal.
  String describe() => [
    for (final requirement in _catalog.requirements) _matrixLine(requirement),
    ...problems,
  ].join('\n');

  String _matrixLine(Requirement requirement) {
    final testCount = _trace.testsByIdentifier[requirement.id]?.length ?? 0;
    return '${requirement.id} ${requirement.increment} $testCount';
  }
}
