// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';
import 'position.dart';

/// The creation location of a widget, in one version of the document.
final class WidgetRef {
  /// Creates the value from its fields.
  const WidgetRef({
    required this.uri,
    required this.position,
    required this.documentVersion,
  });

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] does not have that form.
  factory WidgetRef.fromJson(Object? json) {
    final fields = asJson<Map<String, Object?>>(json);
    return WidgetRef(
      uri: asJson<String>(fields['uri']),
      position: Position.fromJson(fields['position']),
      documentVersion: asJson<int>(fields['documentVersion']),
    );
  }

  /// The file URI of the document that creates the widget.
  final String uri;

  /// Position of the constructor call that creates the widget.
  final Position position;

  /// Version of the document in which the position is valid.
  final int documentVersion;

  /// Encodes the value in the form it has on the wire.
  Map<String, Object?> toJson() => {
    'uri': uri,
    'position': position.toJson(),
    'documentVersion': documentVersion,
  };

  @override
  bool operator ==(Object other) =>
      other is WidgetRef && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());

  @override
  String toString() => 'WidgetRef(${toJson()})';
}
