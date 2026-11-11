# ADR-0001: O código do projeto é a única fonte de verdade

Estado: aceita.

## Contexto e problema

Editores visuais costumam manter um modelo próprio da interface e gerar código a partir dele. O modelo vira a fonte de verdade, o código vira saída, e o projeto passa a depender do editor. O Studio atende programadores que querem ver e possuir o código.

## Direcionadores

- O projeto continua um projeto Flutter comum (DC-02).
- Edição feita por fora é aceita sem conversão (FR-DOC-003).
- O que se vê é o que roda (FR-CNV-001).

## Opções consideradas

1. Modelo próprio com geração de código.
2. Modelo próprio sincronizado nos dois sentidos com o código.
3. Código como única fonte, sem modelo persistente.

## Decisão

Opção 3, porque é a única em que não existe estado a reconciliar: tudo que o Studio mostra deriva do disco e do processo em execução.

## Consequências

- Bom: qualquer ferramenta edita o mesmo projeto; não há formato a migrar; os diffs são legíveis.
- Ruim: só é editável por formulário o que tem forma reconhecível no código; expressões arbitrárias são editadas como texto; toda operação custa análise de código.

## Confirmação

Inspeção de DC-01 e DC-02; oráculo ORC-09.
