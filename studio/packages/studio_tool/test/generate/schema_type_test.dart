import 'package:studio_tool/studio_tool.dart';
import 'package:test/test.dart';

void main() {
  group('SchemaType', () {
    // Verifies: NFR-MNT-006
    test('reads a primitive as its own JSON form', () {
      final type = SchemaType.parse({'type': 'integer'});

      expect(type.dartType, 'int');
      expect(type.decode('x'), 'asJson<int>(x)');
      expect(type.encode('x'), 'x');
    });

    // Verifies: NFR-MNT-006
    test('reads a number as a double', () {
      final type = SchemaType.parse({'type': 'number'});

      expect(type.dartType, 'double');
      expect(type.decode('x'), 'asJson<num>(x).toDouble()');
    });

    // Verifies: NFR-MNT-006
    test('reads a reference as the type of the same name', () {
      final type = SchemaType.parse({r'$ref': '#/components/schemas/Thing'});

      expect(type.dartType, 'Thing');
      expect(type.references, ['Thing']);
      expect(type.decode('x'), 'Thing.fromJson(x)');
      expect(type.encode('x'), 'x.toJson()');
    });

    // Verifies: NFR-MNT-006
    test('reads a list and converts each element', () {
      final type = SchemaType.parse({
        'type': 'array',
        'items': {r'$ref': '#/components/schemas/Thing'},
      });

      expect(type.dartType, 'List<Thing>');
      expect(type.encode('x'), '[for (final item in x) item.toJson()]');
      expect(type.decode('x'), contains('Thing.fromJson(item)'));
    });

    // Verifies: NFR-MNT-006
    test('reads a map of primitives as its own JSON form', () {
      final type = SchemaType.parse({
        'type': 'object',
        'additionalProperties': {'type': 'integer'},
      });

      expect(type.dartType, 'Map<String, int>');
      expect(type.encode('x'), 'x');
      expect(type.decode('x'), contains('key: asJson<int>(value)'));
    });

    // Verifies: NFR-MNT-006
    test('reads a value that may be null', () {
      final type = SchemaType.parse({
        'oneOf': [
          {r'$ref': '#/components/schemas/Thing'},
          {'type': 'null'},
        ],
      });

      expect(type.dartType, 'Thing?');
      expect(type.nullable, same(type));
      expect(type.decode('x'), contains('null => null'));
      expect(type.encode('x'), contains('value.toJson()'));
    });

    // Verifies: NFR-MNT-006
    test('refuses a schema outside the supported subset', () {
      expect(
        () => SchemaType.parse({'allOf': <Object?>[]}),
        throwsFormatException,
      );
    });
  });
}
