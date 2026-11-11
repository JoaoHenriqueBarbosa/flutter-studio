import 'dart:async';
import 'dart:convert';

import 'package:stream_channel/stream_channel.dart';

import 'base_protocol_decoder.dart';

/// Returns a channel of JSON texts over the standard streams of a tool that
/// speaks the base protocol of LSP and DAP.
///
/// [input] is the standard output of the tool and [output] its standard
/// input. Closing the sink of the channel closes [output].
StreamChannel<String> baseProtocolChannel(
  Stream<List<int>> input,
  StreamSink<List<int>> output,
) {
  final outgoing = StreamController<String>();
  unawaited(outgoing.stream.map(_frame).pipe(output));
  return StreamChannel(
    input.transform(const BaseProtocolDecoder()),
    outgoing.sink,
  );
}

List<int> _frame(String message) {
  final body = utf8.encode(message);
  return [...ascii.encode('Content-Length: ${body.length}\r\n\r\n'), ...body];
}
