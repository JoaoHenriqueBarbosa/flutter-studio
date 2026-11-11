# Patches sobre o DevTools

Registro da fila de patches que o Studio mantém sobre o código herdado de [flutter/devtools](https://github.com/flutter/devtools), exigido por NFR-MNT-001 e decidido na ADR-0002.

## Base

| Campo | Valor |
| --- | --- |
| Remoto | `upstream`, `https://github.com/flutter/devtools.git`, ramo `master` |
| Commit base | `9b8d64574de47d8d58234d7ddf2fbf3e55bc3f00`, de 10/11/2026 |
| Último rebase | 11/11/2026 |

O ramo `main` é o `master` do upstream com os commits do Studio por cima. A cada rebase (NFR-MNT-002), o commit base e a data desta tabela são atualizados no mesmo commit.

## Patches

Cada patch altera arquivo herdado e é marcado no próprio arquivo com `STUDIO-PATCH(n)`, na forma da seção 7.2 do padrão de código. Arquivo novo do Studio não é patch e não entra aqui.

| n | Arquivo | Motivo | Situação no upstream |
| --- | --- | --- | --- |
| 1 | `CLAUDE.md` | O arquivo do upstream só manda ler o `AGENTS.md`. O do Studio o substitui para carregar o guia e o padrão de código em toda sessão, e mantém a remissão ao `AGENTS.md` para o código herdado. | Não se aplica: mudança específica do fork, não será proposta. |
| 2 | `packages/devtools_app/lib/initialization.dart`, `packages/devtools_app/lib/src/shared/framework/app_error_handling.dart` | `runDevTools` e `setupErrorHandling` aceitam o parâmetro opcional `ensureBindingInitialized`, para o shell instalar o `StudioWidgetsBinding` dentro da zona de erros (ADR-0015). Sem o parâmetro, o comportamento é o do upstream. | Ainda não proposto. É um ponto de extensão genérico, candidato a devolução. |

## Testes herdados removidos

Nenhum (NFR-MNT-004).
