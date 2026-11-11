# ADR-0002: Fork do DevTools mantido como fila de patches

Estado: aceita.

## Contexto e problema

O DevTools já contém o inspector (cerca de 8,4 mil linhas), o editor de propriedades ligado ao analysis server, o depurador (cerca de 7,8 mil linhas), a conexão com VM Service e DTD e 217 arquivos de teste. É distribuído como app web, mas tem implementações de desktop em pares e roda em desktop no fluxo de desenvolvimento do próprio time.

## Direcionadores

- Tempo até a primeira entrega útil.
- Custo de acompanhar o upstream.
- Licença BSD, que permite a derivação.

## Opções consideradas

1. Escrever do zero, usando só os pacotes publicados (`devtools_app_shared`, `vm_service`, `dtd`).
2. Fork divergente.
3. Fork como fila de patches, com o produto em pacotes novos.
4. Extensão do DevTools.

## Decisão

Opção 3. Preserva o que existe, limita o conflito de rebase aos pontos de extensão e mantém aberta a devolução ao upstream. A opção 4 foi descartada: extensões do DevTools só existem no build web e não têm acesso a processos nem a arquivos.

## Consequências

- Bom: inspector, depurador e painéis de diagnóstico já no primeiro incremento.
- Ruim: dependência de estrutura interna que o upstream pode mudar (RSK-02); telas herdadas em inglês; a versão de Flutter do Studio fica atrelada à do DevTools.

## Confirmação

NFR-MNT-001, NFR-MNT-002 e NFR-MNT-004.
