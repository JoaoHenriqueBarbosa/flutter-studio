# ADR-0012: API primeiro: a interface é cliente do serviço `Studio`

Estado: aceita.

## Contexto e problema

O implementador é um agente, e parte dos usuários também. Testar pela interface gráfica é lento e frágil. O DTD já é o barramento por onde ferramentas e agentes chegam ao app em execução.

## Opções consideradas

1. Interface gráfica com lógica própria e API à parte.
2. Toda operação é método do serviço `Studio`, e a interface só chama esses métodos.

## Decisão

Opção 2.

## Consequências

- Bom: testes de sistema sem interface gráfica; agentes e pessoas editam pela mesma porta; contrato descrito em OpenRPC.
- Ruim: o contrato precisa de versionamento desde o início; toda operação nova começa pela especificação.

## Confirmação

FR-API-001 a FR-API-003; oráculo ORC-10.
