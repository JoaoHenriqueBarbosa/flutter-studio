import 'package:dtd/dtd.dart';

import '../document/text_edit.dart';

/// Connection of the shell with the Dart Tooling Daemon (IR-003).
///
/// An Adapter in the role of Gateway over the `dtd` package.
final class DtdConnection {
  DtdConnection._(this._daemon, this.uri);

  /// Stream on which an editor announces its state to the tools.
  static const _editorStream = 'Editor';

  static const _activeLocationChangedKind = 'activeLocationChanged';

  final DartToolingDaemon _daemon;

  /// Address of the daemon.
  final Uri uri;

  /// Completes when the connection with the daemon ends.
  Future<void> get done => _daemon.done;

  /// Connects to the daemon at [uri].
  static Future<DtdConnection> connect(Uri uri) async =>
      DtdConnection._(await DartToolingDaemon.connect(uri), uri);

  /// Announces on the `Editor` stream that the active location is
  /// [position] in the file at [filePath].
  ///
  /// The document is announced without a version, because the analysis
  /// server reads it from disk.
  Future<void> postActiveLocation({
    required String filePath,
    required DocumentPosition position,
  }) {
    final cursor = {'line': position.line, 'character': position.character};
    return _daemon.postEvent(_editorStream, _activeLocationChangedKind, {
      'textDocument': {'uri': '${Uri.file(filePath)}', 'version': null},
      'selections': [
        {'active': cursor, 'anchor': cursor},
      ],
    });
  }

  /// Closes the connection.
  Future<void> close() => _daemon.close();
}
