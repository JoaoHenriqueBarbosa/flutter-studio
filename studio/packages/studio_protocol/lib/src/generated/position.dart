// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';

/// A position in a document, as the Language Server Protocol counts it.
final class Position {
  /// Creates the value from its fields.
  const Position({required this.line, required this.character});

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] does not have that form.
  factory Position.fromJson(Object? json) {
    final fields = asJson<Map<String, Object?>>(json);
    return Position(
      line: asJson<int>(fields['line']),
      character: asJson<int>(fields['character']),
    );
  }

  /// Line of the position, starting at zero.
  final int line;

  /// Offset in UTF-16 code units from the start of the line, starting at zero.
  final int character;

  /// Encodes the value in the form it has on the wire.
  Map<String, Object?> toJson() => {'line': line, 'character': character};

  @override
  bool operator ==(Object other) =>
      other is Position && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());

  @override
  String toString() => 'Position(${toJson()})';
}
