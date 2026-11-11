import 'dart:io';

import 'package:path/path.dart' as path;

/// Creates under [parent] a directory that looks like the Flutter SDK of
/// version [version] and returns its path.
String createSdk(Directory parent, {required String version}) {
  final rootPath = path.join(parent.path, 'flutter_$version');
  File(path.join(rootPath, 'bin', 'cache', 'flutter.version.json'))
    ..createSync(recursive: true)
    ..writeAsStringSync('{"flutterVersion": "$version"}');
  File(path.join(rootPath, 'bin', 'flutter')).createSync();
  return rootPath;
}

/// Creates under [parent] a Flutter project named `sample_app` and returns
/// its path.
String createFlutterProject(Directory parent) {
  final rootPath = path.join(parent.path, 'sample_app');
  File(path.join(rootPath, 'pubspec.yaml'))
    ..createSync(recursive: true)
    ..writeAsStringSync('''
name: sample_app
dependencies:
  flutter:
    sdk: flutter
''');
  return rootPath;
}
