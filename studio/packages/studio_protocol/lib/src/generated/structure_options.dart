// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';
import 'widget_spec.dart';

/// The structural edits that a widget accepts.
final class StructureOptions {
  /// Creates the value from its fields.
  const StructureOptions({
    required this.wrappers,
    required this.canRemove,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.canSwapWithParent,
    required this.canSwapWithChild,
  });

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] does not have that form.
  factory StructureOptions.fromJson(Object? json) {
    final fields = asJson<Map<String, Object?>>(json);
    return StructureOptions(
      wrappers: [
        for (final item in asJson<List<Object?>>(fields['wrappers']))
          WidgetSpec.fromJson(item),
      ],
      canRemove: asJson<bool>(fields['canRemove']),
      canMoveUp: asJson<bool>(fields['canMoveUp']),
      canMoveDown: asJson<bool>(fields['canMoveDown']),
      canSwapWithParent: asJson<bool>(fields['canSwapWithParent']),
      canSwapWithChild: asJson<bool>(fields['canSwapWithChild']),
    );
  }

  /// The widgets that wrapWidget accepts as wrapper.
  final List<WidgetSpec> wrappers;

  /// Whether removeWidget accepts the widget, keeping its children.
  final bool canRemove;

  /// Whether reorderWidget can move the widget up.
  final bool canMoveUp;

  /// Whether reorderWidget can move the widget down.
  final bool canMoveDown;

  /// Whether swapWidget can swap the widget with its parent.
  final bool canSwapWithParent;

  /// Whether swapWidget can swap the widget with its child.
  final bool canSwapWithChild;

  /// Encodes the value in the form it has on the wire.
  Map<String, Object?> toJson() => {
    'wrappers': [for (final item in wrappers) item.toJson()],
    'canRemove': canRemove,
    'canMoveUp': canMoveUp,
    'canMoveDown': canMoveDown,
    'canSwapWithParent': canSwapWithParent,
    'canSwapWithChild': canSwapWithChild,
  };

  @override
  bool operator ==(Object other) =>
      other is StructureOptions && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());

  @override
  String toString() => 'StructureOptions(${toJson()})';
}
