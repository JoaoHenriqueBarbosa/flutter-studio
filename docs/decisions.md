# Registro de decisões de arquitetura

Decisões do Studio no formato MADR 4.0. Cada decisão vira um arquivo em `docs/decisions/`. Versão 0.2, rascunho para revisão.

## Índice

| ADR | Decisão | Estado | Data |
| --- | --- | --- | --- |
| ADR-0001 | O código do projeto é a única fonte de verdade | Aceita | 11/11/2026 |
| ADR-0002 | Fork do DevTools mantido como fila de patches | Aceita | 11/11/2026 |
| ADR-0003 | Shell desktop cliente de LSP, DAP e DTD | Proposta | 11/11/2026 |
| ADR-0004 | Funil único de edição no `DocumentStore` | Proposta | 11/11/2026 |
| ADR-0005 | Junção das árvores pelo local de criação | Proposta | 11/11/2026 |
| ADR-0006 | Edição em três níveis | Proposta | 11/11/2026 |
| ADR-0007 | Transação validada pelo analisador | Proposta | 11/11/2026 |
| ADR-0008 | Projeto host gerado e `@Preview` como única convenção | Proposta | 11/11/2026 |
| ADR-0009 | Escada de hosts de design | Proposta | 11/11/2026 |
| ADR-0010 | Host nativo em Rust sobre a API de embedder | Proposta | 11/11/2026 |
| ADR-0011 | Dois SDKs: o do Studio e o do projeto | Proposta | 11/11/2026 |
| ADR-0012 | API primeiro: a interface é cliente do serviço `Studio` | Proposta | 11/11/2026 |
| ADR-0013 | Tipos de contrato gerados de uma única fonte | Proposta | 11/11/2026 |

Estados usados: proposta, aceita, rejeitada, substituída por outra ADR. Uma ADR aceita não é editada: uma decisão nova a substitui. Em todas, quem decide é o dono do produto.

## ADR-0001: O código do projeto é a única fonte de verdade

Estado: aceita.

### Contexto e problema

Editores visuais costumam manter um modelo próprio da interface e gerar código a partir dele. O modelo vira a fonte de verdade, o código vira saída, e o projeto passa a depender do editor. O Studio atende programadores que querem ver e possuir o código.

### Direcionadores

- O projeto continua um projeto Flutter comum (DC-02).
- Edição feita por fora é aceita sem conversão (FR-DOC-003).
- O que se vê é o que roda (FR-CNV-001).

### Opções consideradas

1. Modelo próprio com geração de código.
2. Modelo próprio sincronizado nos dois sentidos com o código.
3. Código como única fonte, sem modelo persistente.

### Decisão

Opção 3, porque é a única em que não existe estado a reconciliar: tudo que o Studio mostra deriva do disco e do processo em execução.

### Consequências

- Bom: qualquer ferramenta edita o mesmo projeto; não há formato a migrar; os diffs são legíveis.
- Ruim: só é editável por formulário o que tem forma reconhecível no código; expressões arbitrárias são editadas como texto; toda operação custa análise de código.

### Confirmação

Inspeção de DC-01 e DC-02; oráculo ORC-09.

## ADR-0002: Fork do DevTools mantido como fila de patches

Estado: aceita.

### Contexto e problema

O DevTools já contém o inspector (cerca de 8,4 mil linhas), o editor de propriedades ligado ao analysis server, o depurador (cerca de 7,8 mil linhas), a conexão com VM Service e DTD e 217 arquivos de teste. É distribuído como app web, mas tem implementações de desktop em pares e roda em desktop no fluxo de desenvolvimento do próprio time.

### Direcionadores

- Tempo até a primeira entrega útil.
- Custo de acompanhar o upstream.
- Licença BSD, que permite a derivação.

### Opções consideradas

1. Escrever do zero, usando só os pacotes publicados (`devtools_app_shared`, `vm_service`, `dtd`).
2. Fork divergente.
3. Fork como fila de patches, com o produto em pacotes novos.
4. Extensão do DevTools.

### Decisão

