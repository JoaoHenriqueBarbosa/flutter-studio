// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'studio_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class StudioLocalizationsPt extends StudioLocalizations {
  StudioLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get openProjectAction => 'Abrir projeto';

  @override
  String get openProjectHint =>
      'Escolha o diretório de um projeto Flutter para começar.';

  @override
  String openingProject(String projectPath) {
    return 'Abrindo $projectPath…';
  }

  @override
  String notAFlutterProject(String projectPath) {
    return '$projectPath não é um projeto Flutter.';
  }

  @override
  String get sdkNotFound =>
      'Nenhum SDK Flutter foi encontrado. Ponha o Flutter no PATH ou fixe uma versão no projeto.';

  @override
  String sdkNotFoundAt(String sdkPath) {
    return 'Nenhum SDK Flutter foi encontrado em $sdkPath.';
  }

  @override
  String sdkOutsideWindow(String found, String window) {
    return 'O projeto usa o Flutter $found. O Studio trabalha com as versões $window.';
  }

  @override
  String projectSummary(String name, String version) {
    return '$name · Flutter $version';
  }

  @override
  String get runAction => 'Executar';

  @override
  String get stopAction => 'Parar';

  @override
  String get hotRestartAction => 'Reiniciar';

  @override
  String get undoAction => 'Desfazer';

  @override
  String get redoAction => 'Refazer';

  @override
  String get startingApp => 'Iniciando o app…';

  @override
  String get widgetTreePlaceholder =>
      'Execute o app para ver a árvore de widgets.';

  @override
  String get propertiesTitle => 'Propriedades';

  @override
  String get outputTitle => 'Saída';
}
