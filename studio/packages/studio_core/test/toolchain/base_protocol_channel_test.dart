import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/studio_core.dart';

void main() {
  // Verifies: IR-001, IR-002
  test('baseProtocolChannel frames what is sent with the byte length', () {
    final written = StreamController<List<int>>();
    final channel = baseProtocolChannel(const Stream.empty(), written.sink);

    channel.sink.add('{"text":"ação"}');

    expect(
      written.stream.map(utf8.decode),
      emits('Content-Length: 17\r\n\r\n{"text":"ação"}'),
    );
  });
}
