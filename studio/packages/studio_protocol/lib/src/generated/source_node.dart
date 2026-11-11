// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';
import 'widget_ref.dart';

/// A widget in the tree derived from the source of a file.
final class SourceNode {
  /// Creates the value from its fields.
  const SourceNode({
    required this.ref,
    required this.className,
    this.owner,
    required this.children,
  });

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] does not have that form.
  factory SourceNode.fromJson(Object? json) {
    final fields = asJson<Map<String, Object?>>(json);
    return SourceNode(
      ref: WidgetRef.fromJson(fields['ref']),
      className: asJson<String>(fields['className']),
      owner: switch (fields['owner']) {
        null => null,
        final value => asJson<String>(value),
      },
      children: [
        for (final item in asJson<List<Object?>>(fields['children']))
          SourceNode.fromJson(item),
      ],
    );
  }

  /// The creation location of the widget.
  final WidgetRef ref;

  /// Class of the widget.
  final String className;

  /// Qualified name of the declaration that creates the widget, present only in
  /// a widget that no other widget contains.
  final String? owner;

  /// The widgets created inside the arguments of this one, in source order.
  final List<SourceNode> children;

  /// Encodes the value in the form it has on the wire.
  Map<String, Object?> toJson() => {
    'ref': ref.toJson(),
    'className': className,
    'owner': ?owner,
    'children': [for (final item in children) item.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is SourceNode && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());

  @override
  String toString() => 'SourceNode(${toJson()})';
}
