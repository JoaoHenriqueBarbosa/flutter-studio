// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';
import 'position.dart';

/// The text between two positions of a document.
final class Range {
  /// Creates the value from its fields.
  const Range({required this.start, required this.end});

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] does not have that form.
  factory Range.fromJson(Object? json) {
    final fields = asJson<Map<String, Object?>>(json);
    return Range(
      start: Position.fromJson(fields['start']),
      end: Position.fromJson(fields['end']),
    );
  }

  /// First position of the range.
  final Position start;

  /// Position after the last one of the range.
  final Position end;

  /// Encodes the value in the form it has on the wire.
  Map<String, Object?> toJson() => {
    'start': start.toJson(),
    'end': end.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is Range && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());

  @override
  String toString() => 'Range(${toJson()})';
}
