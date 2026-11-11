// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';
import 'scene_element.dart';

/// The scene mirror of one frame, in the JSON form of the first version of the
/// agent.
final class Scene {
  /// Creates the value from its fields.
  const Scene({
    required this.width,
    required this.height,
    required this.devicePixelRatio,
    required this.elements,
  });

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] does not have that form.
  factory Scene.fromJson(Object? json) {
    final fields = asJson<Map<String, Object?>>(json);
    return Scene(
      width: asJson<num>(fields['width']).toDouble(),
      height: asJson<num>(fields['height']).toDouble(),
      devicePixelRatio: asJson<num>(fields['devicePixelRatio']).toDouble(),
      elements: [
        for (final item in asJson<List<Object?>>(fields['elements']))
          SceneElement.fromJson(item),
      ],
    );
  }

  /// Width of the surface, in logical pixels.
  final double width;

  /// Height of the surface, in logical pixels.
  final double height;

  /// Physical pixels of a frame for each logical pixel.
  final double devicePixelRatio;

  /// The elements created in the project, in the pre-order of the tree.
  final List<SceneElement> elements;

  /// Encodes the value in the form it has on the wire.
  Map<String, Object?> toJson() => {
    'width': width,
    'height': height,
    'devicePixelRatio': devicePixelRatio,
    'elements': [for (final item in elements) item.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is Scene && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());

  @override
  String toString() => 'Scene(${toJson()})';
}
