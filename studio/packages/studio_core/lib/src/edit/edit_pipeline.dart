import 'dart:async';
import 'dart:io';

import '../document/applied_edit.dart';
import '../document/document_store.dart';
import '../document/edit_failure.dart';
import '../document/source_location.dart';
import '../document/text_edit.dart';
import '../document/workspace_edit.dart';
import '../lsp/lsp_client.dart';
import '../lsp/lsp_request_failed.dart';
import '../lsp/widget_assist.dart';
import 'argument_literal.dart';
import 'argument_source_edit.dart';
import 'edit_outcome.dart';
import 'widget_reader.dart';

/// The transaction of every edit: check the target, produce the edit,
/// write the files, ask for the reload (ADR-0007).
///
/// Pipes and Filters, with the stages run in a fixed order and one edit at
/// a time, in arrival order. This version has the first two levels of
/// ADR-0006, in which the analysis server produces the edit, and the edits
/// of the text of one argument.
final class EditPipeline {
  /// Creates the pipeline over [_documents], which reads the arguments of
  /// a target through [_reader].
  ///
  /// [_server] returns the current client of the analysis server, or `null`
  /// while the server is not running. [_requestReload] asks the running app
  /// to reload and tells whether there was an app to ask.
  EditPipeline(
    this._documents,
    this._reader, {
    required this._server,
    required this._requestReload,
  });

  static final _className = RegExp(r'^[A-Z][A-Za-z0-9]*$');

  final DocumentStore _documents;

  final WidgetReader _reader;

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
  /// constructor called at [target], or removes the argument when [source]
  /// is `null`.
  ///
  /// A literal of the kind of the parameter is written by the analysis
  /// server. Another expression takes the place of the one in the code, and
  /// a removal takes the argument out of the code; both are edits of the
  /// text of the argument.
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
    final document = _documents.documentAt(
      target.filePath,
      version: documentVersion,
    );
    final editor = ArgumentSourceEdit(document);
    if (source == null) {
      final range = await _valueRangeOf(target, name);
      return range == null
          ? const EditOutcome(edit: null, isReloadRequested: false)
          : _applyTo(target, editor.removingArgument(range));
    }
    final literal = await _literalValueFor(target, name, source);
    if (literal != null) {
      return _editThroughServer(target, documentVersion, name, literal.value);
    }
    final range = await _valueRangeOf(target, name);
    if (range == null) {
      throw UnsupportedEdit(
        'Only a literal can be given to $name, which is not in the code.',
      );
    }
    return _applyTo(target, editor.replacingValue(range, source));
  });

  /// Applies to the widget created at [target] the assist [assist] of the
  /// analysis server.
  ///
  /// [documentVersion] is the version of the document that the caller read.
  /// Completes when the files are on disk. Throws an [EditFailure] and
  /// changes nothing when the server does not offer the assist there.
  Future<EditOutcome> applyAssist(
    SourceLocation target, {
    required int documentVersion,
    required WidgetAssist assist,
  }) => _enqueue(() async {
    _documents.documentAt(target.filePath, version: documentVersion);
    final offered = await _reader.assists(target);
    final match = offered.where((each) => each.assist == assist).firstOrNull;
    if (match == null) {
      throw UnsupportedEdit('The widget does not accept ${assist.kind}.');
    }
    return _outcomeOf(await _documents.apply(match.edit));
  });

  /// Extracts the widget created at [target], with its subtree, to a new
  /// widget class called [name].
  ///
  /// [documentVersion] is the version of the document that the caller read.
  /// Throws an [EditFailure] and changes nothing when [name] is not a class
  /// name or the server refuses.
  Future<EditOutcome> extractWidget(
    SourceLocation target, {
    required int documentVersion,
    required String name,
  }) => _enqueue(() {
    final document = _documents.documentAt(
      target.filePath,
      version: documentVersion,
    );
    if (!_className.hasMatch(name)) {
      throw UnsupportedEdit('$name is not a name for a class.');
    }
    _reader.openDocumentOf(target);
    return _runOnServer(
      (server) => server.extractWidget(
        target.filePath,
        offset: document.offsetAt(target.position),
        documentVersion: documentVersion,
        name: name,
      ),
    );
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

  /// Asks the server to give [newValue] to the argument [name], and
  /// completes with what the server made the store apply.
  Future<EditOutcome> _editThroughServer(
    SourceLocation target,
    int documentVersion,
    String name,
    Object? newValue,
  ) => _runOnServer(
    (server) => server.editArgument(
      target,
      documentVersion: documentVersion,
      name: name,
      newValue: newValue,
    ),
  );

  /// Sends [request] to the analysis server and completes with what the
  /// server made the store apply while it answered.
  Future<EditOutcome> _runOnServer(
    Future<void> Function(LspClient server) request,
  ) async {
    final server = _server();
    if (server == null) throw const ToolUnavailable(WidgetReader.serverName);
    try {
      await request(server);
    } on LspRequestFailed catch (failure) {
      throw UnsupportedEdit(failure.message);
    }
    return _outcomeOf(_merge(_appliedByServer));
  }

  /// Applies [edit] to the document of [target] and asks for the reload.
  Future<EditOutcome> _applyTo(SourceLocation target, TextEdit edit) async =>
      _outcomeOf(
        await _documents.apply(
          WorkspaceEdit([
            (filePath: target.filePath, edits: [edit]),
          ]),
        ),
      );

  /// Completes with where the value of the argument [name] of the widget
  /// created at [target] is in the code, or with `null` when the code gives
  /// no such argument.
  Future<DocumentRange?> _valueRangeOf(
    SourceLocation target,
    String name,
  ) async {
    final tree = await _reader.sourceTree(target.filePath);
    for (final root in tree.roots) {
      final node = root.nodeAt(target.position);
      if (node != null) return node.argumentRanges[name];
    }
    throw const UnsupportedEdit('No widget is created at the position.');
  }

  /// Completes with the value that the server takes for [source] as the
  /// argument [name] of the constructor at [target], inside a record, or
  /// with `null` when [source] is not a literal that the server can write.
  ///
  /// The record tells a literal `null` apart from no literal at all.
  Future<({Object? value})?> _literalValueFor(
    SourceLocation target,
    String name,
    String source,
  ) async {
    final arguments = await _reader.arguments(target);
    final argument = arguments.where((each) => each.name == name).firstOrNull;
    if (argument == null) {
      throw UnsupportedEdit('The widget has no argument $name.');
    }
    if (!argument.isEditable) return null;
    try {
      final literal = ArgumentLiteral(
        argument.kind,
        enumOptions: argument.options,
      );
      return (value: literal.valueOf(source));
    } on FormatException {
      return null;
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
