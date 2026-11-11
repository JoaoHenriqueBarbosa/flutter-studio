// GENERATED CODE - DO NOT MODIFY BY HAND
// Source: lib/l10n/*.arb. Generator: flutter gen-l10n.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'studio_localizations_en.dart';
import 'studio_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of StudioLocalizations
/// returned by `StudioLocalizations.of(context)`.
///
/// Applications need to include `StudioLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/studio_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: StudioLocalizations.localizationsDelegates,
///   supportedLocales: StudioLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the StudioLocalizations.supportedLocales
/// property.
abstract class StudioLocalizations {
  StudioLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static StudioLocalizations of(BuildContext context) {
    return Localizations.of<StudioLocalizations>(context, StudioLocalizations)!;
  }

  static const LocalizationsDelegate<StudioLocalizations> delegate =
      _StudioLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// Label of the button that chooses a project directory.
  ///
  /// In en, this message translates to:
  /// **'Open project'**
  String get openProjectAction;

  /// Text shown while no project is open.
  ///
  /// In en, this message translates to:
  /// **'Choose the directory of a Flutter project to start.'**
  String get openProjectHint;

  /// Text shown while a project is being opened.
  ///
  /// In en, this message translates to:
  /// **'Opening {projectPath}…'**
  String openingProject(String projectPath);

  /// Error shown when the chosen directory has no pubspec that depends on Flutter.
  ///
  /// In en, this message translates to:
  /// **'{projectPath} is not a Flutter project.'**
  String notAFlutterProject(String projectPath);

  /// Error shown when no source names a Flutter SDK.
  ///
  /// In en, this message translates to:
  /// **'No Flutter SDK was found. Add Flutter to PATH or pin a version in the project.'**
  String get sdkNotFound;

  /// Error shown when the directory that should hold the SDK holds none.
  ///
  /// In en, this message translates to:
  /// **'No Flutter SDK was found at {sdkPath}.'**
  String sdkNotFoundAt(String sdkPath);

  /// Error shown when the SDK of the project is outside the supported versions.
  ///
  /// In en, this message translates to:
  /// **'The project uses Flutter {found}. Studio works with the versions {window}.'**
  String sdkOutsideWindow(String found, String window);

  /// Name of the open project and version of its SDK, in the toolbar.
  ///
  /// In en, this message translates to:
  /// **'{name} · Flutter {version}'**
  String projectSummary(String name, String version);

  /// Label of the button that starts the app.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get runAction;

  /// Label of the button that builds the app for the desktop and opens it in its own window.
  ///
  /// In en, this message translates to:
  /// **'Run in a window'**
  String get runInWindowAction;

  /// Label of the button that ends the app.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopAction;

  /// Label of the button that restarts the app with the code on disk.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get hotRestartAction;

  /// Label of the button that undoes the last edit.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoAction;

  /// Label of the button that applies again the edit that was undone.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redoAction;

  /// Label of the menu that wraps the selected widget with another widget.
  ///
  /// In en, this message translates to:
  /// **'Wrap with'**
  String get wrapWithAction;

  /// Tooltip of the button that removes the selected widget from the code.
  ///
  /// In en, this message translates to:
  /// **'Remove the widget and keep its children'**
  String get removeWidgetAction;

  /// Tooltip of the button that moves the selected widget before its previous sibling.
  ///
  /// In en, this message translates to:
  /// **'Move up among the siblings'**
  String get moveUpAction;

  /// Tooltip of the button that moves the selected widget after its next sibling.
  ///
  /// In en, this message translates to:
  /// **'Move down among the siblings'**
  String get moveDownAction;

  /// Tooltip of the button that swaps the selected widget with its parent.
  ///
  /// In en, this message translates to:
  /// **'Swap with the parent'**
  String get swapWithParentAction;

  /// Tooltip of the button that swaps the selected widget with its child.
  ///
  /// In en, this message translates to:
  /// **'Swap with the child'**
  String get swapWithChildAction;

