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

### Alterado

- Documentos movidos para os caminhos do mapa do guia: `docs/requirements/srs.md`, `docs/architecture/arc42.md`, `docs/interfaces/icd.md`, `docs/verification/test-plan.md` e `docs/engineering/coding-standard.md`.
- Registro de decisões dividido: `docs/decisions.md` virou um arquivo por ADR em `docs/decisions/`, com nome `NNNN-title-with-dashes.md` em inglês e índice em `docs/decisions/README.md`. O texto das decisões não mudou.
- `CLAUDE.md`: seção "Código herdado", com a remissão ao `AGENTS.md` e ao `STYLE.md` do upstream e a regra do marcador `STUDIO-PATCH(n)`.
- Histórico do `main` reescrito pelo rebase: os quatro commits anteriores ganharam hashes novos, sem mudança de conteúdo.
- `docs/guide.md`: linha 0.3 na tabela de mudanças e os dois registros citados na seção de controle de mudanças.
