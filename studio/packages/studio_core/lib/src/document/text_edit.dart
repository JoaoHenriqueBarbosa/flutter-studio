/// A position in a document, as the Language Server Protocol counts it.
///
/// Both numbers start at zero, and `character` counts UTF-16 code units
/// from the start of the line.
typedef DocumentPosition = ({int line, int character});

/// The text between two positions of a document. `end` is exclusive.
typedef DocumentRange = ({DocumentPosition start, DocumentPosition end});

/// Replacement of the text in `range` by `newText`.
///
/// An empty range inserts, and an empty `newText` deletes.
typedef TextEdit = ({DocumentRange range, String newText});
