// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';

/// A direction in the list of the siblings of a widget.
enum MoveDirection {
  /// The value `up`.
  up,

  /// The value `down`.
  down;

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] is not one of the values.
  factory MoveDirection.fromJson(Object? json) {
    final name = asJson<String>(json);
    return values.asNameMap()[name] ??
        (throw FormatException('Unknown MoveDirection.', name));
  }

  /// Encodes the value in the form it has on the wire.
  String toJson() => name;
}
