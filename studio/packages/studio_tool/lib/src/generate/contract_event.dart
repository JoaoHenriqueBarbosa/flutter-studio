import 'schema_type.dart';

/// An event that the service posts on its stream, with data of type `data`.
typedef ContractEvent = ({String name, String description, SchemaType data});
