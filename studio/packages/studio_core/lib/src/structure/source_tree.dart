import 'source_node.dart';

/// The widgets that the source of one file creates, at one version of its
/// document. `roots` are the widgets that no other widget contains.
typedef SourceTree = ({
  String filePath,
  int documentVersion,
  List<SourceNode> roots,
});
