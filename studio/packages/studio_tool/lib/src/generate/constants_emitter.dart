import 'contract_document.dart';
import 'contract_error.dart';
import 'dart_source.dart';

/// Writes the Dart files with the names and numbers of the contract: the
/// binding constants and the enums of methods, events and errors.
final class ConstantsEmitter {
  /// Creates the emitter for [_document].
  const ConstantsEmitter(this._document);

  final ContractDocument _document;

  String get _title => _document.title;

  /// Returns each file, by its name.
  Map<String, String> emit() => {
    '${snakeCase(_title)}_contract.dart': _emitContract(),
    '${snakeCase(_title)}_method.dart': _emitEnum(
      name: '${_title}Method',
      documentation: 'The methods of the `$_title` service.',
      values: {
        for (final method in _document.methods) method.name: method.summary,
      },
    ),
    '${snakeCase(_title)}_event.dart': _emitEnum(
      name: '${_title}Event',
      documentation: 'The events that the `$_title` service posts.',
      values: {
        for (final event in _document.events) event.name: event.description,
      },
    ),
    '${snakeCase(_title)}_error_code.dart': _emitErrors(),
  };

  String _emitContract() {
    final constants = [
      _constant(
        'version',
        _document.version,
        documentation: 'Semantic version of the contract.',
      ),
      for (final MapEntry(:key, :value) in _document.binding.entries)
        _constant(
          key,
          value,
          documentation:
              'The `$key` of the binding to the Dart Tooling Daemon.',
        ),
    ].join('\n\n');
    return '''
$generatedHeader
/// Constants of the contract of the `$_title` service.
abstract final class ${_title}Contract {
$constants
}
''';
  }

  String _constant(
    String name,
    String value, {
    required String documentation,
  }) => "  /// $documentation\n  static const $name = '$value';";

  String _emitEnum({
    required String name,
    required String documentation,
    required Map<String, String> values,
  }) {
    final declarations = [
      for (final MapEntry(key: value, value: description) in values.entries)
        '${docComment(description, indent: '  ')}\n  $value',
    ].join(',\n\n');
    return '''
$generatedHeader
/// $documentation
///
/// The name of each value is its name on the wire.
enum $name {
$declarations,
}
''';
  }

  String _errorValue(ContractError error) {
    final documentation = docComment(
      'Comes with: ${lowerFirst(error.data)}',
      indent: '  ',
    );
    final name = lowerFirst(error.name);
    return "$documentation\n  $name(${error.code}, '${error.name}')";
  }

  String _emitErrors() {
    final name = '${_title}ErrorCode';
    final declarations = [
      for (final error in _document.errors) _errorValue(error),
    ].join(',\n\n');
    return '''
$generatedHeader
/// The errors of the `$_title` service, in the range that JSON-RPC 2.0
/// reserves for the implementation.
enum $name {
$declarations;

  const $name(this.code, this.message);

  /// Number of the error on the wire.
  final int code;

  /// Name of the error, sent as the message.
  final String message;
}
''';
  }
}
