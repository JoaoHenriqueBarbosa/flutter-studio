# Changelog

Registro técnico do que muda no repositório. O formato segue o [Keep a Changelog 1.1.0](https://keepachangelog.com/pt-BR/1.1.0/). O registro informal, para quem aprova, fica em `JOURNAL.md`.

## Não lançado

### Adicionado

- Baseline de projeto em `docs/`: guia, SRS, arquitetura (arc42), ADR-0001 a ADR-0013, interfaces (ICD), plano de verificação e padrão de código.
- `CLAUDE.md` na raiz, que importa `docs/guide.md` e `docs/engineering/coding-standard.md` em toda sessão e indica quando abrir os demais documentos.
- Regras de documentação viva no `CLAUDE.md`: atualização do documento afetado, versão do documento, linha na tabela de mudanças do guia e entradas no changelog e no diário, tudo no commit do trabalho.
- `CHANGELOG.md` e `JOURNAL.md` na raiz.

### Alterado

- Documentos movidos para os caminhos do mapa do guia: `docs/requirements/srs.md`, `docs/architecture/arc42.md`, `docs/interfaces/icd.md`, `docs/verification/test-plan.md` e `docs/engineering/coding-standard.md`.
- Registro de decisões dividido: `docs/decisions.md` virou um arquivo por ADR em `docs/decisions/`, com nome `NNNN-title-with-dashes.md` em inglês e índice em `docs/decisions/README.md`. O texto das decisões não mudou.
- `docs/guide.md`: linha 0.3 na tabela de mudanças e os dois registros citados na seção de controle de mudanças.
