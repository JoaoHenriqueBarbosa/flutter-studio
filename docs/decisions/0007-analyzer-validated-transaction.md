# ADR-0007: Transação validada pelo analisador

Estado: aceita.

## Contexto e problema

Uma edição estrutural pode produzir código que não compila. Gravar e descobrir depois quebra o hot reload e a confiança do usuário.

## Opções consideradas

1. Gravar e reverter se houver erro.
2. Validar em memória antes de gravar, enviando o conteúdo ao analysis server como não gravado.
3. Validar só a sintaxe.

## Decisão

Opção 2.

## Consequências

- Bom: o disco nunca recebe edição que aumenta os erros (QS-01).
- Ruim: latência adicional por edição estrutural (NFR-PERF-004); edições que dependem uma da outra para compilar precisam ser submetidas como uma transação só.

## Confirmação

FR-STR-008; oráculo ORC-06.
