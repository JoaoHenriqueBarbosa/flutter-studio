// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'studio_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class StudioLocalizationsEn extends StudioLocalizations {
  StudioLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get openProjectAction => 'Open project';

  @override
  String get openProjectHint =>
      'Choose the directory of a Flutter project to start.';

  @override
  String openingProject(String projectPath) {
    return 'Opening $projectPath…';
  }

  @override
  String notAFlutterProject(String projectPath) {
    return '$projectPath is not a Flutter project.';
  }

  @override
  String get sdkNotFound =>
      'No Flutter SDK was found. Add Flutter to PATH or pin a version in the project.';

  @override
  String sdkNotFoundAt(String sdkPath) {
    return 'No Flutter SDK was found at $sdkPath.';
  }

  @override
  String sdkOutsideWindow(String found, String window) {
    return 'The project uses Flutter $found. Studio works with the versions $window.';
  }

  @override
  String projectSummary(String name, String version) {
    return '$name · Flutter $version';
  }

  @override
  String get runAction => 'Run';

  @override
  String get runInWindowAction => 'Run in a window';

  @override
  String get stopAction => 'Stop';

  @override
  String get hotRestartAction => 'Restart';

  @override
  String get undoAction => 'Undo';

  @override
  String get redoAction => 'Redo';

  @override
  String get wrapWithAction => 'Wrap with';

  @override
  String get removeWidgetAction => 'Remove the widget and keep its children';

  @override
  String get moveUpAction => 'Move up among the siblings';

  @override
  String get moveDownAction => 'Move down among the siblings';

  @override
  String get swapWithParentAction => 'Swap with the parent';

  @override
  String get swapWithChildAction => 'Swap with the child';

  @override
  String get startingApp => 'Starting the app…';

  @override
  String get widgetTreePlaceholder => 'Run the app to see its widget tree.';

  @override
  String get structureTitle => 'Structure';

  @override
  String get structurePlaceholder => 'No widget is created in this file.';

  @override
  String get canvasTitle => 'Canvas';

  @override
  String get inspectorTitle => 'Inspector';

  @override
  String get canvasPlaceholder => 'Run the app to see it here.';

  @override
  String get canvasStale => 'The app is not running. This is its last frame.';

  @override
  String get canvasNotTracked =>
      'This app was built without the tracking of widget creation. Selecting on the canvas is off for this run.';

  @override
  String get propertiesTitle => 'Properties';

  @override
  String get outputTitle => 'Output';
}
