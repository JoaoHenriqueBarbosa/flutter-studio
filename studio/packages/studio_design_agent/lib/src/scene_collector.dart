import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:studio_protocol/studio_protocol.dart';

/// Reads from the running app the scene mirror of the frame on screen: the
/// bounds and the creation location of each element created in the project.
final class SceneCollector {
  /// Creates a collector that reads the tree of [_binding] and keeps the
  /// elements whose widgets are created in files under [_projectRootUris],
  /// which are `file:` URIs of directories, each ending with a slash.
  SceneCollector(this._binding, this._projectRootUris);

  /// Index of the parent of an element that has no ancestor in the scene.
  static const _noParent = -1;

  final WidgetsBinding _binding;

  final List<String> _projectRootUris;

  /// Where each widget seen so far is created, or `null` in the record
  /// when the widget has no creation location. A widget never changes, and
  /// reading its location from the framework is the slow part of a scene.
  final _locations = Expando<({_Location? location})>();

  /// Returns the scene of the frame that the app shows now.
  ///
  /// An element enters the scene when its widget is created in a file of
  /// the project and its render object has been laid out.
  Scene collect() {
    final view = _binding.platformDispatcher.views.first;
    final size = view.physicalSize / view.devicePixelRatio;
    final elements = <SceneElement>[];
    final root = _binding.rootElement;
    if (root != null) _visit(root, _noParent, elements);
    return Scene(
      width: size.width,
      height: size.height,
      devicePixelRatio: view.devicePixelRatio,
      elements: elements,
    );
  }

  /// Adds [element] to [elements] when it belongs to the scene, and then
  /// its descendants, in pre-order.
  void _visit(Element element, int parentIndex, List<SceneElement> elements) {
    var ownIndex = parentIndex;
    final sceneElement = _sceneElementOf(element, parentIndex);
    if (sceneElement != null) {
      ownIndex = elements.length;
      elements.add(sceneElement);
    }
    element.visitChildren((child) => _visit(child, ownIndex, elements));
  }

  SceneElement? _sceneElementOf(Element element, int parentIndex) {
    final location = _creationLocationOf(element);
    if (location == null || !_projectRootUris.any(location.uri.startsWith)) {
      return null;
    }
    final renderObject = element.findRenderObject();
    final bounds = _boundsOf(renderObject);
    if (bounds == null) return null;
    return SceneElement(
      className: '${element.widget.runtimeType}',
      uri: location.uri,
      position: location.position,
      parentIndex: parentIndex,
      left: bounds.left,
      top: bounds.top,
      width: bounds.width,
      height: bounds.height,
      layout: _layoutOf(renderObject),
    );
  }

  /// Returns the constraints and the flex data of [renderObject], or `null`
  /// when it is not a box.
  ///
  /// Both are read from the description that the render object gives of
  /// itself for diagnostics, where they are public.
  LayoutInfo? _layoutOf(RenderObject? renderObject) {
    if (renderObject is! RenderBox) return null;
    final properties = renderObject.toDiagnosticsNode().getProperties();
    final values = [
      for (final property in properties)
        if (property is DiagnosticsProperty<Object?>) property.value,
    ];
    final constraints = values.whereType<BoxConstraints>().firstOrNull;
    if (constraints == null) return null;
    final flexData = values.whereType<FlexParentData>().firstOrNull;
    return LayoutInfo(
      minWidth: constraints.minWidth,
      maxWidth: constraints.hasBoundedWidth ? constraints.maxWidth : null,
      minHeight: constraints.minHeight,
      maxHeight: constraints.hasBoundedHeight ? constraints.maxHeight : null,
      flex: flexData?.flex,
      fit: switch (flexData?.fit) {
        FlexFit.tight => FlexFitKind.tight,
        FlexFit.loose => FlexFitKind.loose,
        null => null,
      },
    );
  }

  /// Returns the bounds of [renderObject] on the surface, or `null` while
  /// it is not attached or not laid out.
  Rect? _boundsOf(RenderObject? renderObject) {
    if (renderObject == null || !renderObject.attached) return null;
    if (renderObject is RenderBox && !renderObject.hasSize) return null;
    return MatrixUtils.transformRect(
      renderObject.getTransformTo(null),
      renderObject.paintBounds,
    );
  }

  /// Returns where the widget of [element] is created, or `null` when the
  /// app was built without the tracking of widget creation.
  _Location? _creationLocationOf(Element element) {
    final known = _locations[element.widget];
    if (known != null) return known.location;
    final location = _readCreationLocation(element);
    _locations[element.widget] = (location: location);
    return location;
  }

  /// Reads the creation location from the description that the framework
  /// serializes for the inspector, the only place where it is public. The
  /// framework counts lines and columns from one.
  _Location? _readCreationLocation(Element element) {
    final description = element.toDiagnosticsNode().toJsonMap(
      InspectorSerializationDelegate(
        service: WidgetInspectorService.instance,
        subtreeDepth: 0,
      ),
    );
    if (description['creationLocation'] case {
      'file': final String file,
      'line': final int line,
      'column': final int column,
    }) {
      return (
        uri: file,
        position: Position(line: line - 1, character: column - 1),
      );
    }
    return null;
  }
}

/// Where a widget is created, with the line and the character counted from
/// zero.
typedef _Location = ({String uri, Position position});
