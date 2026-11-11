/// One parameter of the constructor at a position, as the analysis server
/// describes it for editing.
final class EditableArgument {
  /// Creates the description of the parameter called [name].
  const EditableArgument({
    required this.name,
    required this.kind,
    required this.hasArgument,
    required this.isEditable,
    this.value,
    this.displayValue,
    this.defaultValue,
    this.options,
    this.documentation,
  });

  /// Kind of an argument whose value is a string.
  static const stringKind = 'string';

  /// Kind of an argument whose value is an integer.
  static const intKind = 'int';

  /// Kind of an argument whose value is a floating point number.
  static const doubleKind = 'double';

  /// Kind of an argument whose value is a boolean.
  static const boolKind = 'bool';

  /// Kind of an argument whose value is one of the constants of an enum.
  static const enumKind = 'enum';

  /// Name of the parameter.
  final String name;

  /// Kind of value, from the set that the server defines: [stringKind],
  /// [intKind], [doubleKind], [boolKind], [enumKind], or another name for a
  /// value that cannot be edited as a literal.
  final String kind;

  /// Whether the code gives an argument for the parameter.
  final bool hasArgument;

  /// Whether the server can edit the argument.
  final bool isEditable;

  /// The literal value of the argument, or of the default when there is no
  /// argument: a `bool`, a `num` or a `String`. It is `null` when the value
  /// is `null`, is not a literal or is absent.
  final Object? value;

  /// Source of the argument when it is not a literal.
  final String? displayValue;

  /// The literal default value of the parameter, or `null` when it has none.
  final Object? defaultValue;

  /// The constants that an enum parameter accepts, as source text.
  final List<String>? options;

  /// Documentation of the parameter.
  final String? documentation;
}
