# Registro de decisões de arquitetura

Decisões do Studio no formato MADR 4.0. Cada decisão é um arquivo nesta pasta. Versão 0.5, rascunho para revisão.

## Índice

| ADR | Decisão | Estado | Data |
| --- | --- | --- | --- |
| [ADR-0001](0001-project-code-is-the-single-source-of-truth.md) | O código do projeto é a única fonte de verdade | Aceita | 11/11/2026 |
| [ADR-0002](0002-devtools-fork-kept-as-a-patch-queue.md) | Fork do DevTools mantido como fila de patches | Aceita | 11/11/2026 |
| [ADR-0003](0003-desktop-shell-as-lsp-dap-and-dtd-client.md) | Shell desktop cliente de LSP, DAP e DTD | Aceita | 11/11/2026 |
| [ADR-0004](0004-single-edit-funnel-in-document-store.md) | Funil único de edição no `DocumentStore` | Aceita | 11/11/2026 |
| [ADR-0005](0005-tree-join-by-creation-location.md) | Junção das árvores pelo local de criação | Aceita | 11/11/2026 |
| [ADR-0006](0006-three-level-editing.md) | Edição em três níveis | Aceita | 11/11/2026 |
| [ADR-0007](0007-analyzer-validated-transaction.md) | Transação validada pelo analisador | Aceita | 11/11/2026 |
| [ADR-0008](0008-generated-host-project-and-preview-as-the-only-convention.md) | Projeto host gerado e `@Preview` como única convenção | Aceita | 11/11/2026 |
| [ADR-0009](0009-design-host-ladder.md) | Escada de hosts de design | Aceita | 11/11/2026 |
| [ADR-0010](0010-native-host-in-rust-on-the-embedder-api.md) | Host nativo em Rust sobre a API de embedder | Aceita | 11/11/2026 |
| [ADR-0011](0011-two-sdks-studio-and-project.md) | Dois SDKs: o do Studio e o do projeto | Aceita | 11/11/2026 |
| [ADR-0012](0012-api-first-ui-is-a-client-of-the-studio-service.md) | API primeiro: a interface é cliente do serviço `Studio` | Aceita | 11/11/2026 |
| [ADR-0013](0013-contract-types-generated-from-a-single-source.md) | Tipos de contrato gerados de uma única fonte | Aceita | 11/11/2026 |
| [ADR-0014](0014-product-built-with-stable-flutter.md) | Produto construído com o Flutter estável | Aceita | 11/11/2026 |
| [ADR-0015](0015-inherited-assets-resolved-in-the-shell-binding.md) | Assets e fontes do código herdado resolvidos no binding do shell | Aceita | 11/11/2026 |
| [ADR-0016](0016-package-assets-resolved-by-a-shared-package.md) | Assets de pacote dependente resolvidos por um pacote compartilhado | Proposta | 11/11/2026 |

Estados usados: proposta, aceita, rejeitada, substituída por outra ADR. Uma ADR aceita não é editada: uma decisão nova a substitui. Em todas, quem decide é o dono do produto.