Opção 3. Preserva o que existe, limita o conflito de rebase aos pontos de extensão e mantém aberta a devolução ao upstream. A opção 4 foi descartada: extensões do DevTools só existem no build web e não têm acesso a processos nem a arquivos.

### Consequências

- Bom: inspector, depurador e painéis de diagnóstico já no primeiro incremento.
- Ruim: dependência de estrutura interna que o upstream pode mudar (RSK-02); telas herdadas em inglês; a versão de Flutter do Studio fica atrelada à do DevTools.

### Confirmação

NFR-MNT-001, NFR-MNT-002 e NFR-MNT-004.

## ADR-0003: Shell desktop cliente de LSP, DAP e DTD

Estado: proposta.

### Contexto e problema

O Studio precisa de análise de código, de execução com hot reload e de um canal entre ferramentas. O SDK oferece os três por protocolo: analysis server (LSP), adaptador de debug (DAP) e Dart Tooling Daemon. O editor de propriedades herdado espera um editor que publique a posição ativa e aplique as edições.

### Opções consideradas

1. Extensão de VS Code ou plugin de IntelliJ.
2. App web servido localmente.
3. App desktop Flutter que assume o papel de editor nos três protocolos.
4. Bibliotecas internas do `flutter_tools` e do analisador, usadas em processo.

### Decisão

Opção 3. Um app desktop inicia processos, lê arquivos e recebe texturas nativas, e o público-alvo espera um ambiente único. Os protocolos são a superfície que o SDK mantém para editores; as bibliotecas internas da opção 4 mudam sem aviso.

### Consequências

- Bom: nenhum acoplamento a API privada do SDK; os painéis herdados funcionam sem reescrita, porque o shell cumpre o papel que eles esperam; o mesmo núcleo pode depois rodar como painel dentro de outro editor.
- Ruim: o shell implementa cliente LSP, cliente DAP e supervisão de processos; os recursos dependem do que o SDK instalado anuncia.

### Confirmação

IR-001 a IR-003; teste de contrato na matriz de SDKs.

## ADR-0004: Funil único de edição no `DocumentStore`

Estado: proposta.

### Contexto e problema

As edições têm três origens: o analysis server, que pede ao cliente para aplicá-las por `workspace/applyEdit`; o motor de edição; e o editor de código. Desfazer, gravação, validação e reload precisam valer para todas.

### Opções consideradas

1. Cada origem grava seus arquivos.
2. Um componente único recebe `WorkspaceEdit` de todas as origens.

### Decisão

Opção 2.

### Consequências

- Bom: desfazer exato, gravação atômica, mapa de posições e disparo de reload ficam num lugar só; FR-API-002 passa a ser verificável por inspeção.
- Ruim: o `DocumentStore` é ponto único de falha e exige a maior cobertura de teste do sistema.

### Confirmação

FR-DOC-001 por inspeção: nenhuma escrita em arquivo do projeto fora do componente. Oráculo ORC-08.

## ADR-0005: Junção das árvores pelo local de criação

Estado: proposta.

### Contexto e problema

O inspector conhece os widgets em execução. O analysis server conhece o código. Para editar o que se clica é preciso ligar um ao outro. Em modo debug, o framework registra arquivo, linha e coluna da expressão que cria cada widget.

### Opções consideradas

1. Chaves ou anotações inseridas no código do usuário.
2. Heurística por tipo e ordem na árvore.
3. Local de criação registrado pelo framework.

### Decisão

Opção 3. Não toca o código do usuário e é a mesma informação que o inspector já usa para ir ao código.

### Consequências

- Bom: nenhuma instrumentação; funciona em qualquer app em modo debug.
- Ruim: só vale com o rastreamento ligado (FR-INS-007); várias instâncias podem compartilhar um local (FR-INS-005); o local se refere à versão do último reload, o que exige o mapa de posições (FR-INS-006).

### Confirmação

Oráculo ORC-03, com meta de 99,9% no corpus.

## ADR-0006: Edição em três níveis

Estado: proposta.

### Contexto e problema

O analysis server já edita argumentos de tipos simples e oferece assists de widget. O editor de propriedades herdado trata cinco tipos: texto, inteiro, real, booleano e enumeração. Faltam objetos compostos, inserção, movimentação entre pais e eventos.

