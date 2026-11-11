// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';
import 'text_edit.dart';

/// The edits made to one document.
final class TextDocumentEdit {
  /// Creates the value from its fields.
  const TextDocumentEdit({required this.uri, required this.edits});

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] does not have that form.
  factory TextDocumentEdit.fromJson(Object? json) {
    final fields = asJson<Map<String, Object?>>(json);
    return TextDocumentEdit(
      uri: asJson<String>(fields['uri']),
      edits: [
        for (final item in asJson<List<Object?>>(fields['edits']))
          TextEdit.fromJson(item),
      ],
    );
  }

  /// The file URI of the document.
  final String uri;

  /// The edits, with ranges that refer to the document before any of them.
  final List<TextEdit> edits;

  /// Encodes the value in the form it has on the wire.
  Map<String, Object?> toJson() => {
    'uri': uri,
    'edits': [for (final item in edits) item.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is TextDocumentEdit && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());

  @override
  String toString() => 'TextDocumentEdit(${toJson()})';
}
