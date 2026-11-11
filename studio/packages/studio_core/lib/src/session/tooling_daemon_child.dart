import 'dart:convert';
import 'dart:io';

import '../dtd/dtd_connection.dart';
import '../sdk/flutter_sdk.dart';
import '../toolchain/toolchain_child.dart';

/// The Dart Tooling Daemon of the project SDK, as a supervised process.
final class ToolingDaemonChild implements ToolchainChild {
  /// Creates the child for the daemon of [_sdk]. Each time a daemon is
  /// ready, the connection with it is handed to [_onConnected].
  const ToolingDaemonChild(this._sdk, this._onConnected);

  final FlutterSdk _sdk;

  final Future<void> Function(DtdConnection connection) _onConnected;

  @override
  String get name => 'tooling-daemon';

  @override
  String get executablePath => _sdk.dartPath;

  @override
  List<String> get arguments => const ['tooling-daemon', '--machine'];

  /// Reads the address that the daemon prints on its first line and
  /// connects to it.
  ///
  /// Throws a [FormatException] when the first line is not the handshake.
  @override
  Future<void> attach(Process process) async {
    final handshake = await process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .first;
    final Object? details = jsonDecode(handshake);
    if (details case {'tooling_daemon_details': {'uri': final String uri}}) {
      await _onConnected(await DtdConnection.connect(Uri.parse(uri)));
    } else {
      throw FormatException('Unexpected daemon handshake.', handshake);
    }
  }
}
