// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';

/// How a child of a flex layout fills the space given to it.
enum FlexFitKind {
  /// The value `tight`.
  tight,

  /// The value `loose`.
  loose;

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] is not one of the values.
  factory FlexFitKind.fromJson(Object? json) {
    final name = asJson<String>(json);
    return values.asNameMap()[name] ??
        (throw FormatException('Unknown FlexFitKind.', name));
  }

  /// Encodes the value in the form it has on the wire.
  String toJson() => name;
}
