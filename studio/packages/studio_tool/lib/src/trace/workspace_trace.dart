import 'dart:io';

import 'package:path/path.dart' as path;

import 'identifier_catalog.dart';
import 'test_trace.dart';
import 'trace_report.dart';

/// Builds the trace report of a workspace of Studio from its files.
final class WorkspaceTrace {
  /// Creates the reader.
  const WorkspaceTrace();

  /// File of the workspace that names the increment under construction.
  static const _incrementFile = 'current-increment.txt';

  /// Where the documents of the system are, relative to the workspace.
  static const _docsPath = '../docs';

  /// Reads the documents, the tests and the current increment of
  /// [workspace].
  ///
  /// Throws a [FileSystemException] when a part is missing.
  TraceReport read(Directory workspace) => TraceReport(
    IdentifierCatalog.read(Directory(path.join(workspace.path, _docsPath))),
    TestTrace.read(workspace),
    currentIncrement: File(path.join(workspace.path, _incrementFile))
        .readAsStringSync()
        .trim(),
  );
}
