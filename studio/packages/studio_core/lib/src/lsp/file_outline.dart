import 'outline_node.dart';

/// The Flutter Outline of one file, as the analysis server publishes it
/// after it analyzes the file. `root` is the node of the whole file.
typedef FileOutline = ({String filePath, OutlineNode root});
