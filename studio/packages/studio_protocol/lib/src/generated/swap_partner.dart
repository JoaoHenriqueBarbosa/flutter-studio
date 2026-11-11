// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';

/// A neighbor of a widget in the tree.
enum SwapPartner {
  /// The value `parent`.
  parent,

  /// The value `child`.
  child;

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] is not one of the values.
  factory SwapPartner.fromJson(Object? json) {
    final name = asJson<String>(json);
    return values.asNameMap()[name] ??
        (throw FormatException('Unknown SwapPartner.', name));
  }

  /// Encodes the value in the form it has on the wire.
  String toJson() => name;
}
