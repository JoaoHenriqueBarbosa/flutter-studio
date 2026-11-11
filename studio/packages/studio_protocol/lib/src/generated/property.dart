// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';
import 'expression.dart';

/// One parameter of the constructor that creates a widget.
final class Property {
  /// Creates the value from its fields.
  const Property({
    required this.name,
    required this.type,
    this.expression,
    this.defaultValue,
    required this.isSet,
    required this.isEditable,
    this.options,
    this.documentation,
  });

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] does not have that form.
  factory Property.fromJson(Object? json) {
    final fields = asJson<Map<String, Object?>>(json);
    return Property(
      name: asJson<String>(fields['name']),
      type: asJson<String>(fields['type']),
      expression: switch (fields['expression']) {
        null => null,
        final value => Expression.fromJson(value),
      },
      defaultValue: switch (fields['defaultValue']) {
        null => null,
        final value => Expression.fromJson(value),
      },
      isSet: asJson<bool>(fields['isSet']),
      isEditable: asJson<bool>(fields['isEditable']),
      options: switch (fields['options']) {
        null => null,
        final value => [
          for (final item in asJson<List<Object?>>(value)) asJson<String>(item),
        ],
      },
      documentation: switch (fields['documentation']) {
        null => null,
        final value => asJson<String>(value),
      },
    );
  }

  /// Name of the parameter.
  final String name;

  /// Kind of value, as the analysis server names it: string, int, double, bool,
  /// enum, or another name for a value that is not editable as a literal.
  final String type;

  /// The argument in the code, absent when no argument is given.
  final Expression? expression;

  /// The default value of the parameter, absent when it has none.
  final Expression? defaultValue;

  /// Whether the code gives an argument for the parameter.
  final bool isSet;

  /// Whether setProperty accepts the parameter.
  final bool isEditable;

  /// The values that an enum parameter accepts, absent for the other kinds.
  final List<String>? options;

  /// Documentation of the parameter, absent when it has none.
  final String? documentation;

  /// Encodes the value in the form it has on the wire.
  Map<String, Object?> toJson() => {
    'name': name,
    'type': type,
    if (expression case final expression?) 'expression': expression.toJson(),
    if (defaultValue case final defaultValue?)
      'defaultValue': defaultValue.toJson(),
    'isSet': isSet,
    'isEditable': isEditable,
    'options': ?options,
    'documentation': ?documentation,
  };

  @override
  bool operator ==(Object other) =>
      other is Property && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());

  @override
  String toString() => 'Property(${toJson()})';
}
