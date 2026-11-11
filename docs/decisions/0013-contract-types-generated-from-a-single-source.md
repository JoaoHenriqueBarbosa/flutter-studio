# ADR-0013: Tipos de contrato gerados de uma única fonte

Estado: aceita.

## Contexto e problema

O contrato do serviço `Studio` e os layouts binários do quadro e do espelho de cena são lidos e escritos por quatro programas: shell, motor de edição, agente de design e host nativo. Três são Dart, sobre dois SDKs diferentes, e um é Rust. Tipos digitados à mão em cada um divergem em silêncio, e a divergência só aparece em execução.

## Opções consideradas

1. Tipos escritos à mão em cada pacote, com testes de contrato para detectar divergência.
2. Código primeiro: classes Dart anotadas são a fonte, e o documento OpenRPC e os tipos Rust são gerados delas.
3. Contrato primeiro: o documento OpenRPC e um arquivo de layouts são a fonte, e tipos Dart e Rust, constantes e referência são gerados deles.

## Decisão

Opção 3. O contrato é o que os clientes externos leem (ADR-0012), então ele é a fonte. O gerador é próprio, escrito em Dart no pacote `studio_tool`; o código gerado é versionado, e o CI regenera e reprova qualquer diferença.

## Consequências

- Bom: uma mudança de contrato aparece no mesmo commit como diff na especificação e nos tipos dos dois lados; a referência da API e os exemplos saem da mesma fonte; o código Rust não redigita nada do Dart.
- Ruim: o projeto mantém um gerador; toda operação nova começa pela especificação; o código gerado precisa compilar nas versões do SDK que NFR-FLEX-001 exige.

## Confirmação

NFR-MNT-006; regras CS-DRY-005 e CS-DRY-012 a 014 do Padrão de código; passo QG-09 do portão; oráculo ORC-10.
