import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// A [BinaryMessenger] that resolves the asset requests of a package that
/// the application depends on.
///
/// Applies the Decorator pattern to the messenger of the binding. A request
/// on the asset channel that finds no asset is repeated with the key the
/// asset has when its package is a dependency: `packages/<package>/<key>`.
/// Every other message passes through unchanged.
final class PackageAssetMessenger implements BinaryMessenger {
  /// Creates a messenger that forwards to [_delegate] and retries missed
  /// asset requests inside the package named [packageName].
  PackageAssetMessenger(this._delegate, {required String packageName})
    : _keyPrefix = utf8.encode('packages/$packageName/');

  /// Channel on which the framework asks the engine for an asset.
  static const _assetChannel = 'flutter/assets';

  final BinaryMessenger _delegate;

  final Uint8List _keyPrefix;

  @override
  Future<void> handlePlatformMessage(
    String channel,
    ByteData? data,
    ui.PlatformMessageResponseCallback? callback,
  ) {
    ui.channelBuffers.push(channel, data, (reply) => callback?.call(reply));
    return Future<void>.value();
  }

  @override
  Future<ByteData?>? send(String channel, ByteData? message) {
    final reply = _delegate.send(channel, message);
    if (channel != _assetChannel || message == null || reply == null) {
      return reply;
    }
    return reply.then(
      (asset) => asset ?? _delegate.send(channel, _prefixed(message)),
    );
  }

  @override
  void setMessageHandler(String channel, MessageHandler? handler) {
    _delegate.setMessageHandler(channel, handler);
  }

  ByteData _prefixed(ByteData key) {
    final bytes = BytesBuilder(copy: false)
      ..add(_keyPrefix)
      ..add(key.buffer.asUint8List(key.offsetInBytes, key.lengthInBytes));
    return ByteData.sublistView(bytes.takeBytes());
  }
}
