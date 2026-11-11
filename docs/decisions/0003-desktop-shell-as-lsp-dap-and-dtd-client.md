# ADR-0003: Shell desktop cliente de LSP, DAP e DTD

Estado: proposta.

## Contexto e problema

O Studio precisa de análise de código, de execução com hot reload e de um canal entre ferramentas. O SDK oferece os três por protocolo: analysis server (LSP), adaptador de debug (DAP) e Dart Tooling Daemon. O editor de propriedades herdado espera um editor que publique a posição ativa e aplique as edições.

## Opções consideradas

1. Extensão de VS Code ou plugin de IntelliJ.
2. App web servido localmente.
3. App desktop Flutter que assume o papel de editor nos três protocolos.
4. Bibliotecas internas do `flutter_tools` e do analisador, usadas em processo.

## Decisão

Opção 3. Um app desktop inicia processos, lê arquivos e recebe texturas nativas, e o público-alvo espera um ambiente único. Os protocolos são a superfície que o SDK mantém para editores; as bibliotecas internas da opção 4 mudam sem aviso.

## Consequências

- Bom: nenhum acoplamento a API privada do SDK; os painéis herdados funcionam sem reescrita, porque o shell cumpre o papel que eles esperam; o mesmo núcleo pode depois rodar como painel dentro de outro editor.
- Ruim: o shell implementa cliente LSP, cliente DAP e supervisão de processos; os recursos dependem do que o SDK instalado anuncia.

## Confirmação

IR-001 a IR-003; teste de contrato na matriz de SDKs.
