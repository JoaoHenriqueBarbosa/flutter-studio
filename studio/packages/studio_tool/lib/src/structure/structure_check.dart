import 'dart:io';

/// One verification of the structure of the own code, part of step QG-08
/// of the quality gate.
abstract interface class StructureCheck {
  /// Returns one line for each violation found under [workspace], the root
  /// of the pub workspace of Studio.
  ///
  /// Throws a [FileSystemException] when the workspace cannot be read.
  List<String> problemsIn(Directory workspace);
}
