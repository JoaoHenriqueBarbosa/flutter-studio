# Especificação de interfaces

Contratos entre os processos do Studio e com o SDK. Mensagens em JSON-RPC 2.0; palavras normativas conforme a BCP 14. Versão 0.9, rascunho para revisão.

## 1. Inventário de interfaces

Nove interfaces ligam os processos do Studio entre si e ao SDK. O Studio define IF-04, IF-06, IF-07 e IF-08. As demais são consumidas como o SDK as oferece.

| ID | Entre | Protocolo e transporte | Definida em |
| --- | --- | --- | --- |
| IF-01 | Shell e analysis server | LSP, JSON-RPC 2.0 sobre entrada e saída padrão | SDK; uso na seção 4 |
| IF-02 | Shell e adaptador de debug | DAP sobre entrada e saída padrão | SDK; uso na seção 4 |
| IF-03 | Shell e Dart Tooling Daemon | JSON-RPC 2.0 sobre WebSocket local | SDK; uso na seção 4 |
| IF-04 | Clientes e serviço `Studio` | JSON-RPC 2.0, pelo daemon | Seção 2 |
| IF-05 | Shell e app alvo | VM Service sobre WebSocket: extensões do inspector e avaliação de expressão | SDK; uso na seção 4 |
| IF-06 | Shell e agente de design | Controle por extensões de serviço `ext.studio.agent.*`; quadros por memória compartilhada | Seção 3 |
| IF-07 | Shell e host nativo (F5) | Processo filho; superfície de GPU compartilhada; entrada pela API de embedder | A especificar em F5 |
| IF-08 | Shell e motor de edição | JSON-RPC 2.0 sobre entrada e saída padrão | Contrato interno, no pacote `studio_protocol` |
| IF-09 | Shell e sistema de arquivos | Leitura, gravação atômica e observação de mudanças | Arquitetura, seção 8.1 |

Regras comuns:

- Posições são `{line, character}`, com base zero e em unidades de código UTF-16, como no LSP.
- Arquivos são identificados por URI `file:`.
- Todo parâmetro é passado por nome.

## 2. Serviço `Studio`

O shell registra o serviço `Studio` no Dart Tooling Daemon. Um cliente chama `Studio.<method>` pela conexão que já tem com o daemon. Esta seção é a referência legível. A forma normativa é o documento OpenRPC `studio.openrpc.json`, na raiz do pacote `studio_protocol`, servido por `rpc.discover` (FR-API-003). O documento OpenRPC traz os métodos, os campos e os eventos dos incrementos já construídos; esta seção traz o contrato inteiro, com o incremento de cada parte.

### 2.1 Regras

- O contrato tem versão semântica, devolvida por `getVersion`. Esta é a versão 0.6.0.
- Todo `WidgetRef` enviado a um método de edição DEVE trazer `documentVersion`. Se não for a versão atual do documento, o serviço DEVE responder `StaleDocument` sem alterar nada.
- Um método de edição DEVE ser atômico: ou todos os arquivos da edição são gravados, ou nenhum.
- O serviço NÃO DEVE aceitar URI fora das raízes do projeto.
- O serviço DEVE processar as edições uma por vez, na ordem de chegada.
- No daemon, o resultado de um método viaja no envelope `{type: "StudioResult", result: <valor>}`, como no serviço `Lsp` do SDK, porque o daemon só transporta resultado que seja objeto com o campo `type`. Os nomes do serviço, do fluxo e do envelope ficam na chave `x-binding` do documento OpenRPC.

### 2.2 Tipos

