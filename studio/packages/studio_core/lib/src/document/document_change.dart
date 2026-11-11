import 'package:studio_protocol/studio_protocol.dart' show ChangeOrigin;

import 'text_document.dart';

/// A document of the project after a change that is already on disk.
///
/// `document` is the new text with its new version, and `origin` tells who
/// made the change.
typedef DocumentChange = ({
  String filePath,
  TextDocument document,
  ChangeOrigin origin,
});
