import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'toolchain_child.dart';
import 'toolchain_state.dart';

/// Starts a process. The seam between the supervisor and the system.
typedef ProcessStarter = Future<Process> Function(
  String executable,
  List<String> arguments,
);

/// Starts, watches and restarts the tools of the project SDK
/// (NFR-REL-002).
///
/// Applies the State pattern: each child is in one [ToolchainState], and
/// only the supervisor moves it.
final class ToolchainSupervisor {
  /// Creates a supervisor that starts processes with [_startProcess].
  ToolchainSupervisor({this._startProcess = Process.start});

  /// A process that ends before this time counts as failing to start.
  static const _minimumUptime = Duration(seconds: 5);

  /// How many times in a row a child may fail to start before the
  /// supervisor gives up on it.
  static const _startAttemptLimit = 3;

  final ProcessStarter _startProcess;

  final _states = <String, ValueNotifier<ToolchainState>>{};

  final _processes = <String, Process>{};

  var _stopping = false;

  /// The state of the child named [name], or `null` when no child with
  /// that name was started.
  ValueListenable<ToolchainState>? stateOf(String name) => _states[name];

  /// Starts [child] and keeps it running until [stop].
  ///
  /// Completes when the first process of the child is ready for use.
  Future<void> start(ToolchainChild child) async {
    final state = _states[child.name] = ValueNotifier(ToolchainState.starting);
    final process = await _launch(child);
    state.value = ToolchainState.running;
    unawaited(_watch(child, process, state));
  }

  /// Ends every child. Completes when all the processes have ended.
  Future<void> stop() async {
    _stopping = true;
    final processes = _processes.values.toList();
    for (final process in processes) {
      process.kill();
    }
    await Future.wait([for (final process in processes) process.exitCode]);
    for (final state in _states.values) {
      state.value = ToolchainState.stopped;
    }
  }

  Future<Process> _launch(ToolchainChild child) async {
    final process = await _startProcess(child.executablePath, child.arguments);
    _processes[child.name] = process;
    await child.attach(process);
    return process;
  }

  Future<void> _watch(
    ToolchainChild child,
    Process firstProcess,
    ValueNotifier<ToolchainState> state,
  ) async {
    var process = firstProcess;
    var failedStarts = 0;
    while (true) {
      final uptime = Stopwatch()..start();
      await process.exitCode;
      if (_stopping) return;
      failedStarts = uptime.elapsed < _minimumUptime ? failedStarts + 1 : 0;
      if (failedStarts >= _startAttemptLimit) {
        state.value = ToolchainState.failed;
        return;
      }
      state.value = ToolchainState.restarting;
      process = await _launch(child);
      state.value = ToolchainState.running;
    }
  }
}
