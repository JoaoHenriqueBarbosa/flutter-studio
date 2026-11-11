// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';

/// A rectangle on the surface of the app, in logical pixels.
final class Bounds {
  /// Creates the value from its fields.
  const Bounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] does not have that form.
  factory Bounds.fromJson(Object? json) {
    final fields = asJson<Map<String, Object?>>(json);
    return Bounds(
      left: asJson<num>(fields['left']).toDouble(),
      top: asJson<num>(fields['top']).toDouble(),
      width: asJson<num>(fields['width']).toDouble(),
      height: asJson<num>(fields['height']).toDouble(),
    );
  }

  /// Left edge.
  final double left;

  /// Top edge.
  final double top;

  /// Width.
  final double width;

  /// Height.
  final double height;

  /// Encodes the value in the form it has on the wire.
  Map<String, Object?> toJson() => {
    'left': left,
    'top': top,
    'width': width,
    'height': height,
  };

  @override
  bool operator ==(Object other) =>
      other is Bounds && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());

  @override
  String toString() => 'Bounds(${toJson()})';
}
