# ADR-0006: Edição em três níveis

Estado: aceita.

## Contexto e problema

O analysis server já edita argumentos de tipos simples e oferece assists de widget. O editor de propriedades herdado trata cinco tipos: texto, inteiro, real, booleano e enumeração. Faltam objetos compostos, inserção, movimentação entre pais e eventos.

## Opções consideradas

1. Motor próprio para tudo.
2. Só o que o servidor oferece.
3. Três níveis: `editArgument`; assists e refactors do servidor; motor próprio para o restante.
4. Plugin de análise com assists próprios.

## Decisão

Opção 3. A opção 4 exigiria habilitar o plugin no `analysis_options.yaml` do projeto, o que viola DC-02.

## Consequências

- Bom: menos código próprio; onde o servidor cobre, o comportamento é idêntico ao dos outros editores.
- Ruim: dois caminhos de edição a manter coerentes; dependência de métodos customizados do servidor (RSK-01).

## Confirmação

Oráculos ORC-01 e ORC-02.
