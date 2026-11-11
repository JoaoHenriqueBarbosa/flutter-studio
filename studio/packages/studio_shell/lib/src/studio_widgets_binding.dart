import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'inherited_assets/inherited_asset_messenger.dart';
import 'inherited_assets/message_channel_asset_bundle.dart';

/// Name of the inherited package whose assets the shell resolves.
const inheritedPackageName = 'devtools_app';

/// Binding of the shell, which resolves the assets of the inherited code.
///
/// The inherited code requests its assets by the keys they have when
/// `devtools_app` is the root application. Inside the shell those assets are
/// bundled under the package prefix, so this binding answers each request
/// that misses with the prefixed asset (ADR-0015).
class StudioWidgetsBinding extends WidgetsFlutterBinding {
  /// The binding in use.
  ///
  /// Throws a [FlutterError] before [ensureInitialized] is called.
  static StudioWidgetsBinding get instance =>
      BindingBase.checkInstance(_instance);
  static StudioWidgetsBinding? _instance;

  /// Returns the binding in use, creating a [StudioWidgetsBinding] first if
  /// no binding exists yet.
  static WidgetsBinding ensureInitialized() {
    if (_instance == null) {
      StudioWidgetsBinding();
    }
    return WidgetsBinding.instance;
  }

  // Images are decoded from buffers that the engine reads by key, bypassing
  // the message channel. Routing them through this bundle sends every asset
  // request to the messenger created below.
  late final AssetBundle _assetBundle = MessageChannelAssetBundle(rootBundle);

  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
  }

  @override
  BinaryMessenger createBinaryMessenger() => InheritedAssetMessenger(
    super.createBinaryMessenger(),
    packageName: inheritedPackageName,
  );

  @override
  Widget wrapWithDefaultView(Widget rootWidget) => super.wrapWithDefaultView(
    DefaultAssetBundle(bundle: _assetBundle, child: rootWidget),
  );
}
