# ADR-0010: Host nativo em Rust sobre a API de embedder

Estado: aceita.

## Contexto e problema

O host nativo carrega o engine, renderiza em superfície compartilhada com o shell e injeta entrada. A API de embedder é C. Um levantamento de terceiros indica que as bibliotecas desktop de release do Flutter não exportam essa API.

## Opções consideradas

1. C++.
2. Rust.
3. Reaproveitar os embeddings desktop do SDK.

## Decisão

Opção 2. O host manipula superfícies de GPU e memória compartilhadas entre processos, onde erro de memória vira falha difícil de diagnosticar. A opção 3 fica descartada enquanto os símbolos não forem exportados; a verificação é refeita no início de F5.

## Consequências

- Bom: segurança de memória no componente de maior risco; um binário por sistema.
- Ruim: segunda linguagem no repositório; três caminhos de textura (DXGI, IOSurface e dmabuf); dependência do pacote de embedder por revisão de engine (RSK-04).

## Confirmação

FR-HST-004 e NFR-PERF-005.
