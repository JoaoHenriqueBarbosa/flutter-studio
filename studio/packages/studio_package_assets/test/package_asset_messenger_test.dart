import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_package_assets/studio_package_assets.dart';

void main() {
  // Verifies: NFR-FLEX-002
  group('PackageAssetMessenger', () {
    test('returns the asset found under the requested key', () async {
      final engine = _FakeEngineMessenger({'icons/app.png': 'root'});
      final messenger = PackageAssetMessenger(
        engine,
        packageName: 'devtools_app',
      );

      final reply = await messenger.send(
        'flutter/assets',
        _encode('icons/app.png'),
      );

      expect(_decode(reply), 'root');
      expect(engine.requestedKeys, ['icons/app.png']);
    });

    test('retries a missed key inside the inherited package', () async {
      final engine = _FakeEngineMessenger({
        'packages/devtools_app/assets/dart_syntax.json': 'inherited',
      });
      final messenger = PackageAssetMessenger(
        engine,
        packageName: 'devtools_app',
      );

      final reply = await messenger.send(
        'flutter/assets',
        _encode('assets/dart_syntax.json'),
      );

      expect(_decode(reply), 'inherited');
      expect(engine.requestedKeys, [
        'assets/dart_syntax.json',
        'packages/devtools_app/assets/dart_syntax.json',
      ]);
    });

    test('answers null when the package has no such asset either', () async {
      final engine = _FakeEngineMessenger(const {});
      final messenger = PackageAssetMessenger(
        engine,
        packageName: 'devtools_app',
      );

      final reply = await messenger.send(
        'flutter/assets',
        _encode('assets/missing.json'),
      );

      expect(reply, isNull);
    });

    test('does not retry a message of another channel', () async {
      final engine = _FakeEngineMessenger(const {});
      final messenger = PackageAssetMessenger(
        engine,
        packageName: 'devtools_app',
      );

      final reply = await messenger.send(
        'flutter/platform',
        _encode('assets/missing.json'),
      );

      expect(reply, isNull);
      expect(engine.requestedKeys, ['assets/missing.json']);
    });
  });
}

ByteData _encode(String text) => ByteData.sublistView(utf8.encode(text));

String? _decode(ByteData? data) =>
    data == null ? null : utf8.decode(Uint8List.sublistView(data));

/// Answers each message with the asset stored under the key it carries, as
/// the engine does on the asset channel, and records the keys it was asked.
class _FakeEngineMessenger implements BinaryMessenger {
  _FakeEngineMessenger(this._assets);

  final Map<String, String> _assets;

  final requestedKeys = <String>[];

  @override
  Future<void> handlePlatformMessage(
    String channel,
    ByteData? data,
    ui.PlatformMessageResponseCallback? callback,
  ) => Future<void>.value();

  @override
  Future<ByteData?> send(String channel, ByteData? message) {
    final key = _decode(message);
    if (key == null) return Future.value();
    requestedKeys.add(key);
    final asset = _assets[key];
    return Future.value(asset == null ? null : _encode(asset));
  }

  @override
  void setMessageHandler(String channel, MessageHandler? handler) {}
}
