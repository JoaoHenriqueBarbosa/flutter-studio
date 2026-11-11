import 'dart:io';

import '../dap/dap_client.dart';
import '../sdk/flutter_sdk.dart';
import '../toolchain/base_protocol_channel.dart';
import 'run_target.dart';

/// One run of the app of the project, driven by the Flutter debug adapter
/// (FR-RUN-001).
final class AppRun {
  AppRun._(this._adapter, this._client);

  final Process _adapter;

  final DapClient _client;

  /// Text that the app and the build write (FR-RUN-003).
  Stream<String> get output => _client.output;

  /// Address of the VM Service of the app, once the app has started.
  Future<Uri> get vmServiceUri => _client.vmServiceUri;

  /// Completes when the run ends.
  Future<void> get ended => _client.terminated;

  /// Builds and starts on [target], with [sdk], the Flutter project at
  /// [rootPath].
  ///
  /// Completes when the debug adapter accepts the launch. Throws a
  /// [ProcessException] when the adapter cannot be started.
  static Future<AppRun> start(
    FlutterSdk sdk, {
    required String rootPath,
    required RunTarget target,
  }) async {
    final adapter = await Process.start(sdk.flutterPath, const [
      'debug-adapter',
    ]);
    final client = DapClient(
      baseProtocolChannel(adapter.stdout, adapter.stdin),
    );
    await client.launch(
      projectPath: rootPath,
      deviceId: target.deviceId,
      toolArguments: target.toolArguments,
    );
    return AppRun._(adapter, client);
  }

  /// Reloads into the app the code that changed on disk.
  Future<void> hotReload() => _client.hotReload();

  /// Restarts the app with the code on disk.
  Future<void> hotRestart() => _client.hotRestart();

  /// Ends the app and the debug adapter.
  Future<void> stop() async {
    await _client.terminate();
    await _client.terminated;
    await _client.close();
    _adapter.kill();
  }
}
