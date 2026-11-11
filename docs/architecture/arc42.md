# Documentação de arquitetura

Arquitetura do Studio no modelo arc42, com diagramas C4. Versão 0.6, rascunho para revisão.

## 1. Introdução e objetivos

### 1.1 Resumo dos requisitos

O Studio edita visualmente projetos Flutter sem representação intermediária: a tela vem da execução do código do projeto, e cada edição é uma alteração de texto nos arquivos dele. Os requisitos estão no SRS. Os que mais moldam a arquitetura são:

- o projeto não recebe nada do Studio (DC-02, FR-PRJ-001);
- toda alteração passa por um único ponto, como `WorkspaceEdit` (FR-DOC-001);
- o canvas só mostra quadros do engine (FR-CNV-001, FR-CNV-002);
- a interface gráfica não tem privilégio sobre a API (FR-API-002).

### 1.2 Metas de qualidade

Em ordem de prioridade. Quando duas entram em conflito, vence a de cima.

| Prioridade | Meta | Característica ISO/IEC 25010 | Cenários |
| --- | --- | --- | --- |
| 1 | Integridade do código do usuário: nenhuma edição corrompe, reformata sem pedir ou deixa arquivo pela metade | Confiabilidade | QS-01, QS-02 |
| 2 | Fidelidade: o canvas mostra o que o código faz, e o que se edita é o código | Adequação funcional | QS-03 |
| 3 | Resposta imediata na seleção e na edição | Eficiência de desempenho | QS-04, QS-05 |
| 4 | Aprendizado por quem vem do Delphi | Capacidade de interação | QS-06 |
| 5 | Sustentação do fork diante do upstream | Manutenibilidade | QS-07, QS-08 |

### 1.3 Partes interessadas

| Parte | Interesse | O que espera desta documentação |
| --- | --- | --- |
| Dono do produto | Decide o escopo e aceita os incrementos | Decisões explícitas e critérios de aceite verificáveis |
| Agente implementador | Escreve e testa o código | Contratos fechados, requisitos atômicos, oráculos automáticos |
| Programador vindo de Delphi | Usuário final primário | Não lê; é representado por QS-06 e pelos requisitos NFR-INTR |
| Programador Flutter | Usuário final e possível colaborador | Garantia de que o projeto continua um projeto Flutter comum |
| Agentes de IA clientes | Usam o serviço `Studio` | Interface estável e descrita por máquina |
| Mantenedores do DevTools e do SDK | Mudam as bases de que o Studio depende | Não leem; são a origem dos riscos RSK-01 e RSK-02 |

## 2. Restrições

As restrições de projeto DC-01 a DC-08 estão no SRS, seção 3.6. As demais:

| Tipo | Restrição | Origem |
| --- | --- | --- |
| Técnica | O SDK do usuário não é modificado nem substituído. O Studio usa os binários e os protocolos que ele traz | NFR-COMP-002 |
| Técnica | O pacote de embedder do engine é publicado em modo debug (ver RSK-04) | Infraestrutura do Flutter |
| Técnica | Extensões do DevTools, visualizador Perfetto e suporte a WASM só existem no build web do DevTools | Código herdado |
| Organizacional | A implementação é feita por agente de IA, com um revisor humano | Dono do produto |
| Organizacional | Mensagens de commit, pull requests, issues e changelogs não levam rodapé de atribuição a ferramenta ou a agente | Dono do produto |
| Convenção | O código herdado segue `STYLE.md` e `AGENTS.md` do DevTools. O código novo segue as mesmas regras | Repositório |
| Convenção | Documentação versionada com o código, em Markdown; decisões em MADR | Guia deste conjunto |

## 3. Contexto e escopo

*Diagrama: contexto C4 · 2 atores, 4 sistemas vizinhos (disponível no documento original).*

O Studio é o único que fala com todos. Quem edita não toca o SDK nem o app alvo diretamente, e o projeto é compartilhado com outros editores.

| Vizinho | O que troca com o Studio | Interface |
| --- | --- | --- |
| Programador | Gestos e teclas; canvas, árvores e inspetor | Interface gráfica |
| Agente de IA | Chamadas de leitura e de edição; eventos | IF-04 |
| Projeto Flutter | Leitura, gravação atômica, observação de mudanças | IF-09 |
| SDK Flutter do projeto | Análise, edição de argumentos, sessões de debug, barramento | IF-01, IF-02, IF-03 |
| App alvo | Árvore em execução, locais de criação, quadros, entrada | IF-05, IF-06, IF-07 |
| Outros editores | Nada diretamente: gravam os mesmos arquivos | Por IF-09 |
| Armazenamento de artefatos do Flutter | Pacote de embedder por revisão de engine, a partir de F5 | HTTPS, com verificação de hash |

