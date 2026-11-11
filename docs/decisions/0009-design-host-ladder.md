# ADR-0009: Escada de hosts de design

Estado: proposta.

## Contexto e problema

O host ideal não exige toolchain nativo, entrega quadros sem cópia e aceita entrada real. Nenhum dispositivo do SDK atende aos três. O Widget Previewer oficial roda em Flutter Web e não oferece `dart:io`, `dart:ffi` nem plugins nativos.

## Opções consideradas

1. Alvo web em visão embutida.
2. Dispositivo desktop com janela oculta.
3. `flutter_tester` com agente que copia os quadros por memória compartilhada.
4. Host nativo próprio sobre a API de embedder.
5. Degraus: a opção 3 primeiro, a 4 depois, e dispositivo real como modo à parte.

## Decisão

Opção 5. O degrau da opção 3 não exige código nativo nem toolchain e destrava o canvas. O da opção 4 entra depois que o primeiro estiver medido.

## Consequências

- Bom: o canvas não espera o host nativo; o transporte fica atrás de uma interface, `FrameTransport`, que também admite o alvo web.
- Ruim: dois transportes a manter; o primeiro degrau depende de ASM-01.

## Confirmação

NFR-PERF-005 e FR-HST-002.
