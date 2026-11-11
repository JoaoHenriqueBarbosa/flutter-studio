import 'dart:io';

import '../lsp/lsp_client.dart';
import '../project/flutter_project.dart';
import '../toolchain/base_protocol_channel.dart';
import '../toolchain/toolchain_child.dart';

/// The analysis server of the project SDK, as a supervised process.
final class AnalysisServerChild implements ToolchainChild {
  /// Creates the child that analyzes [_project]. Edits requested by the
  /// server go to [_applyEdit], and each time a server is ready, its client
  /// is handed to [_onConnected].
  const AnalysisServerChild(
    this._project, {
    required this._applyEdit,
    required this._onConnected,
  });

  final FlutterProject _project;

  final ApplyEdit _applyEdit;

  final Future<void> Function(LspClient client) _onConnected;

  @override
  String get name => 'analysis-server';

  @override
  String get executablePath => _project.sdk.dartPath;

  @override
  List<String> get arguments => const [
    'language-server',
    '--client-id',
    'studio',
  ];

  @override
  Future<void> attach(Process process) async {
    final client = LspClient(
      baseProtocolChannel(process.stdout, process.stdin),
      applyEdit: _applyEdit,
    );
    await client.initialize(_project.rootPath);
    await _onConnected(client);
  }
}
