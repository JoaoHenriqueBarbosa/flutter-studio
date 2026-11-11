// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';
import 'widget_ref.dart';

/// Data of the selectionChanged event.
final class SelectionChanged {
  /// Creates the value from its fields.
  const SelectionChanged({this.selection});

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] does not have that form.
  factory SelectionChanged.fromJson(Object? json) {
    final fields = asJson<Map<String, Object?>>(json);
    return SelectionChanged(
      selection: switch (fields['selection']) {
        null => null,
        final value => WidgetRef.fromJson(value),
      },
    );
  }

  /// The selected widget, absent when nothing is selected.
  final WidgetRef? selection;

  /// Encodes the value in the form it has on the wire.
  Map<String, Object?> toJson() => {
    if (selection case final selection?) 'selection': selection.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is SelectionChanged && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());

  @override
  String toString() => 'SelectionChanged(${toJson()})';
}
