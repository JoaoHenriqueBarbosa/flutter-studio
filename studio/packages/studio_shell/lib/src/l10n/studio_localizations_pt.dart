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
  String get runInWindowAction => 'Executar em janela';

  @override
  String get stopAction => 'Parar';

  @override
  String get hotRestartAction => 'Reiniciar';

  @override
  String get undoAction => 'Desfazer';

  @override
  String get redoAction => 'Refazer';

  @override
  String get wrapWithAction => 'Envolver com';

  @override
  String get removeWidgetAction => 'Remover o widget e manter os filhos';

  @override
  String get moveUpAction => 'Mover para cima entre os irmãos';

  @override
  String get moveDownAction => 'Mover para baixo entre os irmãos';

  @override
  String get swapWithParentAction => 'Trocar com o pai';

  @override
  String get swapWithChildAction => 'Trocar com o filho';

  @override
  String get extractWidgetAction => 'Extrair para um widget novo';

  @override
  String get extractWidgetNameLabel => 'Nome da classe do widget novo';

  @override
  String get extractAction => 'Extrair';

  @override
  String get cancelAction => 'Cancelar';

  @override
  String get startingApp => 'Iniciando o app…';

  @override
  String get widgetTreePlaceholder =>
      'Execute o app para ver a árvore de widgets.';

  @override
  String get structureTitle => 'Estrutura';

  @override
  String get structurePlaceholder => 'Nenhum widget é criado neste arquivo.';

  @override
  String get canvasTitle => 'Canvas';

  @override
  String get inspectorTitle => 'Inspetor';

  @override
  String get canvasPlaceholder => 'Execute o app para vê-lo aqui.';

  @override
  String get canvasStale =>
      'O app não está em execução. Este é o último quadro.';

  @override
  String get canvasNotTracked =>
      'Este app foi compilado sem o rastreamento de criação de widgets. A seleção no canvas fica desligada nesta execução.';

  @override
  String get propertiesTitle => 'Propriedades';

  @override
  String get outputTitle => 'Saída';
}
