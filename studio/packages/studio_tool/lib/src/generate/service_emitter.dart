import 'contract_document.dart';
import 'contract_field.dart';
import 'contract_method.dart';
import 'dart_source.dart';
import 'schema_type.dart';

/// Writes the Dart files that carry the methods of the contract: the
/// interface, the client that calls it and the dispatcher that serves it.
final class ServiceEmitter {
  /// Creates the emitter for [_document].
  const ServiceEmitter(this._document);

  final ContractDocument _document;

  String get _title => _document.title;

  String get _file => snakeCase(_title);

  /// Returns each file, by its name.
  Map<String, String> emit() => {
    '${_file}_api.dart': _emitApi(),
    '${_file}_client.dart': _emitClient(),
    '${_file}_dispatcher.dart': _emitDispatcher(),
  };

  List<String> get _schemaUris => [
    for (final method in _document.methods) ...[
      for (final reference in method.result.references)
        '${snakeCase(reference)}.dart',
      for (final param in method.params)
        for (final reference in param.type.references)
          '${snakeCase(reference)}.dart',
    ],
  ];

  List<String> get _paramUris => [
    for (final method in _document.methods)
      for (final param in method.params)
        for (final reference in param.type.references)
          '${snakeCase(reference)}.dart',
  ];

  String _implementationImports(List<String> schemaUris) => importDirectives([
    '../json_conversion.dart',
    ...schemaUris,
    '${_file}_api.dart',
    '${_file}_method.dart',
  ]);

  String _emitApi() =>
      '''
$generatedHeader
${importDirectives(_schemaUris)}

${docComment(_document.description)}
///
/// A method fails with a `${_title}Fault` that carries one of the errors it
/// declares.
abstract interface class ${_title}Api {
${_document.methods.map(_declaration).join('\n\n')}
}
''';

  String _declaration(ContractMethod method) {
    final paragraphs = [
      method.summary,
      ?method.description,
      for (final param in method.params)
        'The parameter [${param.name}]: ${lowerFirst(param.description)}',
      if (method.errors.isNotEmpty)
        'Errors: ${method.errors.map((error) => '`$error`').join(', ')}.',
    ];
    return '${docComment(paragraphs.join('\n'), indent: '  ')}\n'
        '  ${_signature(method)};';
  }

  String _signature(ContractMethod method) {
    final parameters = method.params.map(_parameter).join(', ');
    return 'Future<${method.result.dartType}> ${method.name}'
        '(${parameters.isEmpty ? '' : '{$parameters,}'})';
  }

  String _parameter(ContractField param) {
    final modifier = param.isRequired ? 'required ' : '';
    return '$modifier${_typeOf(param).dartType} ${param.name}';
  }

  String _emitClient() =>
      '''
$generatedHeader
${_implementationImports(_schemaUris)}

/// Sends one call of the `$_title` service and completes with its result,
/// both in JSON form.
typedef ${_title}Call =
    Future<Object?> Function(
      ${_title}Method method,
      Map<String, Object?> params,
    );

/// Client of the `$_title` service over any transport.
final class ${_title}Client implements ${_title}Api {
  /// Creates a client that sends each call through [_call].
  const ${_title}Client(this._call);

  final ${_title}Call _call;

${_document.methods.map(_clientMethod).join('\n\n')}
}
''';

  String _clientMethod(ContractMethod method) {
    final entries = method.params.map(jsonEntry).join();
    return '''
  @override
  ${_signature(method)} async {
    final result = await _call(${_title}Method.${method.name}, {$entries});
    return ${method.result.decode('result')};
  }''';
  }

  String _emitDispatcher() =>
      '''
$generatedHeader
${_implementationImports(_paramUris)}

/// Serves the calls of the `$_title` service: decodes the parameters, runs
/// the method and encodes the result.
final class ${_title}Dispatcher {
  /// Creates a dispatcher that runs the methods of [_api].
  const ${_title}Dispatcher(this._api);

  final ${_title}Api _api;

  /// Runs [method] with [params] and completes with the result, both in
  /// JSON form.
  ///
  /// Throws a [FormatException] when [params] does not have the form that
  /// the contract gives to the parameters of [method].
  Future<Object?> dispatch(
    ${_title}Method method,
    Map<String, Object?> params,
  ) async {
    switch (method) {
${_document.methods.map(_dispatchCase).join('\n')}
    }
  }
}
''';

  String _dispatchCase(ContractMethod method) {
    final arguments = [
      for (final param in method.params)
        "${param.name}: ${_typeOf(param).decode("params['${param.name}']")},",
    ].join();
    return '''
      case ${_title}Method.${method.name}:
        final result = await _api.${method.name}($arguments);
        return ${method.result.encode('result')};''';
  }

  SchemaType _typeOf(ContractField field) =>
      field.isRequired ? field.type : field.type.nullable;
}
