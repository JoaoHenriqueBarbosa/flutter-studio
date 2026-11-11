import '../document/workspace_edit.dart';
import 'widget_assist.dart';

/// An assist that the analysis server offers at a position, with the edit
/// that performs it.
typedef ServerAssist = ({WidgetAssist assist, WorkspaceEdit edit});
