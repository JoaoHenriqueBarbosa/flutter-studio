/// The Dart type of a JSON Schema of the contract, with the code that
/// converts a value of the type from and to JSON.
///
/// Only the subset of JSON Schema that the contract uses is supported.
sealed class SchemaType {
  const SchemaType();

  /// Reads the type that [schema] describes.
  ///
  /// Throws a [FormatException] for a schema outside the supported subset.
  factory SchemaType.parse(Object? schema) => switch (schema) {
    {r'$ref': final String reference} => ReferenceType(
      reference.split('/').last,
    ),
    {'oneOf': [final Object? inner, {'type': 'null'}]} => NullableType(
      SchemaType.parse(inner),
    ),
    {'type': 'string'} => const PrimitiveType('String'),
    {'type': 'integer'} => const PrimitiveType('int'),
    {'type': 'boolean'} => const PrimitiveType('bool'),
    {'type': 'number'} => const NumberType(),
    {'type': 'array', 'items': final Object? items} => ListType(
      SchemaType.parse(items),
    ),
    {'type': 'object', 'additionalProperties': final Object? values} => MapType(
      SchemaType.parse(values),
    ),
    _ => throw FormatException('Unsupported schema.', schema),
  };

  /// The type as written in Dart code.
  String get dartType;

  /// Whether a value of the type is already its own JSON form.
  bool get isJsonValue;

  /// Names of the contract schemas that the type mentions.
  Iterable<String> get references;

  /// Returns the Dart expression that decodes the JSON value produced by
  /// [expression].
  String decode(String expression);

  /// Returns the Dart expression that encodes as JSON the value produced by
  /// [expression].
  String encode(String expression);

  /// This type, accepting `null` as well.
  SchemaType get nullable => NullableType(this);
}

/// A JSON string, integer or boolean, which Dart reads without conversion.
final class PrimitiveType extends SchemaType {
  /// Creates the type that Dart names [dartType].
  const PrimitiveType(this.dartType);

  @override
  final String dartType;

  @override
  bool get isJsonValue => true;

  @override
  Iterable<String> get references => const [];

  @override
  String decode(String expression) => 'asJson<$dartType>($expression)';

  @override
  String encode(String expression) => expression;
}

/// A JSON number, which is a `double` in Dart even when it arrives without
/// a fraction.
final class NumberType extends SchemaType {
  /// Creates the type.
  const NumberType();

  @override
  String get dartType => 'double';

  @override
  bool get isJsonValue => true;

  @override
  Iterable<String> get references => const [];

  @override
  String decode(String expression) => 'asJson<num>($expression).toDouble()';

  @override
  String encode(String expression) => expression;
}

/// A schema of the contract, referred to by name.
final class ReferenceType extends SchemaType {
  /// Creates the reference to the schema called [name].
  const ReferenceType(this.name);

  /// Name of the schema, which is also the name of its Dart type.
  final String name;

  @override
  String get dartType => name;

  @override
  bool get isJsonValue => false;

  @override
  Iterable<String> get references => [name];

  @override
  String decode(String expression) => '$name.fromJson($expression)';

  @override
  String encode(String expression) => '$expression.toJson()';
}

/// A JSON array whose elements all have the type [item].
final class ListType extends SchemaType {
  /// Creates the list of [item].
  const ListType(this.item);

  /// Type of each element.
  final SchemaType item;

  @override
  String get dartType => 'List<${item.dartType}>';

  @override
  bool get isJsonValue => item.isJsonValue;

  @override
  Iterable<String> get references => item.references;

  @override
  String decode(String expression) =>
      '[for (final item in asJson<List<Object?>>($expression)) '
      '${item.decode('item')}]';

  @override
  String encode(String expression) => isJsonValue
      ? expression
      : '[for (final item in $expression) ${item.encode('item')}]';
}

/// A JSON object used as a map from string to [value].
final class MapType extends SchemaType {
  /// Creates the map to [value].
  const MapType(this.value);

  /// Type of each value of the map.
  final SchemaType value;

  @override
  String get dartType => 'Map<String, ${value.dartType}>';

  @override
  bool get isJsonValue => value.isJsonValue;

  @override
  Iterable<String> get references => value.references;

  @override
  String decode(String expression) =>
      '{for (final MapEntry(:key, :value) in '
      'asJson<Map<String, Object?>>($expression).entries) '
      "key: ${value.decode('value')}}";

  @override
  String encode(String expression) => isJsonValue
      ? expression
      : '{for (final MapEntry(:key, :value) in $expression.entries) '
            "key: ${value.encode('value')}}";
}

/// A value of the type [inner], or `null`.
final class NullableType extends SchemaType {
  /// Creates the nullable form of [inner].
  const NullableType(this.inner);

  /// Type of the value when it is not `null`.
  final SchemaType inner;

  @override
  String get dartType => '${inner.dartType}?';

  @override
  bool get isJsonValue => inner.isJsonValue;

  @override
  Iterable<String> get references => inner.references;

  @override
  SchemaType get nullable => this;

  @override
  String decode(String expression) =>
      'switch ($expression) { null => null, final value => '
      "${inner.decode('value')}, }";

  @override
  String encode(String expression) => isJsonValue
      ? expression
      : 'switch ($expression) { null => null, final value => '
            "${inner.encode('value')}, }";
}
