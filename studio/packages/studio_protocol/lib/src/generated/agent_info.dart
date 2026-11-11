// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';

/// What the design agent tells about itself.
final class AgentInfo {
  /// Creates the value from its fields.
  const AgentInfo({required this.protocolVersion});

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] does not have that form.
  factory AgentInfo.fromJson(Object? json) {
    final fields = asJson<Map<String, Object?>>(json);
    return AgentInfo(protocolVersion: asJson<int>(fields['protocolVersion']));
  }

  /// Version of the protocol between the shell and the agent.
  final int protocolVersion;

  /// Encodes the value in the form it has on the wire.
  Map<String, Object?> toJson() => {'protocolVersion': protocolVersion};

  @override
  bool operator ==(Object other) =>
      other is AgentInfo && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());

  @override
  String toString() => 'AgentInfo(${toJson()})';
}
