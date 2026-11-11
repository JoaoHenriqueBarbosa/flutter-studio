// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';

/// The version of the contract of the Studio service.
final class VersionInfo {
  /// Creates the value from its fields.
  const VersionInfo({required this.version});

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] does not have that form.
  factory VersionInfo.fromJson(Object? json) {
    final fields = asJson<Map<String, Object?>>(json);
    return VersionInfo(version: asJson<String>(fields['version']));
  }

  /// Semantic version of the contract.
  final String version;

  /// Encodes the value in the form it has on the wire.
  Map<String, Object?> toJson() => {'version': version};

  @override
  bool operator ==(Object other) =>
      other is VersionInfo && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());

  @override
  String toString() => 'VersionInfo(${toJson()})';
}
