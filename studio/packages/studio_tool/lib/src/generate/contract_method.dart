import 'contract_field.dart';
import 'schema_type.dart';

/// A method of the service. `errors` holds the names of the errors that the
/// method declares.
typedef ContractMethod = ({
  String name,
  String summary,
  String? description,
  List<ContractField> params,
  SchemaType result,
  List<String> errors,
});
