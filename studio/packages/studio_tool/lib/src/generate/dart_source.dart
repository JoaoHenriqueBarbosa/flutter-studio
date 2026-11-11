import 'contract_field.dart';

/// First lines of every generated file (CS-DRY-012).
const generatedHeader =
    '// GENERATED CODE - DO NOT MODIFY BY HAND\n'
    '// Source: studio.openrpc.json. Generator: st generate.\n';

/// Widest line of a doc comment, counting the indentation and the slashes.
const _lineWidth = 80;

/// Returns [name], written in `UpperCamelCase` or `lowerCamelCase`, in
/// `snake_case`, the form of a Dart file name.
String snakeCase(String name) => name
    .replaceAllMapped(
      RegExp('(?<=[a-z0-9])[A-Z]'),
      (match) => '_${match.group(0)}',
    )
    .toLowerCase();

/// Returns [name] with the first letter in lower case.
String lowerFirst(String name) =>
    '${name.substring(0, 1).toLowerCase()}${name.substring(1)}';

/// Returns [text] as a doc comment indented by [indent], one paragraph for
/// each line of [text], wrapped at the line width.
String docComment(String text, {String indent = ''}) {
  final prefix = '$indent///';
  final lines = <String>[];
  for (final paragraph in text.split('\n')) {
    if (lines.isNotEmpty) lines.add(prefix);
    var line = prefix;
    for (final word in paragraph.split(' ')) {
      if (line.length + 1 + word.length > _lineWidth && line != prefix) {
        lines.add(line);
        line = prefix;
      }
      line = '$line $word';
    }
    lines.add(line);
  }
  return lines.join('\n');
}

/// Returns the import directives for [uris], sorted and without repeats.
String importDirectives(Iterable<String> uris) =>
    [for (final uri in uris.toSet().toList()..sort()) "import '$uri';"]
        .join('\n');

/// Returns the entry of a JSON map literal that encodes [field] from the
/// variable of the same name. An optional field has no entry when the
/// variable is `null`.
String jsonEntry(ContractField field) {
  final name = field.name;
  final value = field.type.encode(name);
  if (field.isRequired) return "'$name': $value,";
  return field.type.isJsonValue
      ? "'$name': ?$name,"
      : "if ($name case final $name?) '$name': $value,";
}
