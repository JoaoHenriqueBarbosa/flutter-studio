import 'constants_emitter.dart';
import 'contract_document.dart';
import 'dart_source.dart';
import 'schema_emitter.dart';
import 'service_emitter.dart';

/// Produces the Dart sources of the `studio_protocol` package from the
/// contract (ADR-0013, NFR-MNT-006).
final class ContractGenerator {
  /// Creates the generator.
  const ContractGenerator();

  /// Directory of the generated files, relative to `lib/`.
  static const generatedDirectory = 'src/generated';

  /// Returns the content of each generated file of the package described
  /// by [document], by path relative to `lib/`.
  ///
  /// [handwrittenSources] are the files of `lib/src/` written by hand,
  /// relative to `lib/`, which the public library exports beside the
  /// generated ones.
  Map<String, String> generate(
    ContractDocument document, {
    required List<String> handwrittenSources,
  }) {
    const schemaEmitter = SchemaEmitter();
    final generated = {
      for (final schema in document.schemas)
        '${snakeCase(schema.name)}.dart': schemaEmitter.emit(schema),
      ...ConstantsEmitter(document).emit(),
      ...ServiceEmitter(document).emit(),
    };
    final exports = [
      ...handwrittenSources,
      for (final name in generated.keys) '$generatedDirectory/$name',
    ]..sort();
    return {
      for (final MapEntry(key: name, value: source) in generated.entries)
        '$generatedDirectory/$name': source,
      'studio_protocol.dart':
          '$generatedHeader\n'
          '/// Contract of the `${document.title}` service: types, names '
          'and stubs.\n'
          'library;\n\n'
          '${exports.map((path) => "export '$path';").join('\n')}\n',
    };
  }
}