| Tipo | Campos | Significado |
| --- | --- | --- |
| `Position` | `line: int`, `character: int` | Posição no documento |
| `WidgetRef` | `uri: string`, `position: Position`, `documentVersion: int` | Local de criação de um widget, numa versão do documento |
| `SlotRef` | `name: string`, `index?: int` | Slot de um widget; `index` posiciona dentro de uma lista |
| `Expression` | `source: string` | Expressão Dart em texto |
| `WidgetSpec` | `libraryUri: string`, `className: string`, `constructorName?: string` (F3), `arguments?: map<string, Expression>` (F3) | Widget a criar |
| `StructureOptions` | `wrappers: WidgetSpec[]`, `canRemove`, `canMoveUp`, `canMoveDown`, `canSwapWithParent`, `canSwapWithChild` | Edições de estrutura que um widget admite |
| `Property` | `name`, `type`, `expression?`, `defaultValue?`, `runtimeValue?` (F2), `isSet`, `isEditable`, `isEvent` (F3), `options?: string[]`, `documentation?` | Parâmetro do construtor de um widget. `type` é o gênero do valor como o analysis server o nomeia (`string`, `int`, `double`, `bool`, `enum` ou outro); `options` traz os valores aceitos por um enum |
| `SourceNode` | `ref: WidgetRef`, `className`, `owner?: string`, `slot?: SlotRef` (F3), `children: SourceNode[]`, `emptySlots: SlotRef[]` (F3) | Nó da árvore de fonte. `owner` é o nome qualificado da declaração que cria o widget, como `MyHomePage.build`, e só vem nos widgets que nenhum outro contém. Os slots dependem do motor de edição (ASM-03) |
| `RuntimeNode` | `id` (F2), `className`, `ref: WidgetRef`, `bounds` (`left`, `top`, `width`, `height`, em pixels lógicos), `children: RuntimeNode[]` | Nó da árvore em execução. Nesta versão a árvore só traz os widgets criados no projeto |
| `Surface` | `id`, `kind` (`preview`, `widget` ou `app`), `name`, `ref?: WidgetRef` | Alvo que o canvas pode abrir |
| `SurfaceConfig` | `width`, `height`, `devicePixelRatio`, `brightness`, `platform`, `textScale`, `locale` | Configuração de exibição de uma superfície |
| `TextDocumentEdit` | `uri: string`, `edits: TextEdit[]`, cada um com `range` e `newText` | Edições feitas em um documento, com intervalos que se referem ao texto anterior |
| `EditResult` | `applied: bool`, `changes: TextDocumentEdit[]`, `documentVersions: map<string, int>`, `reload` (`hotReload`, `hotRestart` ou `none`) | Resultado de uma edição |

### 2.3 Métodos

| Método | Parâmetros | Resultado | Inc. |
| --- | --- | --- | --- |
| `getVersion` | nenhum | `{version: string}` | F1 |
| `getSourceTree` | `uri` | `SourceNode[]`: os widgets do arquivo que nenhum outro contém, na ordem do fonte | F1 |
| `getRuntimeTree` | nenhum; `sessionId` entra com as sessões de superfície, em F2 | `RuntimeNode[]`: as raízes da árvore do app em execução | F1 |
| `getSelection` | nenhum | `WidgetRef` ou nulo | F1 |
| `select` | `target: WidgetRef` | `WidgetRef` efetivamente selecionado | F1 |
| `getProperties` | `target: WidgetRef` | `Property[]` | F1 |
| `setProperty` | `target`, `name`, `value: Expression`, ou nulo para remover o argumento | `TextDocumentEdit` | `uri: string`, `edits: TextEdit[]`, cada um com `range` e `newText` | Edições feitas em um documento, com intervalos que se referem ao texto anterior |
| `EditResult` | F1 |
| `wrapWidget` | `target`, `wrapper: WidgetSpec` | `TextDocumentEdit` | `uri: string`, `edits: TextEdit[]`, cada um com `range` e `newText` | Edições feitas em um documento, com intervalos que se referem ao texto anterior |
| `EditResult` | F1 |
| `removeWidget` | `target`, `keepChildren: bool` | `TextDocumentEdit` | `uri: string`, `edits: TextEdit[]`, cada um com `range` e `newText` | Edições feitas em um documento, com intervalos que se referem ao texto anterior |
| `EditResult` | F1 |
| `undo`, `redo` | nenhum | `TextDocumentEdit` | `uri: string`, `edits: TextEdit[]`, cada um com `range` e `newText` | Edições feitas em um documento, com intervalos que se referem ao texto anterior |
| `EditResult` | F1 |
| `listSurfaces` | nenhum | `Surface[]` | F2 |
| `openSurface` | `surfaceId`, `config?: SurfaceConfig` | `{sessionId: string}` | F2 |
| `captureFrame` | `sessionId`, `target?: WidgetRef` | `{png, width, height, frameId}`, com `png` em base64 | F2 |
| `insertWidget` | `parent: WidgetRef`, `slot: SlotRef`, `widget: WidgetSpec` | `TextDocumentEdit` | `uri: string`, `edits: TextEdit[]`, cada um com `range` e `newText` | Edições feitas em um documento, com intervalos que se referem ao texto anterior |
| `EditResult` | F3 |
| `moveWidget` | `target`, `parent: WidgetRef`, `slot: SlotRef` | `TextDocumentEdit` | `uri: string`, `edits: TextEdit[]`, cada um com `range` e `newText` | Edições feitas em um documento, com intervalos que se referem ao texto anterior |
| `EditResult` | F3 |
| `duplicateWidget` | `target` | `TextDocumentEdit` | `uri: string`, `edits: TextEdit[]`, cada um com `range` e `newText` | Edições feitas em um documento, com intervalos que se referem ao texto anterior |
| `EditResult` | F3 |
| `createEventHandler` | `target`, `event: string` | `EditResult` e a localização do método criado | F3 |
| `listPalette` | `query?: string` | `WidgetSpec[]`, com documentação | F3 |

