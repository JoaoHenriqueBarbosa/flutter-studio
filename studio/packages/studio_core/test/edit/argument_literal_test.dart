import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/studio_core.dart';

void main() {
  group('ArgumentLiteral', () {
    // Verifies: FR-PRP-003
    test('reads the literal of each kind', () {
      expect(const ArgumentLiteral('int').valueOf(' 42 '), 42);
      expect(const ArgumentLiteral('double').valueOf('1.5'), 1.5);
      expect(const ArgumentLiteral('bool').valueOf('true'), true);
      expect(
        const ArgumentLiteral('enum').valueOf('MainAxisAlignment.end'),
        'MainAxisAlignment.end',
      );
      expect(const ArgumentLiteral('string').valueOf("'Hello'"), 'Hello');
      expect(const ArgumentLiteral('string').valueOf('"Hi"'), 'Hi');
      expect(const ArgumentLiteral('int').valueOf('null'), isNull);
    });

    // Verifies: FR-PRP-003
    test('reads the escapes of a string and leaves a raw string as it is', () {
      const literal = ArgumentLiteral('string');

      expect(literal.valueOf(r"'It\'s \$5\n'"), "It's \$5\n");
      expect(literal.valueOf(r"r'a\n$b'"), r'a\n$b');
    });

    // Verifies: FR-PRP-003
    test('refuses an expression that is not a literal of the kind', () {
      for (final (kind, source) in [
        ('int', 'count + 1'),
        ('bool', 'isReady'),
        ('enum', 'alignment'),
        ('string', r"'Hello $name'"),
        ('string', "'a' 'b'"),
        ('string', 'title'),
        ('string', "'"),
        ('widget', 'Text()'),
      ]) {
        expect(
          () => ArgumentLiteral(kind).valueOf(source),
          throwsFormatException,
          reason: '$kind: $source',
        );
      }
    });

    // Verifies: FR-PRP-001
    test('writes a value back as source that reads to the same value', () {
      const literal = ArgumentLiteral('string');
      const text = "It's \$5\n\ta\\b";

      expect(literal.sourceOf('Hello'), "'Hello'");
      expect(literal.valueOf(literal.sourceOf(text)), text);
      expect(const ArgumentLiteral('int').sourceOf(42), '42');
      expect(
        const ArgumentLiteral('enum').sourceOf('MainAxisAlignment.end'),
        'MainAxisAlignment.end',
      );
    });

    // Verifies: FR-PRP-003, FR-PRP-007
    test('takes as enum literal only one of the known constants', () {
      const literal = ArgumentLiteral(
        'enum',
        enumOptions: ['MainAxisAlignment.start', 'MainAxisAlignment.end'],
      );

      expect(literal.valueOf('MainAxisAlignment.end'), 'MainAxisAlignment.end');
      expect(() => literal.valueOf('widget.alignment'), throwsFormatException);
    });
  });
}
