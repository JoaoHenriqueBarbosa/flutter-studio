# Changelog

Registro técnico do que muda no repositório. O formato segue o [Keep a Changelog 1.1.0](https://keepachangelog.com/pt-BR/1.1.0/). O registro informal, para quem aprova, fica em `JOURNAL.md`.

## Não lançado

### Adicionado

- Baseline de projeto em `docs/`: guia, SRS, arquitetura (arc42), ADR-0001 a ADR-0013, interfaces (ICD), plano de verificação e padrão de código.
- `CLAUDE.md` na raiz, que importa `docs/guide.md` e `docs/engineering/coding-standard.md` em toda sessão e indica quando abrir os demais documentos.
- Regras de documentação viva no `CLAUDE.md`: atualização do documento afetado, versão do documento, linha na tabela de mudanças do guia e entradas no changelog e no diário, tudo no commit do trabalho.
- `CHANGELOG.md` e `JOURNAL.md` na raiz.
- Código herdado de `flutter/devtools`: o `main` foi rebaseado sobre o `master` do upstream no commit `9b8d6457` (DC-04, ADR-0002). Entram `packages/devtools_*`, `tool/` (comando `dt`), `third_party/`, `.github/` e os arquivos de raiz do upstream. Remoto `upstream` configurado para buscar só o `master`, sem tags.
- `PATCHES.md` na raiz, com o commit base do fork, a fila de patches e a lista de testes herdados removidos (NFR-MNT-001, NFR-MNT-004). Patch 1: `CLAUDE.md`.
- `docs/requirements/srs.md` 0.3: tabela de situação das premissas no apêndice A, com o resultado parcial de ASM-06 (Linux x64 confirmado, Windows por testar).
- `docs/architecture/arc42.md` 0.3: RSK-11, regressão do engine no SDK candidato do upstream (flutter/flutter#195885).
- ADR-0014 (aceita) e ADR-0015 (proposta), com as linhas no índice de `docs/decisions/README.md`.
- Workspace do pub do Studio em `studio/`: `pubspec.yaml` com os pacotes herdados por caminho em `dependency_overrides`, `pubspec.lock` próprio, `analysis_options.yaml` comum (inclui o do upstream, liga os três modos estritos e as regras de analisador da seção 4.2 do padrão de código) e `flutter-version.txt` com `3.47.9`.
- Pacote `studio/packages/studio_shell` 0.1.0: runner de Linux, `StudioWidgetsBinding`, `InheritedAssetMessenger`, `MessageChannelAssetBundle`, `InheritedFontRegistry` e oito testes de unidade em `test/inherited_assets/`.
- `STUDIO-PATCH(2)` em `packages/devtools_app/lib/initialization.dart` e `packages/devtools_app/lib/src/shared/framework/app_error_handling.dart`: parâmetro opcional `ensureBindingInitialized`. Registrado em `PATCHES.md`.
- Pacote `studio/packages/studio_tool` 0.1.0, com o executável `st` e o comando `st verify` (NFR-MNT-005): `QualityGate`, `GateStep`, `ProcessStep`, `GateStepCatalog`, `ProcessRunner` e 16 testes. Passos construídos: QG-01, QG-02, QG-04 e QG-05. Passo exigido sem implementação, ou com ferramenta ausente, sai como `notRun` e reprova o portão. Uso: `dart run studio_tool:st verify`, a partir de `studio/`.
- Pacote `studio/packages/studio_core` 0.1.0: `ProjectLoader`, `SdkLocator`, `SdkVersionWindow` (3.38, 3.41, 3.44 e 3.47) e as falhas `ProjectOpenFailure` (FR-PRJ-001 a 003); `DocumentStore` com `WorkspaceEdit`, `TextDocument` e gravação atômica (FR-DOC-001, NFR-REL-003, IR-005); `BaseProtocolDecoder` e `baseProtocolChannel`, o enquadramento `Content-Length` comum a LSP e DAP. 32 testes.
- `studio_core`: `LspClient`, `DapClient` e `DtdConnection` (IR-001 a IR-003); `ToolchainSupervisor` com `ToolchainChild` e `ToolchainState` (NFR-REL-002); `ToolingDaemonChild`, `AnalysisServerChild`, `AppRun` e `ProjectSession` (FR-PRJ-004, FR-RUN-001 e 003, FR-DOC-002); `EditFailure` e `SourceLocation`. 51 testes, dois deles de sistema com o SDK real: `project_session_test.dart` e `app_run_test.dart` (tag `desktop`, abre uma janela).
- `studio_shell`: tela Studio dentro do DevTools herdado, com `WorkbenchController`, `InheritedDevTools`, `WorkbenchView`, `ProjectWorkbench`, `RunToolbar`, `OutputPane` e `OpenProjectPrompt`; textos em `lib/l10n/studio_en.arb` e `studio_pt.arb`, com a classe `StudioLocalizations` gerada por `flutter gen-l10n` em `lib/src/l10n/`; o primeiro argumento da linha de comando abre um projeto na partida; o projeto é fechado na saída e em SIGTERM ou SIGINT. 16 testes.
- `STUDIO-PATCH(3)` em `packages/devtools_app/lib/devtools_app.dart`: exporta o painel de propriedades. Registrado em `PATCHES.md`.
- `studio_core`: desfazer e refazer no `DocumentStore` (FR-DOC-005, FR-DOC-006, NFR-REL-004). `apply`, `undo` e `redo` devolvem `AppliedEdit`, com as edições feitas e a versão de cada arquivo; `canUndo` e `canRedo` são `ValueListenable`; `TextDocument` ganha `replacing` e `editTo`. O fluxo `changedFiles` dá lugar a `changes`, de `DocumentChange`, com o documento novo e a origem (`ChangeOrigin`).
- Pacote `studio/packages/studio_protocol` 0.1.0 (ADR-0013, NFR-MNT-006): `studio.openrpc.json`, contrato 0.1.0 do serviço `Studio`, com `getVersion`, `getSelection`, `select`, `getProperties`, `setProperty`, `undo` e `redo`, os eventos `selectionChanged` e `documentChanged` e os seis erros; código gerado em `lib/src/generated/` (tipos de valor, `StudioApi`, `StudioClient`, `StudioDispatcher`, `StudioMethod`, `StudioEvent`, `StudioErrorCode`, `StudioContract`); escritos à mão, `StudioFault` e as funções de `json_conversion.dart`. 17 testes, um deles servindo cada exemplo do contrato pelo dispatcher gerado.
- `studio_tool`: comando `st generate`, com `--check`, e o passo QG-09 do portão (`GeneratedCodeStep`). Gerador em `lib/src/generate/`: `ContractDocument`, `SchemaType`, `SchemaEmitter`, `ConstantsEmitter`, `ServiceEmitter`, `ContractGenerator` e `ProtocolPackage`. A leitura do contrato reprova nome fora da convenção (CS-NAM-005), descrição ausente e método sem exemplo (CS-DOC-010). 50 testes no pacote.
- `docs/interfaces/icd.md` 0.2, conforme a linha 0.9 da tabela do guia.
- `studio_core`: `EditPipeline`, a transação de edição do primeiro nível da ADR-0006, com `setArgument`, `undo`, `redo` e `applyServerEdit`, uma operação por vez (ADR-0007); `ArgumentLiteral`, que converte entre o fonte de um literal e o valor que o analysis server troca; `DocumentSync`, que abre os documentos no servidor com a versão do `DocumentStore` e os reabre num servidor reiniciado (NFR-REL-002); `LspClient` ganha `openDocument`, `changeDocument`, `editableArguments` e `editArgument`, com `EditableArgument` e `LspRequestFailed`; `EditFailure` ganha `StaleDocument`, `UnsupportedEdit` e `ToolUnavailable`. Ainda não ligados à sessão.
- `studio_core`: `StudioService`, a fachada que implementa `StudioApi` e converte cada `EditFailure` no `StudioFault` do contrato (FR-API-001, ADR-0012); `SelectionController` e `WidgetLocation` (FR-INS-003); `ArgumentReader`; `DtdConnection.serveStudio` registra o serviço `Studio` no daemon e `postStudioEvent` publica no fluxo `Studio` (IR-003); `DocumentStore.documentAt` confere projeto e versão. A `ProjectSession` registra o serviço ao conectar ao daemon, abre no analysis server o documento selecionado, anuncia a posição ativa com a versão do documento e publica `selectionChanged` e `documentChanged`. 98 testes no pacote, um deles de sistema: um cliente do daemon lê propriedades, edita, recebe `StaleDocument` e desfaz, e o arquivo volta byte a byte.
- `studio_shell`: `StudioEditorClient`, o cliente de editor do painel de propriedades herdado que envia toda edição a `StudioApi.setProperty` e não oferece refactor por fora do serviço (FR-API-002); `HistoryButtons`, com Desfazer e Refazer na barra, e `WorkbenchController.undo` e `redo` (FR-DOC-005); textos `undoAction` e `redoAction` nos dois ARB. 24 testes no pacote.
- `STUDIO-PATCH(4)` em `property_editor_panel.dart` e `devtools_app.dart`: parâmetro opcional `editorClientBuilder` e exportação de `api_classes.dart`. Registrado em `PATCHES.md`. Os 61 testes herdados de `test/standalone_ui/ide_shared` e `test/shared/editor` passam com o SDK candidato.

### Alterado

- `ProjectWorkbench` recebe a `ProjectSession` no lugar do `FlutterProject`.
- `docs/architecture/arc42.md` 0.7, conforme a linha 0.11 da tabela do guia.
- `studio_core`: `ProjectSession.selectLocation` sai; a seleção passa por `ProjectSession.selection`. O enum `ChangeOrigin` do núcleo dá lugar ao gerado em `studio_protocol`. O pedido de hot reload sai do ouvinte de arquivos e passa ao `EditPipeline`.
- `docs/architecture/arc42.md` 0.6 e `docs/interfaces/icd.md` 0.3, conforme a linha 0.10 da tabela do guia.
- Documentos movidos para os caminhos do mapa do guia: `docs/requirements/srs.md`, `docs/architecture/arc42.md`, `docs/interfaces/icd.md`, `docs/verification/test-plan.md` e `docs/engineering/coding-standard.md`.
- Registro de decisões dividido: `docs/decisions.md` virou um arquivo por ADR em `docs/decisions/`, com nome `NNNN-title-with-dashes.md` em inglês e índice em `docs/decisions/README.md`. O texto das decisões não mudou.
- `CLAUDE.md`: seção "Código herdado", com a remissão ao `AGENTS.md` e ao `STYLE.md` do upstream e a regra do marcador `STUDIO-PATCH(n)`.
- `docs/engineering/coding-standard.md` 0.2: célula do `analysis_options.yaml` na seção 2.2, linha de versões de toolchain na seção 5.2 e padrão Decorator no catálogo da seção 6.3.
- `docs/architecture/arc42.md` 0.4: resposta do RSK-11 e local dos pacotes `studio_*` na seção 8.
- `CLAUDE.md`: os dois workspaces e o SDK de cada um.
- ADR-0003 a ADR-0013: estado de "proposta" para "aceita", nos arquivos e no índice (registro de decisões 0.3). A seção 9 de `docs/architecture/arc42.md` deixa de repetir os estados e remete ao índice.
- ADR-0015: estado de "proposta" para "aceita" (registro de decisões 0.4); `docs/engineering/coding-standard.md` 0.3 tira a ressalva da linha do Decorator na seção 6.3.
- `JOURNAL.md`: caminho de seis marcos até a primeira edição visual, com o desvio temporário de FR-API-002 aprovado pelo dono do produto.
- `docs/architecture/arc42.md` 0.5 e `docs/engineering/coding-standard.md` 0.4, conforme a linha 0.8 da tabela do guia.
- Histórico do `main` reescrito pelo rebase: os quatro commits anteriores ganharam hashes novos, sem mudança de conteúdo.
- `docs/guide.md`: linha 0.3 na tabela de mudanças e os dois registros citados na seção de controle de mudanças.
