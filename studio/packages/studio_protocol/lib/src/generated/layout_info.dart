// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';
import 'flex_fit_kind.dart';

/// The layout data of a widget in the running app.
final class LayoutInfo {
  /// Creates the value from its fields.
  const LayoutInfo({
    required this.minWidth,
    this.maxWidth,
    required this.minHeight,
    this.maxHeight,
    this.flex,
    this.fit,
  });

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] does not have that form.
  factory LayoutInfo.fromJson(Object? json) {
    final fields = asJson<Map<String, Object?>>(json);
    return LayoutInfo(
      minWidth: asJson<num>(fields['minWidth']).toDouble(),
      maxWidth: switch (fields['maxWidth']) {
        null => null,
        final value => asJson<num>(value).toDouble(),
      },
      minHeight: asJson<num>(fields['minHeight']).toDouble(),
      maxHeight: switch (fields['maxHeight']) {
        null => null,
        final value => asJson<num>(value).toDouble(),
      },
      flex: switch (fields['flex']) {
        null => null,
        final value => asJson<int>(value),
      },
      fit: switch (fields['fit']) {
        null => null,
        final value => FlexFitKind.fromJson(value),
      },
    );
  }

  /// Smallest width that the parent allows, in logical pixels.
  final double minWidth;

  /// Largest width that the parent allows, absent when the width is unbounded.
  final double? maxWidth;

  /// Smallest height that the parent allows, in logical pixels.
  final double minHeight;

  /// Largest height that the parent allows, absent when the height is
  /// unbounded.
  final double? maxHeight;

  /// The flex factor of the widget, present when its parent is a flex layout
  /// and gives it one.
  final int? flex;

  /// The flex fit of the widget, present when its parent is a flex layout.
  final FlexFitKind? fit;

  /// Encodes the value in the form it has on the wire.
  Map<String, Object?> toJson() => {
    'minWidth': minWidth,
    'maxWidth': ?maxWidth,
    'minHeight': minHeight,
    'maxHeight': ?maxHeight,
    'flex': ?flex,
    if (fit case final fit?) 'fit': fit.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is LayoutInfo && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());

  @override
  String toString() => 'LayoutInfo(${toJson()})';
}
