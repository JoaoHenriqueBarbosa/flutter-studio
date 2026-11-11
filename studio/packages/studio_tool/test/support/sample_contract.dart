import 'package:studio_tool/studio_tool.dart';

/// Source of a small contract with one method, one event, one object
/// schema, one enum and one error.
const sampleContractSource = '''
{
  "info": {"title": "Sample", "version": "1.2.3", "description": "A sample."},
  "x-binding": {"serviceName": "Sample"},
  "methods": [
    {
      "name": "rename",
      "summary": "Renames a thing.",
      "description": "Completes when the thing is renamed.",
      "paramStructure": "by-name",
      "params": [
        {
          "name": "thing",
          "description": "The thing to rename.",
          "required": true,
          "schema": {"\$ref": "#/components/schemas/Thing"}
        },
        {
          "name": "label",
          "description": "The new label.",
          "schema": {"type": "string"}
        }
      ],
      "result": {"name": "thing", "schema": {"\$ref": "#/components/schemas/Thing"}},
      "errors": [{"\$ref": "#/components/errors/NotFound"}],
      "examples": [{"name": "one", "params": [], "result": {"name": "thing", "value": {}}}]
    }
  ],
  "x-events": [
    {
      "name": "renamed",
      "description": "A thing was renamed.",
      "schema": {"\$ref": "#/components/schemas/Thing"}
    }
  ],
  "x-agent": {
    "extensionPrefix": "ext.sample.agent",
    "extensions": [
      {
        "name": "ping",
        "description": "Answers a thing.",
        "schema": {"\$ref": "#/components/schemas/Thing"}
      }
    ]
  },
  "components": {
    "schemas": {
      "Thing": {
        "description": "A thing with a label.",
        "type": "object",
        "required": ["label"],
        "properties": {
          "label": {"description": "The label.", "type": "string"},
          "kind": {"description": "The kind.", "\$ref": "#/components/schemas/Kind"},
          "tags": {"description": "The tags.", "type": "array", "items": {"type": "string"}}
        }
      },
      "Kind": {"description": "The kind of a thing.", "type": "string", "enum": ["small", "large"]}
    },
    "errors": {
      "NotFound": {"code": -32001, "message": "NotFound", "data": "The label."}
    }
  }
}
''';

/// The contract of [sampleContractSource].
ContractDocument get sampleContract =>
    ContractDocument.parse(sampleContractSource);
