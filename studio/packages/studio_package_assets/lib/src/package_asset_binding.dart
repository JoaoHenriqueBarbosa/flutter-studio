import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'message_channel_asset_bundle.dart';
import 'package_asset_messenger.dart';

/// A binding that resolves the assets of one package that the application
/// depends on.
///
/// The code of that package requests its assets by the keys they have when
/// the package is the root application. In another application those
/// assets are bundled under the package prefix, so this binding answers
/// each request that misses with the prefixed asset (ADR-0015).
final class PackageAssetBinding extends WidgetsFlutterBinding {
  PackageAssetBinding._(this._packageName);

  /// Returns the binding in use, creating first a [PackageAssetBinding]
  /// for the package [packageName] if no binding exists yet.
  ///
  /// A binding that already exists is returned as it is: the binding of an
  /// application is chosen once, by whoever asks first.
  static WidgetsBinding ensureInitialized({required String packageName}) {
    // In a debug build the framework tells whether another binding exists.
    // In a release build it does not, and this method has to be the first
    // to ask for a binding.
    if (!_isCreated && BindingBase.debugBindingType() == null) {
      PackageAssetBinding._(packageName);
    }
    return WidgetsBinding.instance;
  }

  /// Whether a binding of this class was created. The framework allows
  /// one binding in a process, and gives no way to ask whether it exists.
  static var _isCreated = false;

  final String _packageName;

  // Images are decoded from buffers that the engine reads by key, bypassing
  // the message channel. Routing them through this bundle sends every asset
  // request to the messenger created below.
  late final AssetBundle _assetBundle = MessageChannelAssetBundle(rootBundle);

  @override
  void initInstances() {
    super.initInstances();
    _isCreated = true;
  }

  @override
  BinaryMessenger createBinaryMessenger() => PackageAssetMessenger(
    super.createBinaryMessenger(),
    packageName: _packageName,
  );

  @override
  Widget wrapWithDefaultView(Widget rootWidget) => super.wrapWithDefaultView(
    DefaultAssetBundle(bundle: _assetBundle, child: rootWidget),
  );
}
