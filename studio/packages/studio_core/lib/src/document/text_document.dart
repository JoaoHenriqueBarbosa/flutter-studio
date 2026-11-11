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
  /// The ranges of [edits] refer to this text. Throws a [RangeError] when a
  /// range points outside the text, and an [ArgumentError] when two ranges
  /// overlap.
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
        throw ArgumentError.value(edits, 'edits', 'Ranges overlap.');
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

  int _offsetOf(DocumentPosition position, List<int> lineStarts) {
    RangeError.checkValidIndex(position.line, lineStarts, 'line');
    final offset = lineStarts[position.line] + position.character;
    RangeError.checkValueInInterval(offset, 0, text.length, 'character');
    return offset;
  }
}
