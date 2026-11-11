import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/studio_core.dart';

import '../support/fake_process.dart';

/// A child that records the processes it was attached to.
final class _RecordingChild implements ToolchainChild {
  final attached = <Process>[];

  @override
  String get name => 'tool';

  @override
  String get executablePath => '/sdk/bin/dart';

  @override
  List<String> get arguments => const ['language-server'];

  @override
  Future<void> attach(Process process) async => attached.add(process);
}

void main() {
  group('ToolchainSupervisor', () {
    late List<FakeProcess> started;
    late List<String> commandLines;
    late ToolchainSupervisor supervisor;

    setUp(() {
      started = [];
      commandLines = [];
      supervisor = ToolchainSupervisor(
        startProcess: (executable, arguments) async {
          commandLines.add('$executable ${arguments.join(' ')}');
          final process = FakeProcess();
          started.add(process);
          return process;
        },
      );
    });

    // Verifies: FR-PRJ-004
    test('starts the child and attaches it before reporting it', () async {
      final child = _RecordingChild();

      await supervisor.start(child);

      expect(commandLines, ['/sdk/bin/dart language-server']);
      expect(child.attached, started);
      expect(supervisor.stateOf('tool')?.value, ToolchainState.running);
    });

    // Verifies: NFR-REL-002
    test('restarts and attaches again a child that ends', () async {
      final child = _RecordingChild();
      await supervisor.start(child);

      started.single.crash();
      await pumpEventQueue();

      expect(started, hasLength(2));
      expect(child.attached, started);
      expect(supervisor.stateOf('tool')?.value, ToolchainState.running);
    });

    // Verifies: NFR-REL-002
    test('gives up on a child that keeps failing to start', () async {
      await supervisor.start(_RecordingChild());

      for (var attempt = 0; attempt < 3; attempt++) {
        started.last.crash();
        await pumpEventQueue();
      }

      expect(started, hasLength(3));
      expect(supervisor.stateOf('tool')?.value, ToolchainState.failed);
    });

    // Verifies: NFR-REL-002
    test('does not restart a child that it stopped', () async {
      await supervisor.start(_RecordingChild());

      await supervisor.stop();
      await pumpEventQueue();

      expect(started, hasLength(1));
      expect(supervisor.stateOf('tool')?.value, ToolchainState.stopped);
    });
  });
}
