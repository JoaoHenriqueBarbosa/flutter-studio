// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';
import 'change_origin.dart';

/// Data of the documentChanged event.
final class DocumentChanged {
  /// Creates the value from its fields.
  const DocumentChanged({
    required this.uri,
    required this.documentVersion,
    required this.origin,
  });

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] does not have that form.
  factory DocumentChanged.fromJson(Object? json) {
    final fields = asJson<Map<String, Object?>>(json);
    return DocumentChanged(
      uri: asJson<String>(fields['uri']),
      documentVersion: asJson<int>(fields['documentVersion']),
      origin: ChangeOrigin.fromJson(fields['origin']),
    );
  }

  /// The file URI of the document.
  final String uri;

  /// Version of the document after the change.
  final int documentVersion;

  /// Who made the change.
  final ChangeOrigin origin;

  /// Encodes the value in the form it has on the wire.
  Map<String, Object?> toJson() => {
    'uri': uri,
    'documentVersion': documentVersion,
    'origin': origin.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is DocumentChanged && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());

  @override
  String toString() => 'DocumentChanged(${toJson()})';
}