### Opções consideradas

1. Motor próprio para tudo.
2. Só o que o servidor oferece.
3. Três níveis: `editArgument`; assists e refactors do servidor; motor próprio para o restante.
4. Plugin de análise com assists próprios.

### Decisão

Opção 3. A opção 4 exigiria habilitar o plugin no `analysis_options.yaml` do projeto, o que viola DC-02.

### Consequências

- Bom: menos código próprio; onde o servidor cobre, o comportamento é idêntico ao dos outros editores.
- Ruim: dois caminhos de edição a manter coerentes; dependência de métodos customizados do servidor (RSK-01).

### Confirmação

Oráculos ORC-01 e ORC-02.

## ADR-0007: Transação validada pelo analisador

Estado: proposta.

### Contexto e problema

Uma edição estrutural pode produzir código que não compila. Gravar e descobrir depois quebra o hot reload e a confiança do usuário.

### Opções consideradas

1. Gravar e reverter se houver erro.
2. Validar em memória antes de gravar, enviando o conteúdo ao analysis server como não gravado.
3. Validar só a sintaxe.

### Decisão

Opção 2.

### Consequências

- Bom: o disco nunca recebe edição que aumenta os erros (QS-01).
- Ruim: latência adicional por edição estrutural (NFR-PERF-004); edições que dependem uma da outra para compilar precisam ser submetidas como uma transação só.

### Confirmação

FR-STR-008; oráculo ORC-06.

## ADR-0008: Projeto host gerado e `@Preview` como única convenção

Estado: proposta.

### Contexto e problema

Renderizar um widget isolado exige um ponto de entrada que o instancie e que inclua o agente de design. Esse ponto de entrada não pode morar no projeto (DC-02). O Widget Previewer do SDK resolve o mesmo problema com um projeto gerado em `.dart_tool` e a anotação `@Preview`.

### Opções consideradas

1. Dependência de desenvolvimento no projeto do usuário.
2. Projeto host gerado em `.dart_tool`, com dependência por caminho.
3. Anotação própria do Studio para marcar telas.

### Decisão

Opção 2, com `@Preview` do SDK como única forma de dar contexto a telas que precisam dele. Widgets sem parâmetro obrigatório abrem sem anotação.

### Consequências

- Bom: mesmo arranjo da ferramenta oficial; a descoberta de previews vem do analysis server.
- Ruim: recursos e fontes do projeto precisam ser reexpostos no host; telas com parâmetro obrigatório exigem uma função de preview, que o usuário escreve ou aceita que o Studio crie.

### Confirmação

FR-HST-001 e FR-CNV-003; oráculo ORC-09.

## ADR-0009: Escada de hosts de design

Estado: proposta.

### Contexto e problema

O host ideal não exige toolchain nativo, entrega quadros sem cópia e aceita entrada real. Nenhum dispositivo do SDK atende aos três. O Widget Previewer oficial roda em Flutter Web e não oferece `dart:io`, `dart:ffi` nem plugins nativos.

### Opções consideradas

1. Alvo web em visão embutida.
2. Dispositivo desktop com janela oculta.
3. `flutter_tester` com agente que copia os quadros por memória compartilhada.
4. Host nativo próprio sobre a API de embedder.
5. Degraus: a opção 3 primeiro, a 4 depois, e dispositivo real como modo à parte.

### Decisão

Opção 5. O degrau da opção 3 não exige código nativo nem toolchain e destrava o canvas. O da opção 4 entra depois que o primeiro estiver medido.

### Consequências

- Bom: o canvas não espera o host nativo; o transporte fica atrás de uma interface, `FrameTransport`, que também admite o alvo web.
- Ruim: dois transportes a manter; o primeiro degrau depende de ASM-01.

### Confirmação

NFR-PERF-005 e FR-HST-002.

## ADR-0010: Host nativo em Rust sobre a API de embedder

Estado: proposta.

### Contexto e problema

O host nativo carrega o engine, renderiza em superfície compartilhada com o shell e injeta entrada. A API de embedder é C. Um levantamento de terceiros indica que as bibliotecas desktop de release do Flutter não exportam essa API.

