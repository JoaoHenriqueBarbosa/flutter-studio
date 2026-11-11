// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';

/// A widget to create, named by its class.
final class WidgetSpec {
  /// Creates the value from its fields.
  const WidgetSpec({required this.libraryUri, required this.className});

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] does not have that form.
  factory WidgetSpec.fromJson(Object? json) {
    final fields = asJson<Map<String, Object?>>(json);
    return WidgetSpec(
      libraryUri: asJson<String>(fields['libraryUri']),
      className: asJson<String>(fields['className']),
    );
  }

  /// The URI of the library that exports the class.
  final String libraryUri;

  /// Name of the widget class.
  final String className;

  /// Encodes the value in the form it has on the wire.
  Map<String, Object?> toJson() => {
    'libraryUri': libraryUri,
    'className': className,
  };

  @override
  bool operator ==(Object other) =>
      other is WidgetSpec && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());

  @override
  String toString() => 'WidgetSpec(${toJson()})';
}