Ficam fora do sistema o SDK, o compilador, o engine e os serviços do pub.

## 4. Estratégia de solução

Seis escolhas dão forma ao sistema. Cada uma tem sua ADR.

| Problema | Abordagem | Decisão |
| --- | --- | --- |
| Editar sem representação intermediária | O código é a única fonte. A árvore em execução e a árvore de fonte são ligadas pelo local de criação de cada widget | ADR-0001, ADR-0005 |
| Não reescrever o que já existe | Fork do DevTools como fila de patches: inspector, editor de propriedades e depurador são herdados | ADR-0002 |
| Falar com o SDK sem acoplamento privado | O shell é cliente dos três protocolos que o Flutter oferece a editores: LSP, DAP e DTD | ADR-0003 |
| Garantir a integridade do código | Funil único de edição, com transação validada pelo analisador antes de tocar o disco | ADR-0004, ADR-0007 |
| Editar estrutura sem duplicar o analisador | Três níveis: `editArgument`, assists do servidor, e motor próprio só para o que falta | ADR-0006 |
| Mostrar o app real dentro do editor | Projeto host gerado, agente de design dentro do app e quadros transportados ao shell, em degraus de capacidade | ADR-0008, ADR-0009, ADR-0010 |

Duas escolhas atravessam todas. Quem analisa ou executa o projeto usa o SDK do projeto (ADR-0011). Toda operação é método de API antes de ser elemento de interface (ADR-0012).

## 5. Visão de blocos

*Diagrama: contêineres C4 · 3 processos do SDK, 3 blocos do Studio, o app alvo (disponível no documento original).*

O shell é o único processo com interface e o único que grava arquivos. Os demais existem para isolar o que executa código do projeto ou precisa do SDK dele.

### 5.1 Nível 1: blocos

| Bloco | Pacote | Tecnologia | Responsabilidade |
| --- | --- | --- | --- |
| Shell | `studio_shell`, `studio_core` e o `devtools_app` herdado | Flutter desktop, SDK fixado | Interface; `DocumentStore`; seleção; supervisão de processos; clientes LSP e DAP; serviços `Editor` e `Studio` no daemon; canvas |
| Motor de edição | `studio_source_engine` | Dart puro, SDK do projeto | Produz `WorkspaceEdit` para edições estruturais e objetos compostos; calcula o catálogo da paleta |
| Agente de design | `studio_design_agent` | Dart e Flutter, SDK do projeto, dentro do app alvo | Captura quadros e espelho de cena; aplica modo e configuração; injeta entrada; responde por canais de plataforma sem implementação |
| Host nativo (F5) | `studio_design_host` | Rust, API de embedder | Executa o projeto host no engine, compartilha a superfície com o shell e entrega a entrada |
| Contratos | `studio_protocol` | Dart puro | Tipos e esquemas de IF-04, IF-06 e IF-08; documento OpenRPC |
| Ferramentas | `studio_tool` | Dart, SDK fixado | Comando `st`: portão de qualidade, geração de tipos, rastreabilidade e referência de API; fica fora do produto entregue |

### 5.2 Nível 2: dentro do shell

| Componente | Responsabilidade | Depende de |
| --- | --- | --- |
| `DocumentStore` | Texto, versões, funil de edição, desfazer, gravação atômica, mapa de posições | Cliente LSP, sistema de arquivos |
| `SelectionController` | Seleção única entre as vistas; publica a posição ativa para os painéis herdados | `DocumentStore`, inspector herdado |
| `EditPipeline` | Transação de edição: encaminha ao nível certo, valida, confirma e pede o reload | `DocumentStore`, cliente LSP, motor de edição, cliente DAP |
| `ToolchainSupervisor` | Ciclo de vida dos processos filhos | Sistema operacional |
| `CanvasController` | Transporte de quadros (`FrameTransport`), espelho de cena, teste de acerto, sobreposições | Agente de design ou host nativo |
| `StudioService` | Registra e atende o serviço `Studio`; única entrada para operações | `EditPipeline`, `SelectionController`, `CanvasController` |
| Painéis herdados | Inspector, editor de propriedades, depurador, registros | `devtools_app`, serviço `Editor` |

