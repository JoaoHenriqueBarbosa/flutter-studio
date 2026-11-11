import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_package_assets/studio_package_assets.dart';

void main() {
  // Verifies: NFR-FLEX-002
  test('MessageChannelAssetBundle reads image buffers from load', () async {
    final source = _RecordingAssetBundle('icons/app.png', const [1, 2, 3]);
    final bundle = MessageChannelAssetBundle(source);

    final buffer = await bundle.loadBuffer('icons/app.png');

    expect(buffer.length, 3);
    expect(source.loadedKeys, ['icons/app.png']);
  });
}

/// Serves one asset from memory and records the keys requested from [load].
class _RecordingAssetBundle extends CachingAssetBundle {
  _RecordingAssetBundle(this._key, this._bytes);

  final String _key;

  final List<int> _bytes;

  final loadedKeys = <String>[];

  @override
  Future<ByteData> load(String key) {
    loadedKeys.add(key);
    if (key != _key) throw StateError('Unexpected asset key: $key');
    return Future.value(ByteData.sublistView(Uint8List.fromList(_bytes)));
  }
}
