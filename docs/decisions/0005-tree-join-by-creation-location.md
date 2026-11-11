# ADR-0005: Junção das árvores pelo local de criação

Estado: aceita.

## Contexto e problema

O inspector conhece os widgets em execução. O analysis server conhece o código. Para editar o que se clica é preciso ligar um ao outro. Em modo debug, o framework registra arquivo, linha e coluna da expressão que cria cada widget.

## Opções consideradas

1. Chaves ou anotações inseridas no código do usuário.
2. Heurística por tipo e ordem na árvore.
3. Local de criação registrado pelo framework.

## Decisão

Opção 3. Não toca o código do usuário e é a mesma informação que o inspector já usa para ir ao código.

## Consequências

- Bom: nenhuma instrumentação; funciona em qualquer app em modo debug.
- Ruim: só vale com o rastreamento ligado (FR-INS-007); várias instâncias podem compartilhar um local (FR-INS-005); o local se refere à versão do último reload, o que exige o mapa de posições (FR-INS-006).

## Confirmação

Oráculo ORC-03, com meta de 99,9% no corpus.
