import 'package:flutter/services.dart';

/// An [AssetBundle] that reads every asset through [AssetBundle.load].
///
/// The platform bundle reads image buffers straight from the engine, which
/// the binary messenger of the binding never sees. This bundle keeps the
/// default [AssetBundle.loadBuffer], so buffers also come from [load].
final class MessageChannelAssetBundle extends CachingAssetBundle {
  /// Creates a bundle that loads the bytes of each asset from [_source].
  MessageChannelAssetBundle(this._source);

  final AssetBundle _source;

  @override
  Future<ByteData> load(String key) => _source.load(key);
}
