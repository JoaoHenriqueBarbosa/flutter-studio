import 'dart:io';

import 'requirement.dart';

/// The identifiers that the documents of the system define, and the
/// requirements among them.
///
/// An identifier is defined where it opens a row of a table, alone or as
/// the text of a link.
final class IdentifierCatalog {
  const IdentifierCatalog._(this.identifiers, this.requirements);

  /// Reads the catalog from the Markdown files under [docsDirectory].
  factory IdentifierCatalog.read(Directory docsDirectory) {
    final identifiers = <String>{};
    final requirements = <Requirement>[];
    final files = docsDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.md'));
    for (final file in files) {
      for (final line in file.readAsLinesSync()) {
        final id = _definition.firstMatch(line)?.group(1);
        if (id == null) continue;
        identifiers.add(id);
        final requirement = _requirementFrom(id, line);
        if (requirement != null) requirements.add(requirement);
      }
    }
    return IdentifierCatalog._(identifiers, requirements);
  }

  /// The forms of the identifiers of the guide, section "Identificadores".
  static const identifierPattern =
      r'(?:(?:FR|NFR|CS)-[A-Z]+-\d{3}|ADR-\d{4}|(?:IR|WVR)-\d{3}'
      r'|(?:DC|ASM|QS|RSK|IF|ORC|QG)-\d{2})';

  static final _definition = RegExp('^\\|\\s*\\[?($identifierPattern)\\]?');

  static final _increment = RegExp(r'^F\d$');

  /// Letter of the verification method that is an automated test.
  static const _testMethod = 'T';

  /// Every identifier that some document defines.
  final Set<String> identifiers;

  /// The requirements that have an increment and a verification method.
  final List<Requirement> requirements;

  /// Returns the requirement in a table row of the SRS, whose last two
  /// cells are the increments and the verification methods, or `null` when
  /// [line] is another kind of row.
  static Requirement? _requirementFrom(String id, String line) {
    final cells = [for (final cell in line.split('|')) cell.trim()]
      ..removeWhere((cell) => cell.isEmpty);
    const minimumCellCount = 4;
    if (cells.length < minimumCellCount) return null;
    final increments = cells[cells.length - 2]
        .split(',')
        .map((it) => it.trim());
    if (!increments.every(_increment.hasMatch)) return null;
    return (
      id: id,
      increment: increments.first,
      isTested: cells.last.split(',').any((it) => it.trim() == _testMethod),
    );
  }
}