## 6. Visão de execução

### 6.1 Edição de propriedade

*Diagrama: sequência · 5 participantes, 7 mensagens (disponível no documento original).*

A edição de valor é o caminho mais curto: o servidor produz a edição e a devolve ao shell, que é quem grava. O quadro novo chega depois da resposta, como evento.

### 6.2 Abertura de projeto

1. O shell localiza o SDK do projeto e confere a janela de versões.
2. Inicia o daemon, depois o analysis server, e pareia os dois com `dart/connectToDtd`.
3. Registra os serviços `Editor` e `Studio`.
4. Pede as superfícies de design ao analysis server.
5. Nenhum código do projeto é executado até o usuário abrir uma superfície ou iniciar o app.

### 6.3 Edição estrutural

Segue a transação da seção 8.3. A diferença para a figura é a origem do `WorkspaceEdit`, que vem do motor de edição, e o passo de validação antes da gravação.

### 6.4 Edição feita por fora

1. O observador de arquivos notifica o `DocumentStore`.
2. O documento é recarregado e a versão nova é enviada ao analysis server.
3. Chega um Flutter Outline novo, e a árvore de fonte é atualizada.
4. O shell pede hot reload; o quadro e a árvore em execução são atualizados.
5. A seleção é remapeada pelo mapa de posições. Se o widget deixou de existir, a seleção é limpa.

### 6.5 Falha do app alvo

1. O supervisor detecta o fim do processo.
2. A sessão passa ao estado `ended`. O canvas mantém o último quadro, marcado como desatualizado.
3. Os documentos e a pilha de desfazer permanecem intactos.
4. O shell oferece o reinício da sessão.

## 7. Visão de implantação

Tudo roda na máquina do usuário. Não há componente de servidor.

| Artefato | Origem | Local | Executado por |
| --- | --- | --- | --- |
| Shell e interface | Instalador do Studio | Diretório de instalação | Sistema operacional |
| `studio_source_engine` e `studio_design_agent`, em fonte Dart | Instalador do Studio | Diretório de instalação; resolvidos por `pub` contra o SDK do projeto | `dart` e `flutter` do SDK do projeto |
| Host nativo de design (F5) | Instalador do Studio | Diretório de instalação | Shell, como processo filho |
| Pacote de embedder do engine (F5) | Armazenamento oficial de artefatos do Flutter, por revisão de engine | Cache do usuário | Host nativo |
| Analysis server, adaptador de debug, Dart Tooling Daemon, `flutter_tester` | SDK Flutter do projeto | Diretório do SDK | Shell, como processos filhos |
| Projeto host de design | Gerado pelo Studio | `.dart_tool/studio/host/` no projeto | Adaptador de debug |
| Histórico local | Gerado pelo Studio | `.dart_tool/studio/history/` no projeto | Não é executado |
| Catálogo da paleta | Gerado pelo motor de edição | Cache do usuário, por pacote e versão | Não é executado |
| Preferências | Usuário | Configuração do usuário no sistema | Não é executado |

A distribuição é um instalador por sistema operacional. O instalador não inclui SDK Flutter.

## 8. Conceitos transversais

### 8.1 Documento e funil de edição

O `DocumentStore` é o único componente que altera arquivo do projeto. Mantém, por arquivo, o texto, a versão informada ao analysis server e a pilha de desfazer. Toda edição chega como `WorkspaceEdit`, venha do servidor (`workspace/applyEdit`), do motor de edição ou do editor de código.

A gravação é atômica: arquivo temporário no mesmo diretório, depois renomeação.

### 8.2 Duas árvores e uma chave

A árvore em execução vem das extensões do inspector. A árvore de fonte vem do Flutter Outline do analysis server. As duas se ligam pela tripla arquivo, linha e coluna do local de criação. Uma referência a widget na API é sempre essa tripla mais a versão do documento (`WidgetRef`).

O app executa a versão do último reload, e o documento pode estar adiante. O `DocumentStore` mantém, por arquivo, o mapa de posições entre a versão em execução e a versão atual, composto das edições aplicadas desde o último reload.

### 8.3 Transação de edição

1. O chamador submete a operação com a versão de documento que conhece.
2. Se a versão não for a atual, a operação é recusada com `StaleDocument`.
3. O motor produz o `WorkspaceEdit`.
4. O `DocumentStore` aplica a edição em memória e a envia ao analysis server como conteúdo não gravado.
5. Se os erros de análise aumentarem, a edição é revertida em memória e recusada com `EditRejected`.
6. Caso contrário, os arquivos são gravados, a pilha de desfazer recebe a edição inversa e o reload é pedido.

