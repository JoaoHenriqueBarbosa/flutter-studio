import 'contract_field.dart';
import 'contract_schema.dart';
import 'dart_source.dart';

/// Writes the Dart file of one schema of the contract: a value class for an
/// object, an enum for an enumeration.
final class SchemaEmitter {
  /// Creates the emitter.
  const SchemaEmitter();

  /// Returns the source of the file that declares [schema].
  String emit(ContractSchema schema) =>
      schema.enumValues.isEmpty ? _emitClass(schema) : _emitEnum(schema);

  String _emitEnum(ContractSchema schema) {
    final name = schema.name;
    final values = [
      for (final value in schema.enumValues)
        '  /// The value `$value`.\n  $value',
    ].join(',\n\n');
    return '''
$generatedHeader
import '../json_conversion.dart';

${docComment(schema.description)}
enum $name {
$values;

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] is not one of the values.
  factory $name.fromJson(Object? json) {
    final name = asJson<String>(json);
    return values.asNameMap()[name] ??
        (throw FormatException('Unknown $name.', name));
  }

  /// Encodes the value in the form it has on the wire.
  String toJson() => name;
}
''';
  }

  String _emitClass(ContractSchema schema) {
    final name = schema.name;
    final fields = schema.fields;
    final imports = importDirectives([
      '../json_conversion.dart',
      for (final field in fields)
        for (final reference in field.type.references)
          if (reference != name) '${snakeCase(reference)}.dart',
    ]);
    final parameters = [
      for (final field in fields)
        '${field.isRequired ? 'required ' : ''}this.${field.name}',
    ].join(', ');
    return '''
$generatedHeader
$imports

${docComment(schema.description)}
final class $name {
  /// Creates the value from its fields.
  const $name(${parameters.isEmpty ? '' : '{$parameters,}'});

  /// Decodes the value from [json], the form it has on the wire.
  ///
  /// Throws a [FormatException] when [json] does not have that form.
  factory $name.fromJson(Object? json) {
    final fields = asJson<Map<String, Object?>>(json);
    return $name(${fields.map(_decodeArgument).join()});
  }

${fields.map(_declaration).join('\n\n')}

  /// Encodes the value in the form it has on the wire.
  Map<String, Object?> toJson() => {${fields.map(jsonEntry).join()}};

  @override
  bool operator ==(Object other) =>
      other is $name && jsonEquals(toJson(), other.toJson());

  @override
  int get hashCode => jsonHash(toJson());

  @override
  String toString() => '$name(\${toJson()})';
}
''';
  }

  String _declaration(ContractField field) {
    final type = field.isRequired ? field.type : field.type.nullable;
    return '${docComment(field.description, indent: '  ')}\n'
        '  final ${type.dartType} ${field.name};';
  }

  String _decodeArgument(ContractField field) {
    final type = field.isRequired ? field.type : field.type.nullable;
    return "${field.name}: ${type.decode("fields['${field.name}']")},";
  }
}
