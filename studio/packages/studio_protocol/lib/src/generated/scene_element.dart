// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';
import 'position.dart';

/// One element created in the project, in the frame on screen.
final class SceneElement {
  /// Creates the value from its fields.
  const SceneElement({
    required this.uri,
    required this.position,
    required this.parentIndex,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] does not have that form.
  factory SceneElement.fromJson(Object? json) {
    final fields = asJson<Map<String, Object?>>(json);
    return SceneElement(
      uri: asJson<String>(fields['uri']),
      position: Position.fromJson(fields['position']),
      parentIndex: asJson<int>(fields['parentIndex']),
      left: asJson<num>(fields['left']).toDouble(),
      top: asJson<num>(fields['top']).toDouble(),
      width: asJson<num>(fields['width']).toDouble(),
      height: asJson<num>(fields['height']).toDouble(),
    );
  }

  /// The file URI of the document that creates the widget of the element.
  final String uri;

  /// Position of the constructor call that creates the widget.
  final Position position;

  /// Index, in the list of the scene, of the nearest ancestor created in the
  /// project, or -1.
  final int parentIndex;

  /// Left edge of the bounds of the element on the surface, in logical pixels.
  final double left;

  /// Top edge of the bounds of the element on the surface, in logical pixels.
  final double top;

  /// Width of the bounds, in logical pixels.
  final double width;

  /// Height of the bounds, in logical pixels.
  final double height;

  /// Encodes the value in the form it has on the wire.
  Map<String, Object?> toJson() => {
    'uri': uri,
    'position': position.toJson(),
    'parentIndex': parentIndex,
    'left': left,
    'top': top,
    'width': width,
    'height': height,
  };

  @override
  bool operator ==(Object other) =>
      other is SceneElement && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());

  @override
  String toString() => 'SceneElement(${toJson()})';
}
