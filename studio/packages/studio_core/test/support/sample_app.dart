import 'dart:io';

import 'package:path/path.dart' as path;

/// Source of the sample app. The `Column` starts at line 11, character 14,
/// counting from zero.
const sampleAppSource = '''
import 'package:flutter/material.dart';

void main() => runApp(const SampleApp());

class SampleApp extends StatelessWidget {
  const SampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text('Hello')],
        ),
      ),
    );
  }
}
''';

/// Creates under [parent], with the `flutter` found on `PATH`, a Flutter
/// project named `sample_app` whose `lib/main.dart` is [sampleAppSource],
/// and returns its path.
String createSampleApp(Directory parent) {
  final result = Process.runSync('flutter', [
    'create',
    '--platforms=linux',
    '--project-name=sample_app',
    'sample_app',
  ], workingDirectory: parent.path);
  if (result.exitCode != 0) {
    throw StateError('flutter create failed: ${result.stderr}');
  }
  final rootPath = path.join(parent.path, 'sample_app');
  File(path.join(rootPath, 'lib', 'main.dart'))
      .writeAsStringSync(sampleAppSource);
  return rootPath;
}
