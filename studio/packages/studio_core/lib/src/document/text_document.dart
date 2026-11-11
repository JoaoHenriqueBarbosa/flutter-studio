import 'dart:math' as math;

import 'edit_failure.dart';
import 'text_edit.dart';

/// The text of one file at one version.
///
/// A document never changes: [applying] returns the next version.
final class TextDocument {
  /// Creates the document with [text] at [version].
  const TextDocument(this.text, {required this.version});

  /// Version of a document that was just read from disk.
  static const initialVersion = 1;

  /// Full content of the file.
  final String text;

  /// Number that grows by one at each edit applied by Studio.
  final int version;

  /// Returns the document that results from applying [edits] to this one.
  ///
  /// The ranges of [edits] refer to this text. Throws [InvalidEdit] when a
  /// range points outside the text or when two ranges overlap.
  TextDocument applying(List<TextEdit> edits) {
    final lineStarts = _lineStarts();
    final replacements = [
      for (final edit in edits)
        (
          start: _offsetOf(edit.range.start, lineStarts),
          end: _offsetOf(edit.range.end, lineStarts),
          newText: edit.newText,
        ),
    ]..sort((a, b) => b.start.compareTo(a.start));
    var result = text;
    var previousStart = text.length;
    for (final replacement in replacements) {
      if (replacement.start > replacement.end ||
          replacement.end > previousStart) {
        throw const InvalidEdit('Two ranges overlap.');
      }
      result = result.replaceRange(
        replacement.start,
        replacement.end,
        replacement.newText,
      );
      previousStart = replacement.start;
    }
    return TextDocument(result, version: version + 1);
  }

  /// Returns the offset in [text] of [position].
  ///
  /// Throws [InvalidEdit] when [position] is outside the text.
  int offsetAt(DocumentPosition position) => _offsetOf(position, _lineStarts());

  /// Returns the position of the code unit at [offset] in [text].
  DocumentPosition positionAt(int offset) => _positionOf(offset, _lineStarts());

  /// Returns the next version of this document, with [newText] as content.
  TextDocument replacing(String newText) =>
      TextDocument(newText, version: version + 1);

  /// Returns the smallest single edit that turns this text into [newText].
  ///
  /// The edit keeps the longest prefix and the longest suffix that the two
  /// texts share.
  TextEdit editTo(String newText) {
    final shorterLength = math.min(text.length, newText.length);
    var prefix = 0;
    while (prefix < shorterLength &&
        text.codeUnitAt(prefix) == newText.codeUnitAt(prefix)) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < shorterLength - prefix &&
        text.codeUnitAt(text.length - 1 - suffix) ==
            newText.codeUnitAt(newText.length - 1 - suffix)) {
      suffix++;
    }
    final lineStarts = _lineStarts();
    return (
      range: (
        start: _positionOf(prefix, lineStarts),
        end: _positionOf(text.length - suffix, lineStarts),
      ),
      newText: newText.substring(prefix, newText.length - suffix),
    );
  }

  /// Returns the offset of the first code unit of each line.
  ///
  /// A line ends at `\n`, at `\r\n` or at a lone `\r`, as in the Language
  /// Server Protocol.
  List<int> _lineStarts() {
    const lineFeed = 0x0A;
    const carriageReturn = 0x0D;
    final starts = [0];
    for (var offset = 0; offset < text.length; offset++) {
      final unit = text.codeUnitAt(offset);
      final nextIsLineFeed =
          offset + 1 < text.length && text.codeUnitAt(offset + 1) == lineFeed;
      if (unit == lineFeed || (unit == carriageReturn && !nextIsLineFeed)) {
        starts.add(offset + 1);
      }
    }
    return starts;
  }

  DocumentPosition _positionOf(int offset, List<int> lineStarts) {
    final line = lineStarts.lastIndexWhere((start) => start <= offset);
    return (line: line, character: offset - lineStarts[line]);
  }

  int _offsetOf(DocumentPosition position, List<int> lineStarts) {
    final lineStart = lineStarts.elementAtOrNull(position.line);
    final offset = (lineStart ?? text.length) + position.character;
    if (lineStart == null || position.character < 0 || offset > text.length) {
      throw InvalidEdit('Position $position is outside the text.');
    }
    return offset;
  }
}
