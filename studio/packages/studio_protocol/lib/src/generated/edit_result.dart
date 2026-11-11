// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';
import 'reload_kind.dart';
import 'text_document_edit.dart';

/// The result of an edit operation.
final class EditResult {
  /// Creates the value from its fields.
  const EditResult({
    required this.applied,
    required this.changes,
    required this.documentVersions,
    required this.reload,
  });

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] does not have that form.
  factory EditResult.fromJson(Object? json) {
    final fields = asJson<Map<String, Object?>>(json);
    return EditResult(
      applied: asJson<bool>(fields['applied']),
      changes: [
        for (final item in asJson<List<Object?>>(fields['changes']))
          TextDocumentEdit.fromJson(item),
      ],
      documentVersions: {
        for (final MapEntry(:key, :value) in asJson<Map<String, Object?>>(
          fields['documentVersions'],
        ).entries)
          key: asJson<int>(value),
      },
      reload: ReloadKind.fromJson(fields['reload']),
    );
  }

  /// Whether any file changed.
  final bool applied;

  /// The edits made, one entry for each changed document.
  final List<TextDocumentEdit> changes;

  /// Version of each changed document after the edit, by file URI.
  final Map<String, int> documentVersions;

  /// The reload that was requested from the running app.
  final ReloadKind reload;

  /// Encodes the value in the form it has on the wire.
  Map<String, Object?> toJson() => {
    'applied': applied,
    'changes': [for (final item in changes) item.toJson()],
    'documentVersions': documentVersions,
    'reload': reload.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is EditResult && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());

  @override
  String toString() => 'EditResult(${toJson()})';
}
