// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';

/// How the running app was asked to pick up an edit.
enum ReloadKind {
  /// The value `hotReload`.
  hotReload,

  /// The value `hotRestart`.
  hotRestart,

  /// The value `none`.
  none;

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] is not one of the values.
  factory ReloadKind.fromJson(Object? json) {
    final name = asJson<String>(json);
    return values.asNameMap()[name] ??
        (throw FormatException('Unknown ReloadKind.', name));
  }

  /// Encodes the value in the form it has on the wire.
  String toJson() => name;
}
