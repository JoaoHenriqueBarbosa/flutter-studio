# ADR-0011: Dois SDKs: o do Studio e o do projeto

Estado: aceita.

## Contexto e problema

O Studio é um app Flutter e precisa de uma versão fixa para ser construído. O projeto do usuário usa outra. A sintaxe do Dart muda a cada versão, e um analisador embutido deixaria de ler projetos mais novos.

## Opções consideradas

1. Exigir no projeto a versão do Studio.
2. Embutir analisador e compilador no Studio.
3. Executar com o SDK do projeto tudo que analisa ou executa código do projeto.

## Decisão

Opção 3.

## Consequências

- Bom: suporte a uma janela de versões; nenhum comportamento difere do que o usuário teria na linha de comando.
- Ruim: o motor de edição e o agente são resolvidos por versão de SDK; a matriz de testes cresce; a API usada pelo agente tem de compilar em todas as versões da janela.

## Confirmação

NFR-FLEX-001; DC-05 por inspeção.
