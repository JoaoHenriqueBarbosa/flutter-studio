// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';
import 'bounds.dart';
import 'widget_ref.dart';

/// A widget of the project in the tree of the running app.
final class RuntimeNode {
  /// Creates the value from its fields.
  const RuntimeNode({
    required this.className,
    required this.ref,
    required this.bounds,
    required this.children,
  });

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] does not have that form.
  factory RuntimeNode.fromJson(Object? json) {
    final fields = asJson<Map<String, Object?>>(json);
    return RuntimeNode(
      className: asJson<String>(fields['className']),
      ref: WidgetRef.fromJson(fields['ref']),
      bounds: Bounds.fromJson(fields['bounds']),
      children: [
        for (final item in asJson<List<Object?>>(fields['children']))
          RuntimeNode.fromJson(item),
      ],
    );
  }

  /// Class of the widget.
  final String className;

  /// The creation location of the widget, in the current version of its
  /// document.
  final WidgetRef ref;

  /// Where the widget is on the surface.
  final Bounds bounds;

  /// The nearest descendants created in the project, in tree order.
  final List<RuntimeNode> children;

  /// Encodes the value in the form it has on the wire.
  Map<String, Object?> toJson() => {
    'className': className,
    'ref': ref.toJson(),
    'bounds': bounds.toJson(),
    'children': [for (final item in children) item.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is RuntimeNode && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());

  @override
  String toString() => 'RuntimeNode(${toJson()})';
}
