// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';
import 'range.dart';

/// Replacement of the text of a range.
final class TextEdit {
  /// Creates the value from its fields.
  const TextEdit({required this.range, required this.newText});

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] does not have that form.
  factory TextEdit.fromJson(Object? json) {
    final fields = asJson<Map<String, Object?>>(json);
    return TextEdit(
      range: Range.fromJson(fields['range']),
      newText: asJson<String>(fields['newText']),
    );
  }

  /// The replaced text, in the document before the edit.
  final Range range;

  /// The text that takes the place of the range.
  final String newText;

  /// Encodes the value in the form it has on the wire.
  Map<String, Object?> toJson() => {
    'range': range.toJson(),
    'newText': newText,
  };

  @override
  bool operator ==(Object other) =>
      other is TextEdit && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());

  @override
  String toString() => 'TextEdit(${toJson()})';
}