Edições de valor produzidas pelo próprio servidor (`editArgument`) pulam os passos 4 e 5.

### 8.4 Supervisão de processos

O `ToolchainSupervisor` inicia, observa e reinicia os processos filhos.

| Processo | Ao terminar inesperadamente |
| --- | --- |
| Analysis server | Reinicia, reabre os documentos, refaz `dart/connectToDtd` |
| Dart Tooling Daemon | Reinicia, registra de novo `Editor` e `Studio`, reconecta os demais |
| Adaptador de debug ou app alvo | Marca a sessão como encerrada, mantém o último quadro, oferece reinício |
| Motor de edição | Reinicia; a operação em curso falha com `ToolchainUnavailable` |
| Host nativo | Reinicia; após duas falhas seguidas, cai para o host sem toolchain |

### 8.5 Versões de SDK

O Studio é construído com um SDK fixado, prática herdada do DevTools. O projeto usa o SDK do usuário. O motor de edição e o agente de design são resolvidos e executados com o SDK do projeto, uma resolução por versão de SDK, guardada no cache do usuário.

Recursos do analysis server são detectados por capacidade anunciada, não por número de versão.

### 8.6 Segurança

Abrir uma superfície de design executa código do projeto com os privilégios do usuário, como em qualquer IDE. O controle é a confirmação de confiança por projeto (NFR-SEC-001).

| Ameaça (STRIDE) | Onde | Controle |
| --- | --- | --- |
| Elevação de privilégio | Código do projeto executado no host de design | Confirmação de confiança; host sem privilégio além do usuário corrente |
| Adulteração | Cliente local chama `Studio` para escrever arquivos | Endereço do daemon com segredo; escrita restrita às raízes do projeto (NFR-SEC-002, NFR-SEC-003) |
| Adulteração | Binário de engine baixado | Hash contra manifesto (NFR-SEC-004) |
| Divulgação de informação | Quadros em memória compartilhada | Segmento com nome aleatório e permissão apenas do usuário corrente |
| Negação de serviço | App alvo em laço ou sem resposta | Processo separado, supervisão e tempo limite por chamada |
| Repúdio e falsificação de identidade | Uso local por um único usuário | Fora de escopo |

### 8.7 Localização e vocabulário

Os textos da interface própria ficam em arquivos ARB, em português do Brasil e em inglês. As telas herdadas do DevTools permanecem em inglês até serem localizadas. A correspondência entre Delphi e Flutter é dado, não código: uma tabela única alimenta rótulos e ajuda.

### 8.8 Gestão do fork

O produto mora em pacotes `studio_*`, em `studio/packages/`, num workspace do pub separado do herdado e construído com o Flutter estável (ADR-0014). O código herdado só recebe patch para abrir ponto de extensão. Cada patch é marcado no código com `// STUDIO-PATCH(n)` e descrito em `PATCHES.md`, com motivo e situação no upstream. O rebase semanal é automatizado e validado pelos testes herdados.

### 8.9 Registro e diagnóstico

Cada processo grava registro estruturado em arquivo local, com o identificador da operação propagado do shell aos processos filhos. Não há telemetria.

### 8.10 Padrão de código

As regras de escrita, nomes, comentários e documentação gerada estão em Padrão de código. O comando `st verify` as aplica a todo o código próprio, e nenhuma mudança entra sem ele aprovado.

## 9. Decisões de arquitetura

As decisões estão registradas uma a uma em Decisões (ADR). O estado de cada uma está no índice, em `docs/decisions/README.md`.

## 10. Requisitos de qualidade

### 10.1 Visão geral

| Característica | Subcaracterística | Cenários | Requisitos |
| --- | --- | --- | --- |
| Confiabilidade | Ausência de falhas, recuperabilidade | QS-01, QS-02, QS-09 | NFR-REL-001 a 004, FR-STR-008 |
| Adequação funcional | Correção | QS-03 | FR-CNV-001, FR-DOC-007 |
| Eficiência de desempenho | Comportamento no tempo | QS-04, QS-05 | NFR-PERF-001 a 005 |
| Capacidade de interação | Capacidade de aprendizado | QS-06 | NFR-INTR-001 a 006 |
| Manutenibilidade | Modificabilidade, testabilidade | QS-07, QS-08 | NFR-MNT-001 a 004 |
| Flexibilidade | Adaptabilidade | QS-10 | NFR-FLEX-001 e 002 |
| Segurança | Integridade | QS-11 | NFR-SEC-001 a 005 |
| Compatibilidade | Coexistência | QS-12 | NFR-COMP-001 e 002, FR-DOC-003 |

