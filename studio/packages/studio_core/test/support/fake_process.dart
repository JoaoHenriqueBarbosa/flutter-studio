import 'dart:async';
import 'dart:io';

/// A [Process] that runs nothing and ends when the test says so.
final class FakeProcess implements Process {
  final _exitCode = Completer<int>();

  @override
  Future<int> get exitCode => _exitCode.future;

  @override
  int get pid => 0;

  @override
  Stream<List<int>> get stdout => const Stream.empty();

  @override
  Stream<List<int>> get stderr => const Stream.empty();

  @override
  IOSink get stdin => throw UnsupportedError('The fake has no stdin.');

  /// Ends the process as if it had crashed.
  void crash() => _exitCode.complete(1);

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    if (!_exitCode.isCompleted) _exitCode.complete(0);
    return true;
  }
}
