import 'dart:async';
import 'dart:io';

import '../document/applied_edit.dart';
import '../document/document_store.dart';
import '../document/edit_failure.dart';
import '../document/source_location.dart';
import '../document/workspace_edit.dart';
import '../lsp/document_sync.dart';
import '../lsp/lsp_client.dart';
import '../lsp/lsp_request_failed.dart';
import 'argument_literal.dart';
import 'edit_outcome.dart';

/// The transaction of every edit: check the target, produce the edit,
/// write the files, ask for the reload (ADR-0007).
///
/// Pipes and Filters, with the stages run in a fixed order and one edit at
/// a time, in arrival order. This version has the first level of ADR-0006,
/// in which the analysis server produces the edit.
final class EditPipeline {
  /// Creates the pipeline over [_documents] and [_sync].
  ///
  /// [_server] returns the current client of the analysis server, or `null`
  /// while the server is not running. [_requestReload] asks the running app
  /// to reload and tells whether there was an app to ask.
  EditPipeline(
    this._documents,
    this._sync, {
    required this._server,
    required this._requestReload,
  });

  static const _serverName = 'analysis-server';

  final DocumentStore _documents;

  final DocumentSync _sync;

  final LspClient? Function() _server;

  final bool Function() _requestReload;

  /// Completes when the operation at the end of the line does.
  Future<void> _lastOperation = Future.value();

  /// What the store applied on behalf of the server since the operation in
  /// progress started.
  final _appliedByServer = <AppliedEdit>[];

  /// Whether an operation of this pipeline is in progress.
  var _isRunning = false;

  /// Gives the value written in [source] to the argument [name] of the
  /// constructor called at [target].
  ///
  /// [documentVersion] is the version of the document that the caller read.
  /// Completes when the files are on disk. Throws an [EditFailure] and
  /// changes nothing when the edit is refused.
  Future<EditOutcome> setArgument(
    SourceLocation target, {
    required int documentVersion,
    required String name,
    required String? source,
  }) => _enqueue(() async {
    _checkTarget(target.filePath, documentVersion);
    if (source == null) {
      throw const UnsupportedEdit('Removing an argument is not built yet.');
    }
    final server = _server();
    if (server == null) throw const ToolUnavailable(_serverName);
    _sync.ensureOpen(target.filePath);
    try {
      final newValue = await _valueFor(server, target, name, source);
      await server.editArgument(
        target,
        documentVersion: documentVersion,
        name: name,
        newValue: newValue,
      );
    } on LspRequestFailed catch (failure) {
      throw UnsupportedEdit(failure.message);
    }
    return _outcomeOf(_merge(_appliedByServer));
  });

  /// Undoes the last edit. The outcome has no edit when there is none.
  Future<EditOutcome> undo() =>
      _enqueue(() async => _outcomeOf(await _documents.undo()));

  /// Redoes the last undone edit. The outcome has no edit when there is
  /// none.
  Future<EditOutcome> redo() =>
      _enqueue(() async => _outcomeOf(await _documents.redo()));

  /// Applies an edit that the analysis server asked for, and completes with
  /// whether it was applied.
  ///
  /// The server asks while it answers an operation of this pipeline, and
  /// may also ask on behalf of another client of the daemon. In that second
  /// case the reload is requested here.
  Future<bool> applyServerEdit(WorkspaceEdit edit) async {
    try {
      final applied = await _documents.apply(edit);
      if (_isRunning) {
        _appliedByServer.add(applied);
      } else {
        _requestReload();
      }
      return true;
    } on EditFailure {
      return false;
    } on FileSystemException {
      return false;
    }
  }

  /// Runs [operation] after the ones that arrived before it.
  Future<EditOutcome> _enqueue(Future<EditOutcome> Function() operation) {
    final result = _lastOperation.then((_) async {
      _appliedByServer.clear();
      _isRunning = true;
      try {
        return await operation();
      } finally {
        _isRunning = false;
      }
    });
    _lastOperation = result.then((_) {}, onError: (Object _) {});
    return result;
  }

  void _checkTarget(String filePath, int documentVersion) {
    if (!_documents.contains(filePath)) throw EditOutsideProject(filePath);
    try {
      final currentVersion = _documents.document(filePath).version;
      if (currentVersion != documentVersion) {
        throw StaleDocument(currentVersion);
      }
    } on FileSystemException catch (exception) {
      throw UnsupportedEdit(exception.message);
    }
  }

  /// Completes with the value that the server takes for [source] as the
  /// argument [name] of the constructor at [target].
  Future<Object?> _valueFor(
    LspClient server,
    SourceLocation target,
    String name,
    String source,
  ) async {
    final arguments = await server.editableArguments(target);
    if (arguments == null) {
      throw const UnsupportedEdit('No widget is created at the position.');
    }
    final argument = arguments.where((each) => each.name == name).firstOrNull;
    if (argument == null || !argument.isEditable) {
      throw UnsupportedEdit('The argument $name is not editable.');
    }
    try {
      return ArgumentLiteral(argument.kind).valueOf(source);
    } on FormatException catch (exception) {
      throw UnsupportedEdit(exception.message);
    }
  }

  EditOutcome _outcomeOf(AppliedEdit? edit) => EditOutcome(
    edit: edit,
    isReloadRequested: edit != null && _requestReload(),
  );

  /// Returns the edits of [parts] as one, or `null` when there is none.
  AppliedEdit? _merge(List<AppliedEdit> parts) => parts.isEmpty
      ? null
      : AppliedEdit(
          changes: [for (final part in parts) ...part.changes],
          versions: {for (final part in parts) ...part.versions},
        );
}