### 10.2 Cenários

| ID | Estímulo | Ambiente | Resposta | Medida |
| --- | --- | --- | --- | --- |
| QS-01 | Edição estrutural que introduz erro de tipo | Projeto analisado sem erros | A edição é descartada | Zero bytes alterados em disco; diagnóstico exibido |
| QS-02 | Sequência de 100 edições seguida de 100 desfazer | Qualquer arquivo do corpus | Os arquivos voltam ao estado inicial | Hash dos arquivos igual ao inicial |
| QS-03 | Alteração de uma propriedade no inspetor | Arquivo formatado, com comentários | Só o argumento muda | `git diff` restrito à expressão do argumento |
| QS-04 | Clique num widget no canvas | Host de design ativo, espelho de cena presente | Seleção exibida | 16 ms no percentil 95 |
| QS-05 | Confirmação de edição de propriedade | Projeto de referência pequeno | Quadro novo no canvas | 250 ms na mediana, 500 ms no percentil 95 |
| QS-06 | Programador Delphi recebe a tarefa do formulário com três campos e um botão | Primeira sessão, sem documentação externa | Conclui a tarefa | 15 minutos; 4 de 5 participantes |
| QS-07 | Versão estável nova do Flutter muda o inspector | Fork com fila de patches | Rebase concluído e testes passando | Até 7 dias após a publicação |
| QS-08 | Pedido de uma operação de edição nova | Motor de edição existente | Operação implementada com teste de corpus | Nenhuma alteração fora de `studio_source_engine` e do contrato |
| QS-09 | O processo do app alvo é morto durante um arraste | Sessão de design ativa | O Studio segue operante, com o documento intacto | Nenhuma edição parcial gravada; reinício oferecido em até 2 s |
| QS-10 | Projeto fixado numa versão estável três versões atrás | Matriz de SDKs | Abre, inspeciona e edita | Testes de sistema passam em toda a matriz |
| QS-11 | Cliente local chama `setProperty` com arquivo fora do projeto | Serviço `Studio` ativo | Chamada recusada | Erro `NotInProject`; nenhum arquivo tocado |
| QS-12 | Outro editor grava um arquivo durante a sessão | Arquivo sem alteração pendente no Studio | Árvores e canvas se atualizam | Sem ação do usuário; até 1 s mais o tempo de reload |

## 11. Riscos e dívida técnica

