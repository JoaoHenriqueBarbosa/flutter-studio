import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/studio_core.dart';

List<int> _frame(String body) => [
  ...ascii.encode('Content-Length: ${utf8.encode(body).length}\r\n\r\n'),
  ...utf8.encode(body),
];

void main() {
  // Verifies: IR-001, IR-002
  group('BaseProtocolDecoder', () {
    test('decodes messages that arrive whole', () async {
      final input = Stream.fromIterable([_frame('{"id":1}'), _frame('{}')]);

      final messages = await input
          .transform(const BaseProtocolDecoder())
          .toList();

      expect(messages, ['{"id":1}', '{}']);
    });

    test('joins a message split across chunks', () async {
      final frame = _frame('{"text":"ação"}');
      final input = Stream.fromIterable([
        frame.sublist(0, 5),
        frame.sublist(5, 30),
        frame.sublist(30),
      ]);

      final messages = await input
          .transform(const BaseProtocolDecoder())
          .toList();

      expect(messages, ['{"text":"ação"}']);
    });

    test('splits two messages that arrive in one chunk', () async {
      final input = Stream.fromIterable([
        [..._frame('{"a":1}'), ..._frame('{"b":2}')],
      ]);

      final messages = await input
          .transform(const BaseProtocolDecoder())
          .toList();

      expect(messages, ['{"a":1}', '{"b":2}']);
    });

    test('fails on a header without Content-Length', () async {
      final input = Stream<List<int>>.fromIterable([
        ascii.encode('Other: 1\r\n\r\n{}'),
      ]);

      await expectLater(
        input.transform(const BaseProtocolDecoder()).toList(),
        throwsFormatException,
      );
    });
  });
}
