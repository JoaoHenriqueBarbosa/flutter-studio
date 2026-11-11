/// Who changed a document of the project.
enum ChangeOrigin {
  /// Studio changed the document, through the document store.
  studio,

  /// Another process changed the file on disk.
  external,
}
