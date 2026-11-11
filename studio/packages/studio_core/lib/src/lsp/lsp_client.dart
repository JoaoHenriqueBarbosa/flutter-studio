import 'dart:async';
import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:stream_channel/stream_channel.dart';

import '../document/text_edit.dart';
import '../document/workspace_edit.dart';

/// The diagnostics that the analysis server reports for one file. Each
/// report replaces the previous one for the same file.
typedef FileDiagnostics = ({String filePath, List<String> messages});

/// Applies an edit requested by the analysis server and tells whether it
/// was applied.
typedef ApplyEdit = Future<bool> Function(WorkspaceEdit edit);

/// Client of the analysis server over the Language Server Protocol
/// (IR-001).
///
/// An Adapter in the role of Gateway: JSON stays inside this class, and the
/// rest of the core sees domain types (CS-DSN-004).
final class LspClient {
  /// Creates a client that talks over [channel], one JSON text per message,
  /// and hands the edits requested by the server to [_applyEdit].
  LspClient(StreamChannel<String> channel, {required this._applyEdit})
    : _peer = Peer(channel) {
    _peer
      ..registerMethod(_applyEditMethod, _handleApplyEdit)
      ..registerMethod(_diagnosticsMethod, _handleDiagnostics)
      ..registerFallback(_ignore);
    unawaited(_peer.listen());
  }

  static const _applyEditMethod = 'workspace/applyEdit';

  static const _diagnosticsMethod = 'textDocument/publishDiagnostics';

  final Peer _peer;

  final ApplyEdit _applyEdit;

  final _diagnostics = StreamController<FileDiagnostics>.broadcast();

  /// Diagnostics of each file, as the server publishes them.
  Stream<FileDiagnostics> get diagnostics => _diagnostics.stream;

  /// Completes when the connection with the server ends.
  Future<void> get done => _peer.done;

  /// Starts the session for the project at [rootPath].
  ///
  /// Completes when the server has answered and may receive requests.
  Future<void> initialize(String rootPath) async {
    final rootUri = '${Uri.directory(rootPath)}';
    await _peer.sendRequest('initialize', {
      'processId': pid,
      'rootUri': rootUri,
      'workspaceFolders': [
        {'uri': rootUri, 'name': rootPath},
      ],
      'capabilities': {
        'workspace': {
          'applyEdit': true,
          'workspaceEdit': {'documentChanges': true},
        },
      },
    });
    _peer.sendNotification('initialized', const <String, Object?>{});
  }

  /// Pairs the server with the Dart Tooling Daemon at [daemonUri], which
  /// makes the server register its `Lsp` service there.
  Future<void> connectToDtd(Uri daemonUri) =>
      _peer.sendRequest('dart/connectToDtd', {'uri': '$daemonUri'});

  /// Ends the session and closes the channel.
  Future<void> close() async {
    await _diagnostics.close();
    await _peer.close();
  }

  Future<Map<String, Object?>> _handleApplyEdit(Parameters parameters) async {
    final edit = _workspaceEditFrom(parameters.value);
    if (edit == null) {
      return {'applied': false, 'failureReason': 'Unsupported edit.'};
    }
    return {'applied': await _applyEdit(edit)};
  }

  void _handleDiagnostics(Parameters parameters) {
    final Object? report = parameters.value;
    if (report case {
      'uri': final String uri,
      'diagnostics': final List<Object?> diagnostics,
    }) {
      _diagnostics.add((
        filePath: Uri.parse(uri).toFilePath(),
        messages: [
          for (final diagnostic in diagnostics)
            if (diagnostic case {'message': final String message}) message,
        ],
      ));
    }
  }

  /// Answers `null` to every request and notification this client has no
  /// use for, so the server is never left waiting.
  Object? _ignore(Parameters parameters) => null;

  /// Returns the edit in the parameters of `workspace/applyEdit`, or `null`
  /// when it has a part that this client does not apply, such as a file
  /// creation.
  WorkspaceEdit? _workspaceEditFrom(Object? parameters) {
    if (parameters case {
      'edit': {'documentChanges': final List<Object?> changes},
    }) {
      final fileEdits = [for (final change in changes) _fileEditFrom(change)];
      if (!fileEdits.contains(null)) {
        return WorkspaceEdit(fileEdits.nonNulls.toList());
      }
    }
    return null;
  }

  FileEdit? _fileEditFrom(Object? change) {
    if (change case {
      'textDocument': {'uri': final String uri},
      'edits': final List<Object?> edits,
    }) {
      final textEdits = [for (final edit in edits) _textEditFrom(edit)];
      if (!textEdits.contains(null)) {
        return (
          filePath: Uri.parse(uri).toFilePath(),
          edits: textEdits.nonNulls.toList(),
        );
      }
    }
    return null;
  }

  TextEdit? _textEditFrom(Object? edit) {
    if (edit case {
      'range': {'start': final Object? start, 'end': final Object? end},
      'newText': final String newText,
    }) {
      final startPosition = _positionFrom(start);
      final endPosition = _positionFrom(end);
      if (startPosition != null && endPosition != null) {
        return (
          range: (start: startPosition, end: endPosition),
          newText: newText,
        );
      }
    }
    return null;
  }

  DocumentPosition? _positionFrom(Object? position) => switch (position) {
    {'line': final int line, 'character': final int character} => (
      line: line,
      character: character,
    ),
    _ => null,
  };
}
