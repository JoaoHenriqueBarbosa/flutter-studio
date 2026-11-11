import 'dart:async';
import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:stream_channel/stream_channel.dart';

import '../document/source_location.dart';
import '../document/text_document.dart';
import '../document/text_edit.dart';
import '../document/workspace_edit.dart';
import 'editable_argument.dart';
import 'lsp_request_failed.dart';

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

  /// Opens in the server the file at [filePath] with the content of
  /// [document]. From then on the server analyzes that content and not the
  /// file on disk, until the next [changeDocument].
  void openDocument(String filePath, TextDocument document) =>
      _peer.sendNotification('textDocument/didOpen', {
        'textDocument': {
          'uri': '${Uri.file(filePath)}',
          'languageId': 'dart',
          'version': document.version,
          'text': document.text,
        },
      });

  /// Replaces the content that the server has for the open file at
  /// [filePath] with the one of [document].
  void changeDocument(String filePath, TextDocument document) =>
      _peer.sendNotification('textDocument/didChange', {
        'textDocument': {
          'uri': '${Uri.file(filePath)}',
          'version': document.version,
        },
        'contentChanges': [
          {'text': document.text},
        ],
      });

  /// Completes with the parameters of the constructor called at [location],
  /// or with `null` when no widget is created there.
  ///
  /// Throws [LspRequestFailed] when the server refuses the request.
  Future<List<EditableArgument>?> editableArguments(
    SourceLocation location,
  ) async {
    final result = await _request(
      'dart/textDocument/editableArguments',
      _positionParameters(location),
    );
    if (result case {'arguments': final List<Object?> arguments}) {
      return [for (final argument in arguments) ?_argumentFrom(argument)];
    }
    return null;
  }

  /// Asks the server to give the value [newValue] to the argument [name] of
  /// the constructor called at [location], in the document at
  /// [documentVersion].
  ///
  /// [newValue] is a `bool`, a `num`, a `String` or `null`. The server
  /// answers with a `workspace/applyEdit` before this call completes.
  /// Throws [LspRequestFailed] when the server refuses the edit.
  Future<void> editArgument(
    SourceLocation location, {
    required int documentVersion,
    required String name,
    required Object? newValue,
  }) => _request('dart/textDocument/editArgument', {
    ..._positionParameters(location, documentVersion: documentVersion),
    'edit': {'name': name, 'newValue': newValue},
  });

  /// Ends the session and closes the channel.
  Future<void> close() async {
    await _diagnostics.close();
    await _peer.close();
  }

  Future<Object?> _request(
    String method,
    Map<String, Object?> parameters,
  ) async {
    try {
      final Object? result = await _peer.sendRequest(method, parameters);
      return result;
    } on RpcException catch (exception) {
      throw LspRequestFailed(method, exception.message);
    } on StateError catch (error) {
      throw LspRequestFailed(method, error.message);
    }
  }

  Map<String, Object?> _positionParameters(
    SourceLocation location, {
    int? documentVersion,
  }) => {
    'textDocument': {
      'uri': '${Uri.file(location.filePath)}',
      'version': ?documentVersion,
    },
    'position': {
      'line': location.position.line,
      'character': location.position.character,
    },
  };

  EditableArgument? _argumentFrom(Object? argument) {
    if (argument case {'name': final String name, 'type': final String kind}) {
      return EditableArgument(
        name: name,
        kind: kind,
        hasArgument: argument['hasArgument'] == true,
        isEditable: argument['isEditable'] != false,
        value: argument['value'],
        displayValue: switch (argument['displayValue']) {
          final String displayValue => displayValue,
          _ => null,
        },
        defaultValue: argument['defaultValue'],
        options: switch (argument['options']) {
          final List<Object?> options => options.whereType<String>().toList(),
          _ => null,
        },
        documentation: switch (argument['documentation']) {
          final String documentation => documentation,
          _ => null,
        },
      );
    }
    return null;
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