### Opções consideradas

1. C++.
2. Rust.
3. Reaproveitar os embeddings desktop do SDK.

### Decisão

Opção 2. O host manipula superfícies de GPU e memória compartilhadas entre processos, onde erro de memória vira falha difícil de diagnosticar. A opção 3 fica descartada enquanto os símbolos não forem exportados; a verificação é refeita no início de F5.

### Consequências

- Bom: segurança de memória no componente de maior risco; um binário por sistema.
- Ruim: segunda linguagem no repositório; três caminhos de textura (DXGI, IOSurface e dmabuf); dependência do pacote de embedder por revisão de engine (RSK-04).

### Confirmação

FR-HST-004 e NFR-PERF-005.

## ADR-0011: Dois SDKs: o do Studio e o do projeto

Estado: proposta.

### Contexto e problema

O Studio é um app Flutter e precisa de uma versão fixa para ser construído. O projeto do usuário usa outra. A sintaxe do Dart muda a cada versão, e um analisador embutido deixaria de ler projetos mais novos.

### Opções consideradas

1. Exigir no projeto a versão do Studio.
2. Embutir analisador e compilador no Studio.
3. Executar com o SDK do projeto tudo que analisa ou executa código do projeto.

### Decisão

Opção 3.

### Consequências

- Bom: suporte a uma janela de versões; nenhum comportamento difere do que o usuário teria na linha de comando.
- Ruim: o motor de edição e o agente são resolvidos por versão de SDK; a matriz de testes cresce; a API usada pelo agente tem de compilar em todas as versões da janela.

### Confirmação

NFR-FLEX-001; DC-05 por inspeção.

## ADR-0012: API primeiro: a interface é cliente do serviço `Studio`

Estado: proposta.

### Contexto e problema

O implementador é um agente, e parte dos usuários também. Testar pela interface gráfica é lento e frágil. O DTD já é o barramento por onde ferramentas e agentes chegam ao app em execução.

### Opções consideradas

1. Interface gráfica com lógica própria e API à parte.
2. Toda operação é método do serviço `Studio`, e a interface só chama esses métodos.

### Decisão

Opção 2.

### Consequências

- Bom: testes de sistema sem interface gráfica; agentes e pessoas editam pela mesma porta; contrato descrito em OpenRPC.
- Ruim: o contrato precisa de versionamento desde o início; toda operação nova começa pela especificação.

### Confirmação

FR-API-001 a FR-API-003; oráculo ORC-10.

## ADR-0013: Tipos de contrato gerados de uma única fonte

Estado: proposta.

### Contexto e problema

O contrato do serviço `Studio` e os layouts binários do quadro e do espelho de cena são lidos e escritos por quatro programas: shell, motor de edição, agente de design e host nativo. Três são Dart, sobre dois SDKs diferentes, e um é Rust. Tipos digitados à mão em cada um divergem em silêncio, e a divergência só aparece em execução.

### Opções consideradas

1. Tipos escritos à mão em cada pacote, com testes de contrato para detectar divergência.
2. Código primeiro: classes Dart anotadas são a fonte, e o documento OpenRPC e os tipos Rust são gerados delas.
3. Contrato primeiro: o documento OpenRPC e um arquivo de layouts são a fonte, e tipos Dart e Rust, constantes e referência são gerados deles.

### Decisão

Opção 3. O contrato é o que os clientes externos leem (ADR-0012), então ele é a fonte. O gerador é próprio, escrito em Dart no pacote `studio_tool`; o código gerado é versionado, e o CI regenera e reprova qualquer diferença.

### Consequências

- Bom: uma mudança de contrato aparece no mesmo commit como diff na especificação e nos tipos dos dois lados; a referência da API e os exemplos saem da mesma fonte; o código Rust não redigita nada do Dart.
- Ruim: o projeto mantém um gerador; toda operação nova começa pela especificação; o código gerado precisa compilar nas versões do SDK que NFR-FLEX-001 exige.

### Confirmação

NFR-MNT-006; regras CS-DRY-005 e CS-DRY-012 a 014 do Padrão de código; passo QG-09 do portão; oráculo ORC-10.
