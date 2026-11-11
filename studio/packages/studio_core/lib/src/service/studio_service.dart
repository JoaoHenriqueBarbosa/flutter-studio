import 'dart:io';

import 'package:studio_protocol/studio_protocol.dart';

import '../document/applied_edit.dart';
import '../document/document_store.dart';
import '../document/edit_failure.dart';
import '../document/source_location.dart';
import '../document/text_edit.dart' as document;
import '../edit/argument_literal.dart';
import '../edit/argument_reader.dart';
import '../edit/edit_outcome.dart';
import '../edit/edit_pipeline.dart';
import '../lsp/editable_argument.dart';
import '../selection/selection_controller.dart';
import '../selection/widget_location.dart';

/// The `Studio` service: the single entry for every operation (ADR-0012).
///
/// A Facade over the documents, the selection and the edit pipeline. It
/// converts between the types of the contract and the ones of the core, and
/// turns every [EditFailure] into the [StudioFault] that the contract names.
final class StudioService implements StudioApi {
  /// Creates the service over the parts of an open project.
  const StudioService(
    this._documents,
    this._selection,
    this._pipeline,
    this._reader,
  );

  final DocumentStore _documents;

  final SelectionController _selection;

  final EditPipeline _pipeline;

  final ArgumentReader _reader;

  @override
  Future<VersionInfo> getVersion() async =>
      const VersionInfo(version: StudioContract.version);

  @override
  Future<WidgetRef?> getSelection() async =>
      switch (_selection.selection.value) {
        null => null,
        final selected => _referenceOf(selected),
      };

  @override
  Future<WidgetRef> select({required WidgetRef target}) => _guarded(
    () async => _referenceOf(_selection.select(_locationOf(target))),
  );

  @override
  Future<List<Property>> getProperties({required WidgetRef target}) =>
      _guarded(() async {
        final arguments = await _reader.read(_locationOf(target));
        return arguments.map(_propertyOf).toList();
      });

  @override
  Future<EditResult> setProperty({
    required WidgetRef target,
    required String name,
    required Expression? value,
  }) => _guarded(
    () async => _resultOf(
      await _pipeline.setArgument(
        _locationOf(target),
        documentVersion: target.documentVersion,
        name: name,
        source: value?.source,
      ),
    ),
  );

  @override
  Future<EditResult> undo() =>
      _guarded(() async => _resultOf(await _pipeline.undo()));

  @override
  Future<EditResult> redo() =>
      _guarded(() async => _resultOf(await _pipeline.redo()));

  /// Runs [operation] and reports its failure as the contract names it.
  Future<T> _guarded<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on EditFailure catch (failure) {
      throw switch (failure) {
        StaleDocument(:final currentVersion) => StudioFault(
          StudioErrorCode.staleDocument,
          data: currentVersion,
        ),
        EditOutsideProject(:final filePath) => StudioFault(
          StudioErrorCode.notInProject,
          data: '${Uri.file(filePath)}',
        ),
        UnsupportedEdit(:final reason) => StudioFault(
          StudioErrorCode.unsupportedTarget,
          data: reason,
        ),
        InvalidEdit(:final message) => StudioFault(
          StudioErrorCode.unsupportedTarget,
          data: message,
        ),
        ToolUnavailable(:final toolName) => StudioFault(
          StudioErrorCode.toolchainUnavailable,
          data: toolName,
        ),
      };
    } on FileSystemException catch (exception) {
      throw StudioFault(
        StudioErrorCode.unsupportedTarget,
        data: exception.message,
      );
    }
  }

  /// Returns where [reference] points, after checking that its document is
  /// in the project and at the version of the reference.
  SourceLocation _locationOf(WidgetRef reference) {
    final uri = Uri.tryParse(reference.uri);
    if (uri == null || !uri.isScheme('file')) {
      throw StudioFault(StudioErrorCode.notInProject, data: reference.uri);
    }
    final filePath = uri.toFilePath();
    _documents.documentAt(filePath, version: reference.documentVersion);
    return (
      filePath: filePath,
      position: (
        line: reference.position.line,
        character: reference.position.character,
      ),
    );
  }

  WidgetRef _referenceOf(WidgetLocation location) => WidgetRef(
    uri: '${Uri.file(location.filePath)}',
    position: _positionOf(location.position),
    documentVersion: location.documentVersion,
  );

  Position _positionOf(document.DocumentPosition position) =>
      Position(line: position.line, character: position.character);

  Property _propertyOf(EditableArgument argument) {
    final literal = ArgumentLiteral(argument.kind);
    final value = argument.value;
    final defaultValue = argument.defaultValue;
    final source = value == null
        ? argument.displayValue
        : literal.sourceOf(value);
    return Property(
      name: argument.name,
      type: argument.kind,
      expression: argument.hasArgument && source != null
          ? Expression(source: source)
          : null,
      defaultValue: defaultValue == null
          ? null
          : Expression(source: literal.sourceOf(defaultValue)),
      isSet: argument.hasArgument,
      isEditable: argument.isEditable,
      options: argument.options,
      documentation: argument.documentation,
    );
  }

  EditResult _resultOf(EditOutcome outcome) {
    final edit = outcome.edit;
    return EditResult(
      applied: edit != null,
      changes: edit == null ? const [] : _changesOf(edit),
      documentVersions: {
        if (edit != null)
          for (final MapEntry(key: filePath, value: version)
              in edit.versions.entries)
            '${Uri.file(filePath)}': version,
      },
      reload: outcome.isReloadRequested
          ? ReloadKind.hotReload
          : ReloadKind.none,
    );
  }

  List<TextDocumentEdit> _changesOf(AppliedEdit edit) => [
    for (final change in edit.changes)
      TextDocumentEdit(
        uri: '${Uri.file(change.filePath)}',
        edits: [
          for (final textEdit in change.edits)
            TextEdit(
              range: Range(
                start: _positionOf(textEdit.range.start),
                end: _positionOf(textEdit.range.end),
              ),
              newText: textEdit.newText,
            ),
        ],
      ),
  ];
}
