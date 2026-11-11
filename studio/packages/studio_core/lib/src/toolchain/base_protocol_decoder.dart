import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

/// Splits a byte stream into the messages of the base protocol that the
/// Language Server Protocol and the Debug Adapter Protocol share.
///
/// Each message is a header block that ends with an empty line and carries
/// `Content-Length`, followed by that many bytes of UTF-8 text.
final class BaseProtocolDecoder
    extends StreamTransformerBase<List<int>, String> {
  /// Creates a decoder.
  const BaseProtocolDecoder();

  static const _headerEnd = [0x0D, 0x0A, 0x0D, 0x0A];

  static final _contentLength = RegExp(
    r'^Content-Length: *(\d+)\r?$',
    multiLine: true,
  );

  @override
  Stream<String> bind(Stream<List<int>> stream) async* {
    var pending = Uint8List(0);
    await for (final chunk in stream) {
      pending = Uint8List.fromList([...pending, ...chunk]);
      while (true) {
        final bodyStart = _bodyStart(pending);
        if (bodyStart == null) break;
        final bodyEnd = bodyStart + _bodyLength(pending, bodyStart);
        if (pending.length < bodyEnd) break;
        yield utf8.decode(Uint8List.sublistView(pending, bodyStart, bodyEnd));
        pending = Uint8List.sublistView(pending, bodyEnd);
      }
    }
  }

  /// Returns the offset just after the header block, or `null` while the
  /// block is incomplete.
  int? _bodyStart(Uint8List bytes) {
    for (var start = 0; start + _headerEnd.length <= bytes.length; start++) {
      var matches = true;
      for (var index = 0; index < _headerEnd.length; index++) {
        if (bytes[start + index] != _headerEnd[index]) {
          matches = false;
          break;
        }
      }
      if (matches) return start + _headerEnd.length;
    }
    return null;
  }

  int _bodyLength(Uint8List bytes, int bodyStart) {
    final header = ascii.decode(Uint8List.sublistView(bytes, 0, bodyStart));
    final length = _contentLength.firstMatch(header)?.group(1);
    if (length == null) {
      throw FormatException('Header without Content-Length.', header);
    }
    return int.parse(length);
  }
}
