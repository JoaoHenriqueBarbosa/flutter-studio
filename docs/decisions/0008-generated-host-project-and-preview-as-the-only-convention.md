# ADR-0008: Projeto host gerado e `@Preview` como única convenção

Estado: aceita.

## Contexto e problema

Renderizar um widget isolado exige um ponto de entrada que o instancie e que inclua o agente de design. Esse ponto de entrada não pode morar no projeto (DC-02). O Widget Previewer do SDK resolve o mesmo problema com um projeto gerado em `.dart_tool` e a anotação `@Preview`.

## Opções consideradas

1. Dependência de desenvolvimento no projeto do usuário.
2. Projeto host gerado em `.dart_tool`, com dependência por caminho.
3. Anotação própria do Studio para marcar telas.

## Decisão

Opção 2, com `@Preview` do SDK como única forma de dar contexto a telas que precisam dele. Widgets sem parâmetro obrigatório abrem sem anotação.

## Consequências

- Bom: mesmo arranjo da ferramenta oficial; a descoberta de previews vem do analysis server.
- Ruim: recursos e fontes do projeto precisam ser reexpostos no host; telas com parâmetro obrigatório exigem uma função de preview, que o usuário escreve ou aceita que o Studio crie.

## Confirmação

FR-HST-001 e FR-CNV-003; oráculo ORC-09.
