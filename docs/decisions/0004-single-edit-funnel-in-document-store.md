# ADR-0004: Funil único de edição no `DocumentStore`

Estado: proposta.

## Contexto e problema

As edições têm três origens: o analysis server, que pede ao cliente para aplicá-las por `workspace/applyEdit`; o motor de edição; e o editor de código. Desfazer, gravação, validação e reload precisam valer para todas.

## Opções consideradas

1. Cada origem grava seus arquivos.
2. Um componente único recebe `WorkspaceEdit` de todas as origens.

## Decisão

Opção 2.

## Consequências

- Bom: desfazer exato, gravação atômica, mapa de posições e disparo de reload ficam num lugar só; FR-API-002 passa a ser verificável por inspeção.
- Ruim: o `DocumentStore` é ponto único de falha e exige a maior cobertura de teste do sistema.

## Confirmação

FR-DOC-001 por inspeção: nenhuma escrita em arquivo do projeto fora do componente. Oráculo ORC-08.
