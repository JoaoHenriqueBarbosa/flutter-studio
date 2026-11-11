import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'document_store.dart';

/// Watches the Dart files of the project for changes made by other
/// processes, such as another editor or a version control tool
/// (FR-DOC-003).
///
/// The files that the store has read are read again, which gives them a
/// new version. No lock is taken on any file (NFR-COMP-001).
final class ProjectFileWatcher {
  /// Creates the watcher of the project at [_rootPath], whose documents
  /// are in [_documents].
  ///
  /// A burst of file events is reported once, after [quietPeriod] with no
  /// new event: an editor that saves a file touches it more than once.
  ProjectFileWatcher(
    this._rootPath,
    this._documents, {
    this.quietPeriod = const Duration(milliseconds: 200),
  });

  static const _dartExtension = '.dart';

  /// Directories that tools write to and that hold no source of the
  /// project. Hidden directories are skipped as well.
  static const _generatedDirectories = {'build'};

  final String _rootPath;

  final DocumentStore _documents;

  /// How long the watcher waits after the last file event before it
  /// reports the files that changed.
  final Duration quietPeriod;

  final _externalChanges = StreamController<Set<String>>.broadcast();

  final _pendingPaths = <String>{};

  /// The subscription of each watched directory, by path. On Linux there
  /// is one for each directory of the project; elsewhere, one for the root.
  final _watches = <String, StreamSubscription<FileSystemEvent>>{};

  Timer? _quietTimer;

  /// The Dart files that another process created, changed or removed, one
  /// set for each burst of changes. The changes that the store itself wrote
  /// are not reported.
  Stream<Set<String>> get externalChanges => _externalChanges.stream;

  /// Starts watching. Does nothing when the watcher has started already.
  void start() => _watch(Directory(_rootPath));

  /// Stops watching and releases the resources of the watcher.
  Future<void> dispose() async {
    _quietTimer?.cancel();
    for (final watch in _watches.values.toList()) {
      await watch.cancel();
    }
    _watches.clear();
    await _externalChanges.close();
  }

  /// Watches [directory] and, on Linux, each directory under it.
  ///
  /// The file watcher of Linux does not reach into subdirectories, so each
  /// one gets its own watch. A directory that tools write to is left out.
  void _watch(Directory directory) {
    final isRoot = path.equals(directory.path, _rootPath);
    if (_watches.containsKey(directory.path) ||
        (!isRoot && !_holdsSources(directory.path))) {
      return;
    }
    _watches[directory.path] = directory
        .watch(recursive: !Platform.isLinux)
        .listen(
          _handleEvent,
          onDone: () => _watches.remove(directory.path),
          // The directory was removed, or the system refused the watch.
          onError: (Object _) => _watches.remove(directory.path),
        );
    if (!Platform.isLinux) return;
    try {
      directory.listSync().whereType<Directory>().forEach(_watch);
    } on FileSystemException {
      // The directory was removed while it was being listed.
    }
  }

  void _handleEvent(FileSystemEvent event) {
    if (event is FileSystemCreateEvent && event.isDirectory) {
      _watch(Directory(event.path));
    }
    final paths = [
      event.path,
      if (event is FileSystemMoveEvent) ?event.destination,
    ].where(_isSource);
    if (paths.isEmpty) return;
    _pendingPaths.addAll(paths.map(path.normalize));
    _quietTimer?.cancel();
    _quietTimer = Timer(quietPeriod, _reportPending);
  }

  bool _isSource(String filePath) =>
      filePath.endsWith(_dartExtension) && _holdsSources(filePath);

  /// Whether no part of [entityPath], below the root, is hidden or is a
  /// directory that tools write to.
  bool _holdsSources(String entityPath) {
    final names = path.split(path.relative(entityPath, from: _rootPath));
    return !names.any(
      (name) => name.startsWith('.') || _generatedDirectories.contains(name),
    );
  }

  /// Reports the pending files that changed without the store. A file that
  /// the store never read counts as changed, because every write of the
  /// store is to a file it has read.
  void _reportPending() {
    final changed = {
      for (final filePath in _pendingPaths)
        if (!_documents.isLoaded(filePath) || _documents.refresh(filePath))
          filePath,
    };
    _pendingPaths.clear();
    if (changed.isNotEmpty) _externalChanges.add(changed);
  }
}
