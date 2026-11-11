// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: studio.openrpc.json. Generator: st generate.

import '../json_conversion.dart';

/// A Dart expression, as source text.
final class Expression {
  /// Creates the value from its fields.
  const Expression({required this.source});

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] does not have that form.
  factory Expression.fromJson(Object? json) {
    final fields = asJson<Map<String, Object?>>(json);
    return Expression(source: asJson<String>(fields['source']));
  }

  /// The source text of the expression.
  final String source;

  /// Encodes the value in the form it has on the wire.
  Map<String, Object?> toJson() => {'source': source};

  @override
  bool operator ==(Object other) =>
      other is Expression && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());

  @override
  String toString() => 'Expression(${toJson()})';
}
