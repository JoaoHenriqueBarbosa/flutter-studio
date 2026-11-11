import 'dart:io';

import 'package:path/path.dart' as path;

import 'identifier_catalog.dart';

/// What the tests of the workspace declare to verify, in their
/// `// Verifies:` comments (guide, section "Rastreabilidade").
final class TestTrace {
  const TestTrace._(this.testsByIdentifier);

  /// Reads the comments of every test file under the packages of
  /// [workspace]. A comment may continue on the comment lines that follow
  /// it, as long as they hold only identifiers.
  factory TestTrace.read(Directory workspace) {
    final testsByIdentifier = <String, Set<String>>{};
    final packages = Directory(path.join(workspace.path, 'packages'));
    final files = packages
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('_test.dart'));
    for (final file in files) {
      final relativePath = path.relative(file.path, from: workspace.path);
      for (final id in _identifiersIn(file.readAsLinesSync())) {
        testsByIdentifier.putIfAbsent(id, () => {}).add(relativePath);
      }
    }
    return TestTrace._(testsByIdentifier);
  }

  static final _marker = RegExp(r'^\s*// Verifies:(.*)$');

  static final _continuation = RegExp(
    '^\\s*//((?:\\s*${IdentifierCatalog.identifierPattern},?)+)\\s*\$',
  );

  static final _word = RegExp(r'[\w-]+');

  /// The test files that verify each identifier, by identifier. The paths
  /// are relative to the workspace.
  final Map<String, Set<String>> testsByIdentifier;

  static Iterable<String> _identifiersIn(List<String> lines) sync* {
    var isInsideMarker = false;
    for (final line in lines) {
      final listed =
          _marker.firstMatch(line)?.group(1) ??
          (isInsideMarker ? _continuation.firstMatch(line)?.group(1) : null);
      isInsideMarker = listed != null;
      if (listed != null) {
        yield* _word.allMatches(listed).map((match) => match.group(0) ?? '');
      }
    }
  }
}
