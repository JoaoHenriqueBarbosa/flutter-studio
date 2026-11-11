import '../lsp/editable_argument.dart';

/// Converts the value of an argument between the Dart source of a literal
/// and the value that the analysis server exchanges for it.
///
/// The server edits arguments of five kinds, and for each one it takes the
/// value, not the source. An expression that is not a literal of the kind
/// has no value to give to the server.
final class ArgumentLiteral {
  /// Creates the converter for arguments of [_kind], one of the kinds of
  /// [EditableArgument.kind].
  const ArgumentLiteral(this._kind);

  static const _nullSource = 'null';

  /// What each escape of a string literal stands for.
  static const _escapes = {
    'n': '\n',
    'r': '\r',
    't': '\t',
    r'\': r'\',
    "'": "'",
    '"': '"',
    r'$': r'$',
  };

  static final _enumConstant = RegExp(
    r'^[A-Za-z_$][\w$]*(\.[A-Za-z_$][\w$]*)+$',
  );

  final String _kind;

  /// Returns the Dart source of [value], a value of the kind as the server
  /// gives it.
  String sourceOf(Object? value) => switch (value) {
    final String text when _kind == EditableArgument.stringKind => _quote(text),
    _ => '$value',
  };

  /// Returns the value that the server takes for the literal written in
  /// [source].
  ///
  /// Throws a [FormatException] when [source] is not a literal of the kind.
  Object? valueOf(String source) {
    final trimmed = source.trim();
    if (trimmed == _nullSource) return null;
    final value = switch (_kind) {
      EditableArgument.stringKind => _unquote(trimmed),
      EditableArgument.intKind => int.tryParse(trimmed),
      EditableArgument.doubleKind => double.tryParse(trimmed),
      EditableArgument.boolKind => bool.tryParse(trimmed),
      EditableArgument.enumKind =>
        _enumConstant.hasMatch(trimmed) ? trimmed : null,
      _ => null,
    };
    if (value != null) return value;
    throw FormatException('Not a literal of kind $_kind.', source);
  }

  String _quote(String text) {
    final escaped = text
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll(r'$', r'\$')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll('\t', r'\t');
    return "'$escaped'";
  }

  /// Returns the text of the single-line string literal in [source], or
  /// `null` when [source] is something else: an interpolation, adjacent
  /// strings, a multi-line string or another expression.
  String? _unquote(String source) {
    final isRaw = source.startsWith('r');
    final literal = isRaw ? source.substring(1) : source;
    const quoteCount = 2;
    if (literal.length < quoteCount) return null;
    final quote = literal[0];
    if ((quote != "'" && quote != '"') || !literal.endsWith(quote)) {
      return null;
    }
    final body = literal.substring(1, literal.length - 1);
    return isRaw
        ? (body.contains(quote) ? null : body)
        : _unescape(body, quote);
  }

  String? _unescape(String body, String quote) {
    final text = StringBuffer();
    for (var index = 0; index < body.length; index++) {
      final character = body[index];
      if (character == quote || character == r'$') return null;
      if (character != r'\') {
        text.write(character);
        continue;
      }
      index++;
      final replacement = index < body.length ? _escapes[body[index]] : null;
      if (replacement == null) return null;
      text.write(replacement);
    }
    return '$text';
  }
}