| ID | Risco | Prob. | Impacto | Resposta |
| --- | --- | --- | --- | --- |
| RSK-01 | Os métodos `editableArguments` e `editArgument` são extensões do analysis server, sem garantia de estabilidade | Média | Alto | Detecção por capacidade; teste de contrato na matriz de SDKs; o motor próprio cobre o caso como reserva |
| RSK-02 | O upstream reorganiza o inspector ou o editor de propriedades e quebra os patches | Alta | Médio | Fila de patches mínima; rebase semanal; propor os pontos de extensão ao upstream |
| RSK-03 | `flutter_tester` não serve de host interativo (ASM-01) | Média | Alto | Experimento em F0; dispositivo desktop como reserva; antecipar o host próprio |
| RSK-04 | O pacote de embedder só existe em modo debug, e custom devices é recurso experimental (ASM-04, ASM-05) | Média | Médio | Host próprio só em F5; pipeline de reload próprio como reserva |
| RSK-05 | Hot reload acima da meta em projetos grandes (ASM-08) | Média | Médio | Medir em F0; o ajuste ao vivo cobre a interação; pipeline próprio como reserva |
| RSK-06 | A junção por local de criação falha com fábricas, extensões, código gerado ou widgets constantes | Média | Alto | Oráculo de junção no corpus; casos catalogados ficam somente leitura |
| RSK-07 | Edição estrutural corrompe código em casos de borda | Média | Alto | Transação validada; oráculos de corpus e diferencial; desfazer exato |
| RSK-08 | Telas que dependem de plugin nativo não renderizam no host | Alta | Médio | Resposta vazia com aviso; edição sobre dispositivo real (FR-HST-005) |
| RSK-09 | Abrir um projeto malicioso executa código | Baixa | Alto | Confirmação de confiança (NFR-SEC-001) |
| RSK-10 | O editor de código consome o esforço de F4 (ASM-07) | Média | Médio | Pacote existente atrás de interface própria; abrir no editor externo sempre disponível |
| RSK-11 | O SDK que o upstream fixa em `flutter-candidate.txt` é uma pré-versão trocada com frequência, e uma regressão do engine nela atinge o shell em desktop. Ocorrência em 11/11/2026: no candidato `de37392d`, em Linux com driver proprietário da NVIDIA, a janela desenha o conteúdo deslocado em meia janela ([flutter/flutter#195885](https://github.com/flutter/flutter/issues/195885)) | Alta | Médio | O produto é construído com o Flutter estável, e o candidato fica só para os testes herdados (ADR-0014); a cada rebase, build do shell e conferência em desktop nos três sistemas |

Dívida técnica assumida nesta baseline:

- As telas herdadas do DevTools ficam em inglês.
- Extensões do DevTools e o visualizador Perfetto ficam indisponíveis no build desktop.
- O primeiro transporte de quadros copia os pixels pela memória principal.
- Até o serviço `Studio` existir, o painel de propriedades herdado pede a edição ao analysis server direto pelo daemon, e o shell só aplica o `workspace/applyEdit` que volta. É o desvio temporário de FR-API-002 aprovado para o primeiro entregável.
- O Dart Tooling Daemon não termina quando o processo pai morre. O shell o encerra ao sair e ao receber sinal de término, mas um shell morto à força deixa o daemon rodando.

## 12. Glossário

| Termo | Definição |
| --- | --- |
| Agente de design | Código Dart do Studio que roda dentro do app alvo, captura quadros e geometria e recebe entrada |
| App alvo | O código do projeto em execução, num host de design ou num dispositivo |
| Canvas | Painel do Studio que exibe os quadros do app alvo com as sobreposições de seleção |
| DAP | Debug Adapter Protocol |
| DTD | Dart Tooling Daemon, barramento JSON-RPC local entre ferramentas Dart |
| Espelho de cena | Lista, por quadro, da geometria e do local de criação de cada elemento do projeto |
| Funil de edição | Caminho único pelo qual toda alteração de arquivo chega ao `DocumentStore` |
| Host de design | Processo que executa o projeto host: `flutter_tester` ou o host nativo próprio |
| Local de criação | Arquivo, linha e coluna da expressão que constrói um widget, registrados pelo framework em modo debug |
| LSP | Language Server Protocol |
| Projeto host | Projeto Flutter gerado em `.dart_tool/studio/host/`, que importa o projeto do usuário e o agente de design |
| Shell | O aplicativo desktop do Studio |
| Slot | Parâmetro de construtor que recebe widget: `child`, `children`, nomeado ou builder |
| Superfície de design | Alvo que o canvas pode abrir: função ou construtor com `@Preview`, ou widget sem parâmetro obrigatório |
| `WidgetRef` | Referência a um widget pela tripla do local de criação mais a versão do documento |

Correspondência entre Delphi e Flutter, usada pela interface (NFR-INTR-003):

| Delphi | Flutter | Observação |
| --- | --- | --- |
| Form | `StatefulWidget` com `@Preview` | Um arquivo por formulário |
| Unit | Biblioteca, um arquivo `.dart` |  |
| `uses` | `import` |  |
| Component, Control | Widget |  |
| Object Inspector, aba Properties | Argumentos do construtor |  |
| Object Inspector, aba Events | Parâmetros de tipo função |  |
| Tool Palette | Paleta derivada dos pacotes | Sem pacote de design-time |
| Structure | Árvore de fonte | Mostra os slots |
| `Parent` e `Controls` | Slots `child` e `children` |  |
| `Align = alClient` | `Expanded` | Dentro de `Row`, `Column` ou `Flex` |
| `Anchors` | `Positioned` dentro de `Stack`, ou `Align` |  |
| `Margins` e `Padding` | `Padding` | É widget, não propriedade |
| `Name` | Variável ou controller extraído | Widgets não têm nome |
| `TFrame` | Widget extraído |  |
| `Enabled`, `Visible` | Argumento ou condição no código |  |
| Run, F9 | Modo execução ou sessão em dispositivo |  |
| `__history` | `.dart_tool/studio/history/` |  |