  /// Tooltip of the button and title of the dialog that extract the selected widget to a new class.
  ///
  /// In en, this message translates to:
  /// **'Extract to a new widget'**
  String get extractWidgetAction;

  /// Label of the field with the name of the class that the extraction creates.
  ///
  /// In en, this message translates to:
  /// **'Name of the new widget class'**
  String get extractWidgetNameLabel;

  /// Label of the button that confirms the extraction.
  ///
  /// In en, this message translates to:
  /// **'Extract'**
  String get extractAction;

  /// Label of the button that closes a dialog without doing anything.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// Text shown in the toolbar while the app is being built and started.
  ///
  /// In en, this message translates to:
  /// **'Starting the app…'**
  String get startingApp;

  /// Text shown in place of the widget tree while the app is not running.
  ///
  /// In en, this message translates to:
  /// **'Run the app to see its widget tree.'**
  String get widgetTreePlaceholder;

  /// Title of the pane with the tree of widgets derived from the source of a file.
  ///
  /// In en, this message translates to:
  /// **'Structure'**
  String get structureTitle;

  /// Text shown in place of the source tree when the file creates no widget or the tree is not known yet.
  ///
  /// In en, this message translates to:
  /// **'No widget is created in this file.'**
  String get structurePlaceholder;

  /// Title of the tab that shows the frames of the running app.
  ///
  /// In en, this message translates to:
  /// **'Canvas'**
  String get canvasTitle;

  /// Title of the tab with the widget tree of the running app.
  ///
  /// In en, this message translates to:
  /// **'Inspector'**
  String get inspectorTitle;

  /// Text shown in the canvas before the app has drawn anything.
  ///
  /// In en, this message translates to:
  /// **'Run the app to see it here.'**
  String get canvasPlaceholder;

  /// Notice over the canvas when the frame on screen is of an app that ended.
  ///
  /// In en, this message translates to:
  /// **'The app is not running. This is its last frame.'**
  String get canvasStale;

  /// Notice over the canvas when the running app cannot link its widgets to the source.
  ///
  /// In en, this message translates to:
  /// **'This app was built without the tracking of widget creation. Selecting on the canvas is off for this run.'**
  String get canvasNotTracked;

  /// Size of the selected widget in the running app, in logical pixels.
  ///
  /// In en, this message translates to:
  /// **'Size {width} × {height}'**
  String layoutSize(String width, String height);

  /// Constraints that the parent gives to the selected widget.
  ///
  /// In en, this message translates to:
  /// **'Constraints: width {minWidth} to {maxWidth}, height {minHeight} to {maxHeight}'**
  String layoutConstraints(
    String minWidth,
    String maxWidth,
    String minHeight,
    String maxHeight,
  );

  /// Flex factor and flex fit of the selected widget inside a row or a column.
  ///
  /// In en, this message translates to:
  /// **'Flex {flex}, fit {fit}'**
  String layoutFlex(String flex, String fit);

  /// Shown in place of a maximum that a constraint does not have.
  ///
  /// In en, this message translates to:
  /// **'unbounded'**
  String get layoutUnbounded;

  /// Title of the pane that edits the arguments of the selected widget.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get propertiesTitle;

  /// Title of the pane with the output of the build and of the app.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get outputTitle;
}

class _StudioLocalizationsDelegate
    extends LocalizationsDelegate<StudioLocalizations> {
  const _StudioLocalizationsDelegate();

  @override
  Future<StudioLocalizations> load(Locale locale) {
    return SynchronousFuture<StudioLocalizations>(
      lookupStudioLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_StudioLocalizationsDelegate old) => false;
}

StudioLocalizations lookupStudioLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return StudioLocalizationsEn();
    case 'pt':
      return StudioLocalizationsPt();
  }

  throw FlutterError(
    'StudioLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
