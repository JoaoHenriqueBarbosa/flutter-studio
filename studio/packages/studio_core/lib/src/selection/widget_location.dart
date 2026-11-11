import '../document/text_edit.dart';

/// Where a widget is created: the file, the position of the constructor
/// call and the version of the document in which that position is valid.
typedef WidgetLocation = ({
  String filePath,
  DocumentPosition position,
  int documentVersion,
});
