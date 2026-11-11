import '../generate/contract_document.dart';
import '../generate/contract_event.dart';
import '../generate/contract_field.dart';
import '../generate/contract_method.dart';

/// Writes the reference of the `Studio` service from its contract, as
/// Markdown (CS-DOC-010, section 8.2 of the coding standard).
final class ServiceReference {
  /// Creates the writer.
  const ServiceReference();

  /// Returns the reference of the service that [document] describes.
  String render(ContractDocument document) => [
    '# ${document.title} service ${document.version}',
    document.description,
    '## Methods',
    for (final method in document.methods) _renderMethod(method),
    '## Events',
    for (final event in document.events) _renderEvent(event),
    '## Errors',
    for (final error in document.errors)
      '- `${error.code}` `${error.name}`. Data: ${error.data}',
    '## Types',
    for (final schema in document.schemas)
      schema.enumValues.isEmpty
          ? '### ${schema.name}\n\n${schema.description}\n\n'
                '${schema.fields.map(_renderField).join('\n')}'
          : '### ${schema.name}\n\n${schema.description} One of: '
                '${schema.enumValues.map((value) => '`$value`').join(', ')}.',
    '',
  ].join('\n\n');

  String _renderEvent(ContractEvent event) {
    final data = event.data.dartType;
    return '### ${event.name}\n\n${event.description} Data: `$data`.';
  }

  String _renderMethod(ContractMethod method) => [
    '### ${method.name}',
    method.summary,
    ?method.description,
    if (method.params.isNotEmpty) method.params.map(_renderField).join('\n'),
    'Result: `${method.result.dartType}`.',
    if (method.errors.isNotEmpty)
      'Errors: ${method.errors.map((error) => '`$error`').join(', ')}.',
    for (final example in method.examples) '```json\n$example\n```',
  ].join('\n\n');

  String _renderField(ContractField field) {
    final presence = field.isRequired ? '' : ', optional';
    return '- `${field.name}` (`${field.type.dartType}`$presence): '
        '${field.description}';
  }
}
