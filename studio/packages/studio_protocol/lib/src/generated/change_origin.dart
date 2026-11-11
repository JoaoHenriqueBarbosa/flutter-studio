// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';

/// Who changed a document.
enum ChangeOrigin {
  /// The value `studio`.
  studio,

  /// The value `external`.
  external;

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] is not one of the values.
  factory ChangeOrigin.fromJson(Object? json) {
    final name = asJson<String>(json);
    return values.asNameMap()[name] ??
        (throw FormatException('Unknown ChangeOrigin.', name));
  }

  /// Encodes the value in the form it has on the wire.
  String toJson() => name;
}