O contrato 0.6.0 traz `getVersion`, `getSourceTree`, `getRuntimeTree`, `getSelection`, `select`, `getProperties`, `setProperty`, `getStructureOptions`, `wrapWidget`, `removeWidget`, `reorderWidget`, `swapWidget`, `undo` e `redo`. Os demais métodos de F1 entram com as operações que os atendem.

Limites da versão 0.6.0, que realiza os dois primeiros níveis da ADR-0006:

- `setProperty` grava um literal do gênero do parâmetro pelo analysis server, esteja o argumento no código ou não. Outra expressão só substitui a de um argumento que já está no código, e `value` nulo remove do código um argumento nomeado; as duas são edições do texto do argumento, sem validação pelo analisador nesta versão (FR-PRP-007, FR-PRP-008). Expressão não literal para argumento ausente e remoção de argumento posicional respondem `UnsupportedTarget`.
- `wrapWidget` aceita os widgets que `getStructureOptions` lista em `wrappers`, que são os que o analysis server sabe envolver. Outro widget responde `UnsupportedTarget` até o motor de edição existir.
- `removeWidget` com `keepChildren` falso responde `UnsupportedTarget`: excluir a subárvore é FR-STR-005, de F3.

### 2.4 Eventos

Publicados no fluxo `Studio` do daemon.

| Evento | Dados | Quando |
| --- | --- | --- |
| `selectionChanged` | `{selection?: WidgetRef}`, sem o campo quando nada está selecionado | A seleção muda, por qualquer vista ou cliente |
| `documentChanged` | `uri`, `documentVersion`, `origin` (`studio` ou `external`) | Um documento do projeto muda |
| `frameProduced` | `sessionId`, `frameId` | Um quadro novo está disponível |
| `sessionStateChanged` | `sessionId`, `state` (`starting`, `running`, `stale` ou `ended`) | O estado de uma sessão muda |

### 2.5 Erros

Os códigos ficam na faixa que o JSON-RPC 2.0 reserva a erros definidos pela implementação.

| Código | Nome | Significado | Dados |
| --- | --- | --- | --- |
| -32001 | `StaleDocument` | A versão informada não é a atual | Versão atual |
| -32002 | `NotInProject` | O alvo está fora das raízes do projeto | URI |
| -32003 | `EditRejected` | A transação aumentaria os erros de análise | Diagnósticos |
| -32004 | `NoSession` | Não há sessão com o identificador dado | Identificador |
| -32005 | `UnsupportedTarget` | O alvo não admite a operação pedida | Motivo |
| -32006 | `ToolchainUnavailable` | Um processo necessário não está em execução | Processo |

## 3. Agente de design

O agente roda dentro do app alvo. O canal de controle usa extensões de serviço do VM Service. O canal de quadros usa memória compartilhada, porque o volume não cabe em JSON. Esta é a versão 1 do protocolo, a confirmar no incremento F2.

Os nomes das extensões e os tipos dos resultados ficam no documento OpenRPC do `studio_protocol`, na chave `x-agent`, de onde saem as constantes e os tipos usados pelo shell e pelo agente (ADR-0013).

Construído até aqui: `ext.studio.agent.hello` e `ext.studio.agent.scene`. A primeira devolve `protocolVersion` e `isWidgetCreationTracked`, que diz se o app foi compilado com o rastreamento de criação de widgets (FR-INS-007). A segunda não está na tabela de controle abaixo: ela devolve o espelho de cena da seção 3.3 em JSON, enquanto o segmento de memória compartilhada não existe. Cada elemento traz `className`, `uri` e `position` do local de criação, `parentIndex` e o retângulo `left`, `top`, `width` e `height` na superfície, em pixels lógicos, no lugar da matriz de transformação; a cena traz ainda `width`, `height` e `devicePixelRatio` da superfície.

### 3.1 Controle

| Extensão | Parâmetros | Efeito |
| --- | --- | --- |
| `ext.studio.agent.hello` | nenhum | Devolve `protocolVersion` e as capacidades do agente |
| `ext.studio.agent.attachFrames` | `name: string`, `capacity: int` | O agente abre o segmento de memória criado pelo shell e passa a escrever os quadros nele |
| `ext.studio.agent.locations` | nenhum | Devolve a tabela de locais de criação vigente: índice, URI, linha e coluna |
| `ext.studio.agent.setMode` | `mode` (`design` ou `run`) | Em `design`, pausa as animações e ignora entrada |
| `ext.studio.agent.configure` | `SurfaceConfig` | Aplica tamanho, densidade, brilho, plataforma, escala de texto e localidade |
| `ext.studio.agent.pointer` | `kind`, `x`, `y`, `buttons`, `device` | Injeta um evento de ponteiro, em modo `run` |
| `ext.studio.agent.key` | `kind`, `physicalKey`, `logicalKey`, `character?` | Injeta um evento de tecla, em modo `run` |
| `ext.studio.agent.textInput` | `text`, `selectionBase`, `selectionExtent` | Atualiza o estado do campo de texto que tem o foco |

