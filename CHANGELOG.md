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

### Alterado

- Documentos movidos para os caminhos do mapa do guia: `docs/requirements/srs.md`, `docs/architecture/arc42.md`, `docs/interfaces/icd.md`, `docs/verification/test-plan.md` e `docs/engineering/coding-standard.md`.
- Registro de decisões dividido: `docs/decisions.md` virou um arquivo por ADR em `docs/decisions/`, com nome `NNNN-title-with-dashes.md` em inglês e índice em `docs/decisions/README.md`. O texto das decisões não mudou.
- `CLAUDE.md`: seção "Código herdado", com a remissão ao `AGENTS.md` e ao `STYLE.md` do upstream e a regra do marcador `STUDIO-PATCH(n)`.
- `docs/engineering/coding-standard.md` 0.2: célula do `analysis_options.yaml` na seção 2.2, linha de versões de toolchain na seção 5.2 e padrão Decorator no catálogo da seção 6.3.
- `docs/architecture/arc42.md` 0.4: resposta do RSK-11 e local dos pacotes `studio_*` na seção 8.
- `CLAUDE.md`: os dois workspaces e o SDK de cada um.
- ADR-0003 a ADR-0013: estado de "proposta" para "aceita", nos arquivos e no índice (registro de decisões 0.3). A seção 9 de `docs/architecture/arc42.md` deixa de repetir os estados e remete ao índice.
- ADR-0015: estado de "proposta" para "aceita" (registro de decisões 0.4); `docs/engineering/coding-standard.md` 0.3 tira a ressalva da linha do Decorator na seção 6.3.
- Histórico do `main` reescrito pelo rebase: os quatro commits anteriores ganharam hashes novos, sem mudança de conteúdo.
- `docs/guide.md`: linha 0.3 na tabela de mudanças e os dois registros citados na seção de controle de mudanças.
