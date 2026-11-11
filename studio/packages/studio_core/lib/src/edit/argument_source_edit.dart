import '../document/edit_failure.dart';
import '../document/text_document.dart';
import '../document/text_edit.dart';

/// Edits the source of one argument of a constructor call, from the range
/// of its value.
///
/// It covers what the analysis server does not: an expression that is not
/// a literal, and the removal of an argument. It works on the text, so it
/// is replaced by the edit engine when the engine exists (ADR-0006).
final class ArgumentSourceEdit {
  /// Creates the editor of the arguments in [_document].
  const ArgumentSourceEdit(this._document);

  static const _comma = ',';

  static const _colon = ':';

  static const _lineFeed = '\n';

  static final _identifierCharacter = RegExp(r'[\w$]');

  static final _inlineSpace = RegExp('[ \t]');

  static final _anySpace = RegExp(r'\s');

  final TextDocument _document;

  String get _text => _document.text;

  /// Returns the edit that puts [source] in place of the value at
  /// [valueRange].
  TextEdit replacingValue(DocumentRange valueRange, String source) =>
      (range: valueRange, newText: source);

  /// Returns the edit that removes the named argument whose value is at
  /// [valueRange], with its name and one of the commas beside it.
  ///
  /// An argument that is alone on its line takes the line with it. Throws
  /// [UnsupportedEdit] when the argument is positional.
  TextEdit removingArgument(DocumentRange valueRange) {
    final valueStart = _document.offsetAt(valueRange.start);
    final valueEnd = _document.offsetAt(valueRange.end);
    final nameStart = _nameStartBefore(valueStart);
    final afterValue = _skipForward(valueEnd, _anySpace);
    final hasCommaAfter =
        afterValue < _text.length && _text[afterValue] == _comma;
    final (start, end) = hasCommaAfter
        ? _withLineOrSpace(nameStart, afterValue + 1)
        : (_commaBefore(nameStart) ?? nameStart, valueEnd);
    return (
      range: (
        start: _document.positionAt(start),
        end: _document.positionAt(end),
      ),
      newText: '',
    );
  }

  /// Returns where the name of the argument starts, given where its value
  /// does.
  int _nameStartBefore(int valueStart) {
    final colon = _skipBackward(valueStart, _anySpace) - 1;
    if (colon < 0 || _text[colon] != _colon) {
      throw const UnsupportedEdit('A positional argument cannot be removed.');
    }
    final nameEnd = _skipBackward(colon, _anySpace);
    return _skipBackward(nameEnd, _identifierCharacter);
  }

  /// Widens the span from [start] to [end], which ends after a comma: to
  /// the whole line when nothing else is on it, and otherwise over the
  /// spaces that follow the comma.
  (int, int) _withLineOrSpace(int start, int end) {
    final lineStart = _skipBackward(start, _inlineSpace);
    final lineEnd = _skipForward(end, _inlineSpace);
    final startsLine = lineStart == 0 || _text[lineStart - 1] == _lineFeed;
    final endsLine = lineEnd < _text.length && _text[lineEnd] == _lineFeed;
    return startsLine && endsLine ? (lineStart, lineEnd + 1) : (start, lineEnd);
  }

  /// Returns the offset of the comma that comes before [offset], with only
  /// white space between the two, or `null` when there is none.
  int? _commaBefore(int offset) {
    final comma = _skipBackward(offset, _anySpace) - 1;
    return comma >= 0 && _text[comma] == _comma ? comma : null;
  }

  int _skipForward(int offset, RegExp characters) {
    var index = offset;
    while (index < _text.length && characters.hasMatch(_text[index])) {
      index++;
    }
    return index;
  }

  int _skipBackward(int offset, RegExp characters) {
    var index = offset;
    while (index > 0 && characters.hasMatch(_text[index - 1])) {
      index--;
    }
    return index;
  }
}