### 3.2 Segmento de quadros

O shell cria o segmento, o agente escreve e o shell lê. Inteiros em little-endian.

| Deslocamento | Bytes | Campo | Conteúdo |
| --- | --- | --- | --- |
| 0 | 4 | `magic` | `STFR` |
| 4 | 2 | `version` | 1 |
| 6 | 2 | `flags` | Reservado, zero |
| 8 | 4 | `sequence` | Contador da trava de sequência |
| 12 | 4 | `width` | Largura em pixels físicos |
| 16 | 4 | `height` | Altura em pixels físicos |
| 20 | 4 | `stride` | Bytes por linha |
| 24 | 8 | `frameId` | Crescente a cada quadro |
| 32 | 4 | `sceneLength` | Bytes do espelho de cena |
| 36 | 28 | reservado | Zero |
| 64 | `stride` vezes `height` | `pixels` | RGBA, 8 bits por canal, alfa pré-multiplicado |
| após `pixels` | `sceneLength` | `scene` | Espelho de cena |

Escrita e leitura seguem a trava de sequência. O agente incrementa `sequence` antes de escrever, o que o deixa ímpar, e de novo ao terminar. O shell lê `sequence`, copia o conteúdo, lê `sequence` de novo e descarta a cópia se o valor mudou ou era ímpar.

### 3.3 Espelho de cena

Um registro de 88 bytes por elemento criado no projeto, em pré-ordem da árvore.

| Campo | Tipo | Conteúdo |
| --- | --- | --- |
| `elementId` | u32 | Identificador do elemento, estável enquanto ele existir |
| `locationId` | u32 | Índice na tabela de locais de criação |
| `parentIndex` | i32 | Índice do registro do pai, ou -1 |
| `flags` | u32 | Bit 0: visível. Bit 1: recortado por ancestral |
| `transform` | 16 valores f32 | Matriz do espaço local para o da superfície, por colunas |
| `width`, `height` | 2 valores f32 | Tamanho local, em pixels lógicos |

O shell faz o teste de acerto e desenha as alças com o espelho do mesmo `frameId` que está exibindo (FR-CNV-006).

## 4. Interfaces consumidas do SDK

O Studio usa cada interface como o SDK instalado a oferece e verifica a presença de cada elemento antes de usá-lo.

| Interface | Elementos usados | Para quê |
| --- | --- | --- |
| LSP, métodos padrão | `textDocument/didOpen`, `didChange` e `didClose`; `publishDiagnostics`; `codeAction`; `workspace/executeCommand`; `workspace/applyEdit`; `rangeFormatting`; `completion`; `hover`; `definition`; `rename`; `semanticTokens` | Documentos, diagnósticos, assists, formatação e editor de código |
| LSP, extensões do Dart | `dart/textDocument/editableArguments`; `dart/textDocument/editArgument`; `dart/textDocument/publishFlutterOutline`; `dart/workspace/getFlutterWidgetPreviews`; `dart/connectToDtd` | Propriedades, árvore de fonte, superfícies de design e pareamento com o daemon |
| DAP | `launch`, `attach`, `setBreakpoints`, `stackTrace`, `scopes`, `variables`, `evaluate`, `continue`, `next`, `stepIn`, `stepOut`, `disconnect`; requisições `hotReload` e `hotRestart` do Flutter | Execução, recarga e depuração |
| Dart Tooling Daemon | `registerService`, `streamListen`, `postEvent`; serviço `Editor`, registrado pelo shell: `navigateToCode`, `getActiveLocation`, `getDebugSessions`, `hotReload`, `hotRestart`; evento `activeLocationChanged` | Barramento, e o papel de editor que os painéis herdados esperam |
| VM Service, extensões do inspector | `isWidgetCreationTracked`, `addPubRootDirectories`, `getRootWidgetTree`, `getDetailsSubtree`, `getProperties`, `getLayoutExplorerNode`, `setSelectionById`, `getSelectedWidget`, `setFlexFit`, `setFlexFactor`, `setFlexProperties`, `screenshot` | Árvore em execução, locais de criação, layout e capturas |
| VM Service, núcleo | `evaluate`, `callServiceExtension`, eventos de extensão | Ajuste ao vivo e canal de controle do agente |
| Ferramenta `flutter` | `debug-adapter`, `create`, `pub add`, `pub remove`, `build` | Sessões e operações de projeto |
| API de embedder (F5) | Execução do engine, métricas de janela, eventos de ponteiro e de tecla, superfícies de composição, adição e remoção de view | Host nativo |

Elementos que o SDK marca como experimentais estão tratados como risco (RSK-01, RSK-04).
