import 'package:devtools_app/devtools_app.dart';
import 'package:studio_core/studio_core.dart' show ArgumentLiteral;
import 'package:studio_protocol/studio_protocol.dart';

/// The editor client of the inherited property panel, with every edit sent
/// to the `Studio` service (FR-API-002).
///
/// An Adapter over [EditorClient], which the panel requires by type: it
/// inherits the reading of arguments and replaces the operations that
/// change code. The inherited client would ask the analysis server for the
/// edit directly, around the service.
final class StudioEditorClient extends EditorClient {
  /// Creates a client that reads through [dtdManager] and edits through
  /// [_studio].
  StudioEditorClient(super.dtdManager, this._studio);

  final StudioApi _studio;

  /// Kind of each argument of the widget that was read last, by name. The
  /// panel edits with the value alone, and the kind tells how to write it
  /// as source.
  final _argumentKinds = <String, String>{};

  @override
  Future<EditableArgumentsResult?> getEditableArguments({
    required TextDocument textDocument,
    required CursorPosition position,
    required String screenId,
  }) async {
    final result = await super.getEditableArguments(
      textDocument: textDocument,
      position: position,
      screenId: screenId,
    );
    _argumentKinds
      ..clear()
      ..addAll({
        for (final argument in result?.args ?? <EditableArgument>[])
          argument.name: argument.type,
      });
    return result;
  }

  /// Completes with no refactor, so that the panel offers none.
  ///
  /// The inherited panel runs a refactor as a command of the analysis
  /// server, around the service. The refactors come back with the
  /// operation of the service that covers each one.
  @override
  Future<CodeActionResult?> getRefactors({
    required TextDocument textDocument,
    required EditorRange range,
    required String screenId,
  }) async => null;

  @override
  Future<GenericApiResponse> editArgument<T>({
    required TextDocument textDocument,
    required CursorPosition position,
    required String name,
    required T value,
    required String screenId,
  }) async {
    final documentVersion = textDocument.version;
    if (documentVersion == null) return _refusal;
    final literal = ArgumentLiteral(_argumentKinds[name] ?? '');
    try {
      await _studio.setProperty(
        target: WidgetRef(
          uri: textDocument.uriAsString,
          position: Position(
            line: position.line,
            character: position.character,
          ),
          documentVersion: documentVersion,
        ),
        name: name,
        value: Expression(source: literal.sourceOf(value)),
      );
      return GenericApiResponse(success: true);
    } on StudioFault catch (fault) {
      return GenericApiResponse(
        success: false,
        errorMessage: '$fault',
        errorCode: fault.code.code,
      );
    }
  }

  @override
  Future<GenericApiResponse> executeCommand({
    required String commandName,
    required List<Object?> commandArgs,
    required String screenId,
  }) async => _refusal;

  GenericApiResponse get _refusal => GenericApiResponse(
    success: false,
    errorMessage: StudioErrorCode.unsupportedTarget.message,
    errorCode: StudioErrorCode.unsupportedTarget.code,
  );
}
