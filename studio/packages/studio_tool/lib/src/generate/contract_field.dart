import 'schema_type.dart';

/// A named value of the contract: a parameter of a method or a property of
/// an object schema. `type` is the type of the value when it is present.
typedef ContractField = ({
  String name,
  String description,
  SchemaType type,
  bool isRequired,
});
