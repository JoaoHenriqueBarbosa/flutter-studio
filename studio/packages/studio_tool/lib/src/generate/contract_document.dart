import 'dart:convert';

import 'contract_error.dart';
import 'contract_event.dart';
import 'contract_field.dart';
import 'contract_method.dart';
import 'contract_schema.dart';
import 'schema_type.dart';

/// The OpenRPC document of the `Studio` service, read into the parts that
/// the generator uses (ADR-0013).
///
/// This class is the border where the JSON of the document becomes typed
/// values. Reading also enforces the naming convention of the protocol
/// (CS-NAM-005) and the presence of every description (CS-DOC-010).
final class ContractDocument {
  const ContractDocument._({
    required this.title,
    required this.description,
    required this.version,
    required this.binding,
    required this.methods,
    required this.events,
    required this.agentExtensionPrefix,
    required this.agentExtensions,
    required this.schemas,
    required this.errors,
  });

  /// Reads the document from [source], the text of the OpenRPC file.
  ///
  /// Throws a [FormatException] when the text is not JSON, when a part is
  /// missing or outside the supported subset, or when a name breaks the
  /// convention.
  factory ContractDocument.parse(String source) {
    final Object? document = jsonDecode(source);
    if (document case {
      'info': {
        'title': final String title,
        'version': final String version,
        'description': final String description,
      },
      'x-binding': final Map<String, Object?> binding,
      'methods': final List<Object?> methods,
      'x-events': final List<Object?> events,
      'x-agent': {
        'extensionPrefix': final String agentExtensionPrefix,
        'extensions': final List<Object?> agentExtensions,
      },
      'components': {
        'schemas': final Map<String, Object?> schemas,
        'errors': final Map<String, Object?> errors,
      },
    }) {
      return ContractDocument._(
        title: title,
        description: description,
        version: version,
        binding: {
          for (final MapEntry(:key, :value) in binding.entries) key: '$value',
        },
        methods: methods.map(_methodFrom).toList(),
        events: events.map(_eventFrom).toList(),
        agentExtensionPrefix: agentExtensionPrefix,
        agentExtensions: agentExtensions.map(_eventFrom).toList(),
        schemas: schemas.entries.map(_schemaFrom).toList(),
        errors: errors.entries.map(_errorFrom).toList(),
      );
    }
    throw const FormatException('The document lacks a required section.');
  }

  static final _lowerCamelCase = RegExp(r'^[a-z][a-zA-Z0-9]*$');

  static final _upperCamelCase = RegExp(r'^[A-Z][a-zA-Z0-9]*$');

  /// Name of the service.
  final String title;

  /// What the service is for.
  final String description;

  /// Semantic version of the contract.
  final String version;

  /// How the contract travels on the Dart Tooling Daemon: names of the
  /// service and of the stream, and the envelope of a result.
  final Map<String, String> binding;

  /// The methods, in document order.
  final List<ContractMethod> methods;

  /// The events, in document order.
  final List<ContractEvent> events;

  /// Prefix of the service extensions of the design agent, such as
  /// `ext.studio.agent`.
  final String agentExtensionPrefix;

  /// The service extensions of the design agent, each with the type of its
  /// result, in document order.
  final List<ContractEvent> agentExtensions;

  /// The named schemas, in document order.
  final List<ContractSchema> schemas;

  /// The errors, in document order.
  final List<ContractError> errors;

  static ContractMethod _methodFrom(Object? method) {
    if (method case {
      'name': final String name,
      'summary': final String summary,
      'paramStructure': 'by-name',
      'params': final List<Object?> params,
      'result': {'schema': final Object? result},
      'examples': [_, ...] && final List<Object?> examples,
    }) {
      return (
        name: _checked(name, _lowerCamelCase),
        summary: summary,
        description: switch (method['description']) {
          final String description => description,
          _ => null,
        },
        params: params.map(_paramFrom).toList(),
        result: SchemaType.parse(result),
        errors: [
          if (method['errors'] case final List<Object?> errors)
            for (final error in errors)
              if (error case {r'$ref': final String reference})
                reference.split('/').last,
        ],
        examples: [
          for (final example in examples)
            const JsonEncoder.withIndent('  ').convert(example),
        ],
      );
    }
    throw FormatException(
      'A method needs name, summary, by-name params, result and example.',
      method,
    );
  }

  static ContractField _paramFrom(Object? param) {
    if (param case {
      'name': final String name,
      'description': final String description,
      'schema': final Object? schema,
    }) {
      return (
        name: _checked(name, _lowerCamelCase),
        description: description,
        type: SchemaType.parse(schema),
        isRequired: param['required'] == true,
      );
    }
    throw FormatException('A param needs name, description and schema.', param);
  }

  static ContractEvent _eventFrom(Object? event) {
    if (event case {
      'name': final String name,
      'description': final String description,
      'schema': final Object? schema,
    }) {
      return (
        name: _checked(name, _lowerCamelCase),
        description: description,
        data: SchemaType.parse(schema),
      );
    }
    throw FormatException(
      'An event or extension needs name, description and schema.',
      event,
    );
  }

  static ContractSchema _schemaFrom(MapEntry<String, Object?> entry) {
    final name = _checked(entry.key, _upperCamelCase);
    switch (entry.value) {
      case {
        'description': final String description,
        'type': 'string',
        'enum': final List<Object?> values,
      }:
        return (
          name: name,
          description: description,
          fields: const [],
          enumValues: [
            for (final value in values) _checked('$value', _lowerCamelCase),
          ],
        );
      case {
        'description': final String description,
        'type': 'object',
        'required': final List<Object?> required,
        'properties': final Map<String, Object?> properties,
      }:
        return (
          name: name,
          description: description,
          fields: [
            for (final property in properties.entries)
              _propertyFrom(property, required),
          ],
          enumValues: const [],
        );
    }
    throw FormatException('Schema $name is not an object nor an enum.');
  }

  static ContractField _propertyFrom(
    MapEntry<String, Object?> property,
    List<Object?> required,
  ) {
    final schema = property.value;
    if (schema case {'description': final String description}) {
      return (
        name: _checked(property.key, _lowerCamelCase),
        description: description,
        type: SchemaType.parse(schema),
        isRequired: required.contains(property.key),
      );
    }
    throw FormatException('Property ${property.key} has no description.');
  }

  static ContractError _errorFrom(MapEntry<String, Object?> entry) {
    if (entry.value
        case {
          'code': final int code,
          'message': final String message,
          'data': final String data,
        }
        when message == entry.key) {
      return (
        name: _checked(entry.key, _upperCamelCase),
        code: code,
        data: data,
      );
    }
    throw FormatException(
      'Error ${entry.key} needs code, data and its name as message.',
    );
  }

  static String _checked(String name, RegExp convention) {
    if (convention.hasMatch(name)) return name;
    throw FormatException('The name breaks the naming convention.', name);
  }
}
