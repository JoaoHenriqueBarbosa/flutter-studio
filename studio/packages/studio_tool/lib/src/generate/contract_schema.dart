import 'contract_field.dart';

/// A named schema of the contract. It is an enumeration when `enumValues`
/// is not empty, and an object with `fields` otherwise.
typedef ContractSchema = ({
  String name,
  String description,
  List<ContractField> fields,
  List<String> enumValues,
});
