import 'package:path/path.dart' as path;
import 'package:studio_protocol/studio_protocol.dart';

import '../document/source_location.dart';

/// Answers questions about where the elements of a scene are: which one is
/// under a point, and which ones a location creates.
///
/// The shell answers them from the scene of the frame on screen, without
/// asking the app (FR-CNV-006).
final class SceneGeometry {
  /// Creates the geometry of [_scene].
  const SceneGeometry(this._scene);

  final Scene _scene;

  /// Returns the creation location of the element under the point
  /// ([x], [y]) of the surface, in logical pixels, or `null` when the point
  /// is over no element of the project.
  ///
  /// The scene is in pre-order, so the last element that contains the point
  /// is the deepest one, and the one painted last among overlapping ones.
  SourceLocation? locationAt(double x, double y) {
    final hit = _scene.elements
        .where(
          (element) =>
              x >= element.left &&
              x < element.left + element.width &&
              y >= element.top &&
              y < element.top + element.height,
        )
        .lastOrNull;
    if (hit == null) return null;
    return (
      filePath: Uri.parse(hit.uri).toFilePath(),
      position: (line: hit.position.line, character: hit.position.character),
    );
  }

  /// Returns the elements whose widget is created at [location]. There is
  /// more than one when the code at that location runs more than once,
  /// as in the builder of a list.
  List<SceneElement> elementsCreatedAt(SourceLocation location) {
    final uri = '${Uri.file(path.normalize(location.filePath))}';
    return [
      for (final element in _scene.elements)
        if (element.uri == uri &&
            element.position.line == location.position.line &&
            element.position.character == location.position.character)
          element,
    ];
  }
}
