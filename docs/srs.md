# Especificação de requisitos de software

Requisitos do Studio na estrutura da ISO/IEC/IEEE 29148:2018. Versão 0.2, rascunho para revisão.

## 1. Introdução

### 1.1 Propósito

Este documento especifica o que o Studio deve fazer e os limites dentro dos quais deve fazê-lo. É a base para o projeto, a implementação e a verificação.

### 1.2 Escopo

O Studio é um ambiente de desenvolvimento desktop para projetos Flutter. Permite inspecionar e editar visualmente a interface de um projeto existente, editar seu código, executá-lo e depurá-lo. O código Dart do projeto é a única representação da interface.

Estão fora do escopo: publicação em lojas e assinatura de aplicativos, edição de imagens e ícones, serviços de backend, um framework próprio de gerência de estado e uma biblioteca própria de componentes.

### 1.3 Visão do produto

**1.3.1 Perspectiva.** O Studio é derivado do Dart & Flutter DevTools e opera sobre o SDK Flutter instalado pelo usuário. Usa do SDK o analysis server, o adaptador de debug, o Dart Tooling Daemon e a ferramenta `flutter`. Não substitui o SDK nem o compilador. As interfaces estão na especificação de interfaces.

**1.3.2 Funções.** Em resumo, o Studio:

- abre um projeto Flutter sem modificá-lo;
- mostra o projeto em execução num canvas ou num dispositivo;
- liga cada widget na tela ao ponto do código que o cria;
- edita propriedades, estrutura e eventos gravando no código;
- oferece editor de código, execução e depuração;
- expõe as mesmas operações por uma API local.

**1.3.3 Usuários.**

| Perfil | Características | O que espera |
| --- | --- | --- |
| Programador vindo de Delphi | Longa experiência em desenvolvimento visual para desktop, pouca ou nenhuma em Flutter, usa Windows | Formulário, inspetor de objetos, paleta, F9, e entender o código que resulta |
| Programador Flutter | Conhece o framework e usa outro editor em paralelo | Edição visual que não altere o estilo do código nem crie dependência |
| Agente de IA | Opera sem interface gráfica | API completa, determinística e descrita por máquina |

**1.3.4 Limitações.**

- Exige um SDK Flutter instalado, dentro da janela de versões suportadas (NFR-FLEX-001).
- Edita visualmente apenas widgets cujo local de criação está em arquivo do projeto.
- Plugin sem implementação no host de design responde com valor vazio no canvas (FR-HST-003).
- Não edita código gerado nem arquivos fora das raízes do projeto.

### 1.4 Definições

Os termos estão no glossário, seção 12 do documento de arquitetura.

## 2. Referências

As normas e as fontes técnicas estão listadas no guia deste conjunto.

## 3. Requisitos

### 3.1 Funções

Cada linha traz o incremento em que o requisito entra (Inc.) e o método de verificação (Ver.).

#### Projeto e sessão

| ID | Requisito | Inc. | Ver. |
| --- | --- | --- | --- |
| FR-PRJ-001 | Quando o usuário abre um diretório que contém `pubspec.yaml` com dependência do SDK `flutter`, o Studio DEVE carregá-lo como projeto sem criar nem alterar arquivo fora de `.dart_tool/`. | F0 | T |
| FR-PRJ-002 | Quando um projeto é aberto, o Studio DEVE localizar o SDK Flutter do projeto nesta ordem: versão fixada no projeto (`.fvmrc`), configuração do Studio, `PATH`. | F0 | T |
| FR-PRJ-003 | Se o SDK localizado estiver fora da janela de versões suportadas, então o Studio DEVE informar a versão encontrada e a janela, e NÃO DEVE iniciar sessão de edição. | F0 | T |
| FR-PRJ-004 | Quando um projeto é aberto, o Studio DEVE iniciar o Dart Tooling Daemon e o analysis server do SDK do projeto e registrar no daemon os serviços `Editor` e `Studio`. | F0 | T |
| FR-PRJ-005 | Quando o usuário cria um projeto, o Studio DEVE criá-lo com `flutter create`, sem modelo de projeto próprio. | F4 | T |
| FR-PRJ-006 | Quando o usuário cria um formulário, o Studio DEVE gerar um arquivo Dart com um `StatefulWidget` e uma função anotada com `@Preview`. | F4 | T |
| FR-PRJ-007 | Quando o usuário adiciona ou remove um pacote, o Studio DEVE fazê-lo com `flutter pub add` ou `flutter pub remove`. | F4 | T |

#### Documentos e edição

| ID | Requisito | Inc. | Ver. |
| --- | --- | --- | --- |
| FR-DOC-001 | O Studio DEVE aplicar toda alteração em arquivo do projeto por um único componente, o `DocumentStore`, na forma de `WorkspaceEdit`. | F0 | I |
| FR-DOC-002 | Quando uma edição visual é confirmada, o Studio DEVE gravar os arquivos alterados em disco antes de pedir hot reload. | F1 | T |
| FR-DOC-003 | Quando um arquivo do projeto é alterado em disco por outro processo, o Studio DEVE recarregá-lo e atualizar árvores, canvas e inspetor sem ação do usuário. | F1 | T |
| FR-DOC-004 | Se um arquivo for alterado em disco enquanto tem alteração não gravada no Studio, então o Studio DEVE preservar as duas versões e pedir a decisão do usuário. | F4 | T |
| FR-DOC-005 | O Studio DEVE oferecer desfazer e refazer para toda edição, visual ou textual. | F1 | T |
| FR-DOC-006 | Quando uma edição é desfeita, o Studio DEVE restaurar os bytes exatos anteriores a ela. | F1 | T |
| FR-DOC-007 | Uma edição visual DEVE alterar somente os bytes do trecho editado e os de formatação desse trecho. | F1 | T |
| FR-DOC-008 | Enquanto o arquivo de destino estiver formatado segundo `dart format`, o Studio DEVE entregá-lo formatado após a edição. | F3 | T |
| FR-DOC-009 | Enquanto o arquivo de destino não estiver formatado segundo `dart format`, o Studio NÃO DEVE reformatar texto fora do trecho editado. | F3 | T |
| FR-DOC-010 | O Studio DEVE manter histórico local das versões de cada arquivo que editar, em `.dart_tool/studio/history/`. | F3 | T |

#### Inspeção e seleção

| ID | Requisito | Inc. | Ver. |
| --- | --- | --- | --- |
| FR-INS-001 | Enquanto houver sessão de execução em modo debug, o Studio DEVE exibir a árvore de widgets em execução, com o local de criação de cada widget do projeto. | F1 | T |
| FR-INS-002 | O Studio DEVE exibir, para cada arquivo aberto, a árvore de widgets derivada do código-fonte, incluídos os ramos que não estão renderizados. | F1 | T |
| FR-INS-003 | Quando o usuário seleciona um widget no canvas, na árvore em execução, na árvore de fonte ou no editor de código, o Studio DEVE refletir a mesma seleção nas demais vistas. | F1 | T |
| FR-INS-004 | Quando a seleção recai em widget criado fora do projeto, o Studio DEVE selecionar o ancestral mais próximo criado no projeto e indicar que o fez. | F1 | T |
| FR-INS-005 | Quando o widget selecionado tem mais de uma instância com o mesmo local de criação, o Studio DEVE indicar que a edição afeta todas. | F2 | T |
| FR-INS-006 | Enquanto houver edição ainda não refletida no app em execução, o Studio DEVE manter a seleção pelo mapa de posições entre a versão em execução e a versão atual do arquivo. | F1 | T |
| FR-INS-007 | Se o rastreamento de criação de widgets não estiver disponível na sessão, então o Studio DEVE informar o fato e desabilitar a edição visual nessa sessão. | F1 | T |

#### Propriedades

| ID | Requisito | Inc. | Ver. |
| --- | --- | --- | --- |
| FR-PRP-001 | Quando um widget do projeto é selecionado, o Studio DEVE listar os parâmetros do seu construtor com nome, tipo, valor no código, valor padrão, documentação e indicação de argumento presente. | F1 | T |
| FR-PRP-002 | Onde a sessão de execução fornecer o valor efetivo de uma propriedade, o Studio DEVE exibi-lo ao lado da expressão do código. | F2 | T |
| FR-PRP-003 | Quando o usuário altera uma propriedade de tipo `bool`, `int`, `double`, `String` ou enum, o Studio DEVE alterar o argumento correspondente no código. | F1 | T |
| FR-PRP-004 | Quando o usuário altera parte de uma propriedade cujo valor é um objeto composto, o Studio DEVE reescrever a expressão do argumento preservando os subargumentos não alterados. | F3 | T |
| FR-PRP-005 | O Studio DEVE oferecer editores dedicados para `Color`, `EdgeInsets`, `BorderRadius`, `BoxDecoration`, `TextStyle`, `Alignment`, `Duration` e `IconData`. | F3 | D |
| FR-PRP-006 | Onde não houver editor dedicado para o tipo de uma propriedade, o Studio DEVE oferecer um formulário gerado a partir dos construtores públicos do tipo. | F3 | T |
| FR-PRP-007 | Quando o valor de um argumento não é literal, o Studio DEVE exibi-lo como expressão editável em texto e oferecer navegação ao código. | F1 | T |
| FR-PRP-008 | Quando o usuário restaura o valor padrão de uma propriedade opcional, o Studio DEVE remover o argumento do código. | F1 | T |
| FR-PRP-009 | Enquanto o usuário arrasta um controle contínuo de propriedade, o Studio DEVERIA aplicar o valor no app em execução sem alterar arquivo. | F5 | T |
| FR-PRP-010 | Quando o usuário solta um controle contínuo de propriedade, o Studio DEVE gravar uma única edição com o valor final. | F5 | T |
| FR-PRP-011 | O Studio DEVE exibir restrições, tamanho e dados de flex do widget selecionado e permitir alterar alinhamento, fator e ajuste de flex gravando no código. | F1 | T |

#### Estrutura

| ID | Requisito | Inc. | Ver. |
| --- | --- | --- | --- |
| FR-STR-001 | O Studio DEVE permitir envolver o widget selecionado com outro widget, removê-lo mantendo seus filhos, movê-lo para cima ou para baixo entre irmãos e trocá-lo com o pai ou com o filho. | F1 | T |
| FR-STR-002 | O Studio DEVE permitir inserir um widget em qualquer slot do widget selecionado: `child`, `children`, parâmetro nomeado de tipo widget ou retorno de builder. | F3 | T |
| FR-STR-003 | O Studio DEVE exibir os slots vazios do widget selecionado como destinos de inserção. | F3 | D |
| FR-STR-004 | O Studio DEVE permitir mover uma subárvore para outro slot, no mesmo arquivo ou em outro arquivo do projeto. | F3 | T |
| FR-STR-005 | O Studio DEVE permitir duplicar e excluir uma subárvore. | F3 | T |
| FR-STR-006 | Quando uma inserção ou movimentação usa símbolo não importado no arquivo de destino, o Studio DEVE acrescentar a diretiva `import` necessária. | F3 | T |
| FR-STR-007 | O Studio DEVE permitir extrair a subárvore selecionada para um widget novo e converter um `StatelessWidget` em `StatefulWidget`. | F1 | T |
| FR-STR-008 | Se uma edição estrutural aumentar o número de erros de análise do projeto, então o Studio DEVE descartá-la sem gravar em disco e informar o diagnóstico. | F3 | T |
| FR-STR-009 | Quando um gesto de redimensionar ou de posicionar admite mais de uma tradução em código, o Studio DEVE apresentar as alternativas e aplicar a escolhida. | F3 | D |

#### Paleta

| ID | Requisito | Inc. | Ver. |
| --- | --- | --- | --- |
| FR-PAL-001 | O Studio DEVE listar na paleta toda classe pública, concreta e subtipo de `Widget` exportada pelas bibliotecas públicas das dependências diretas do projeto e pelo próprio projeto. | F3 | T |
| FR-PAL-002 | O Studio NÃO DEVE exigir registro, anotação ou arquivo de configuração para que um widget apareça na paleta. | F3 | I |
| FR-PAL-003 | Quando um widget com parâmetros obrigatórios é inserido, o Studio DEVE preenchê-los com valores que compilem. | F3 | T |
| FR-PAL-004 | Quando as dependências do projeto mudam, o Studio DEVE atualizar a paleta. | F3 | T |

#### Canvas

| ID | Requisito | Inc. | Ver. |
| --- | --- | --- | --- |
| FR-CNV-001 | O Studio DEVE exibir no canvas quadros produzidos pela execução do código do projeto em um engine Flutter. | F2 | I |
| FR-CNV-002 | O Studio NÃO DEVE desenhar no canvas representação própria de widget do projeto. Contornos, alças e guias são sobreposições. | F2 | I |
| FR-CNV-003 | O Studio DEVE oferecer como superfície de design todo alvo anotado com `@Preview` e todo widget do projeto cujo construtor não tenha parâmetro obrigatório. | F2 | T |
| FR-CNV-004 | Enquanto o canvas está em modo design, o Studio NÃO DEVE entregar ao app eventos de ponteiro e de teclado e DEVE manter as animações pausadas. | F2 | T |
| FR-CNV-005 | Enquanto o canvas está em modo execução, o Studio DEVE entregar ao app os eventos de ponteiro, de teclado e de entrada de texto. | F2 | T |
| FR-CNV-006 | O Studio DEVE desenhar o contorno e as alças do widget selecionado com a geometria do mesmo quadro que está exibido. | F2 | T |
| FR-CNV-007 | O Studio DEVE permitir exibir a mesma superfície em mais de uma configuração de tamanho, densidade de pixels, brilho e plataforma simulada. | F2 | D |
| FR-CNV-008 | Se o código do projeto deixar de compilar, então o Studio DEVE manter o último quadro válido, marcá-lo como desatualizado e listar os erros. | F2 | T |
| FR-CNV-009 | Se o hot reload for rejeitado, então o Studio DEVE executar hot restart e informar que o estado do app foi reiniciado. | F2 | T |
| FR-CNV-010 | O Studio DEVE usar como imagem de arraste e como miniatura de paleta capturas do widget real. | F3 | I |

#### Host de design

| ID | Requisito | Inc. | Ver. |
| --- | --- | --- | --- |
| FR-HST-001 | Quando uma superfície de design é aberta, o Studio DEVE gerar o projeto host em `.dart_tool/studio/host/`, com dependência por caminho para o projeto do usuário. | F2 | T |
| FR-HST-002 | O Studio DEVE executar o host de design sem exigir toolchain nativo instalado na máquina. | F2 | T |
| FR-HST-003 | Se um canal de plataforma não tiver implementação no host, então o agente de design DEVE responder com resultado vazio e o Studio DEVE identificar o plugin afetado. | F2 | T |
| FR-HST-004 | Onde o host nativo próprio existir para a revisão de engine do projeto, o Studio DEVE usá-lo e receber os quadros por textura compartilhada. | F5 | T |
| FR-HST-005 | O Studio DEVE permitir usar como alvo de inspeção e de edição um app em execução em qualquer dispositivo aceito pelo `flutter run`. | F1 | D |

#### Código e eventos

| ID | Requisito | Inc. | Ver. |
| --- | --- | --- | --- |
| FR-COD-001 | O Studio DEVE oferecer editor de código com realce semântico, completar, diagnósticos, ir para definição, renomear, ações de código e formatação, obtidos do analysis server. | F4 | D |
| FR-COD-002 | Quando o usuário alterna do canvas para o código, o Studio DEVE posicionar o cursor no local de criação do widget selecionado. | F4 | T |
| FR-COD-003 | Quando o usuário alterna do código para o canvas, o Studio DEVE selecionar o widget cuja criação contém o cursor. | F4 | T |
| FR-COD-004 | O Studio DEVE exibir os diagnósticos do projeto em painel de mensagens, com navegação ao local de cada um. | F4 | D |
| FR-EVT-001 | Quando um widget é selecionado, o Studio DEVE listar como eventos os parâmetros do construtor cujo tipo é função. | F3 | T |
| FR-EVT-002 | Quando o usuário aciona um evento sem tratador, o Studio DEVE criar um método na classe que contém o widget, atribuí-lo ao argumento e abrir o editor no corpo do método. | F3 | T |
| FR-EVT-003 | Quando o usuário aciona um evento que já tem tratador, o Studio DEVE navegar até ele. | F3 | T |
| FR-EVT-004 | O Studio DEVE permitir criar, para um campo de texto, um `TextEditingController` com declaração, inicialização e descarte na classe `State`. | F4 | T |

#### Execução e depuração

| ID | Requisito | Inc. | Ver. |
| --- | --- | --- | --- |
| FR-RUN-001 | O Studio DEVE iniciar, encerrar, recarregar e reiniciar a execução do app do projeto no dispositivo escolhido, pelo adaptador de debug do Flutter. | F0 | T |
| FR-RUN-002 | O Studio DEVE oferecer pontos de parada, execução passo a passo, pilha de chamadas, inspeção de variáveis e avaliação de expressão. | F4 | D |
| FR-RUN-003 | O Studio DEVE exibir a saída e os erros de execução do app. | F0 | D |
| FR-RUN-004 | Quando o usuário pede a compilação, o Studio DEVE acionar `flutter build` para a plataforma escolhida e exibir o resultado. | F4 | D |

#### API

| ID | Requisito | Inc. | Ver. |
| --- | --- | --- | --- |
| FR-API-001 | O Studio DEVE expor como método do serviço `Studio`, no Dart Tooling Daemon, toda operação de leitura, seleção e edição disponível na interface gráfica. | F1 | I |
| FR-API-002 | A interface gráfica DEVE executar operações de edição exclusivamente pelos métodos do serviço `Studio`. | F1 | I |
| FR-API-003 | O serviço `Studio` DEVE publicar a descrição OpenRPC de seus métodos pelo método `rpc.discover`. | F3 | T |
| FR-API-004 | Quando a seleção, um documento ou o quadro exibido muda, o Studio DEVE publicar o evento correspondente no fluxo `Studio`. | F2 | T |
| FR-API-005 | Onde um servidor MCP estiver habilitado, o Studio DEVERIA expor as operações do serviço `Studio` como ferramentas. | F6 | D |

### 3.2 Desempenho

As medidas valem na máquina e nos projetos de referência definidos no plano de verificação. São metas a confirmar no incremento F0 (ASM-08).

| ID | Requisito | Inc. | Ver. |
| --- | --- | --- | --- |
| NFR-PERF-001 | Quando o usuário clica no canvas, o Studio DEVE exibir a seleção em até 16 ms no percentil 95. | F2 | T |
| NFR-PERF-002 | Quando uma edição de propriedade é confirmada, o Studio DEVE exibir o quadro atualizado em até 250 ms na mediana e 500 ms no percentil 95, no projeto de referência pequeno. | F2 | T |
| NFR-PERF-003 | Enquanto o usuário arrasta no canvas, o Studio DEVE atualizar as sobreposições a pelo menos 60 quadros por segundo. | F2 | T |
| NFR-PERF-004 | Quando uma edição estrutural é submetida, o Studio DEVE concluir a validação em até 300 ms no percentil 95, no projeto de referência pequeno. | F3 | T |
| NFR-PERF-005 | O transporte de quadros DEVE acrescentar no máximo 33 ms de latência no host sem toolchain e 16 ms no host nativo próprio, no percentil 95. | F2, F5 | T |

### 3.3 Usabilidade

| ID | Requisito | Inc. | Ver. |
| --- | --- | --- | --- |
| NFR-INTR-001 | O Studio DEVE oferecer os textos da sua interface própria em português do Brasil e em inglês. | F4 | I |
| NFR-INTR-002 | O Studio DEVE oferecer um esquema de teclas em que F9 executa, Ctrl+F9 compila, F11 foca o inspetor de objetos e F12 alterna entre formulário e código. | F4 | D |
| NFR-INTR-003 | O Studio DEVE exibir, para os conceitos da tabela de correspondência do glossário, o termo Delphi ao lado do termo Flutter, com opção de ocultá-lo. | F4 | I |
| NFR-INTR-004 | Toda operação de edição DEVE ser acionável pelo teclado. | F4 | I |
| NFR-INTR-005 | Quando uma edição é rejeitada, o Studio DEVE informar o arquivo, a linha e o diagnóstico que a rejeitou. | F3 | T |
| NFR-INTR-006 | Um programador com experiência em Delphi e sem experiência em Flutter DEVERIA concluir, em até 15 minutos e sem documentação externa, um formulário com três campos de texto e um botão com tratador. | F4 | D |

### 3.4 Interfaces

Os contratos estão na especificação de interfaces. Aqui fica apenas a obrigação.

| ID | Requisito | Inc. | Ver. |
| --- | --- | --- | --- |
| IR-001 | O Studio DEVE atuar como cliente do analysis server pelo Language Server Protocol, sobre a entrada e a saída padrão do processo. | F0 | T |
| IR-002 | O Studio DEVE atuar como cliente do adaptador de debug do Flutter pelo Debug Adapter Protocol. | F0 | T |
| IR-003 | O Studio DEVE registrar no Dart Tooling Daemon os serviços `Editor` e `Studio`. | F0, F1 | T |
| IR-004 | O Studio DEVE obter a árvore em execução e os locais de criação pelas extensões de serviço do inspector do framework. | F1 | T |
| IR-005 | O Studio DEVE ler e gravar arquivos somente sob as raízes do projeto, os diretórios de dados do Studio e o diretório temporário do sistema. | F0 | T |
| IR-006 | O Studio NÃO DEVE abrir conexão de rede própria, exceto para baixar binário de engine (FR-HST-004). | F0 | I |
| IR-007 | A interface gráfica DEVE ocupar uma única janela, com painéis encaixáveis de canvas, estrutura, inspetor de objetos, paleta, código e mensagens. | F2 | D |

### 3.5 Dados

O Studio não tem banco de dados. Os dados persistentes são os arquivos do projeto e os diretórios abaixo.

| ID | Requisito | Inc. | Ver. |
| --- | --- | --- | --- |
| NFR-DATA-001 | O Studio NÃO DEVE persistir estado de projeto fora dos arquivos do projeto e de `.dart_tool/studio/`. | F0 | I |
| NFR-DATA-002 | Quando `.dart_tool/studio/` é apagado, o Studio DEVE reconstruí-lo, com perda apenas do histórico local e de caches. | F2 | T |
| NFR-DATA-003 | O Studio DEVE guardar as preferências do usuário no diretório de configuração do usuário no sistema operacional. | F0 | I |
| NFR-DATA-004 | O Studio DEVE indexar o catálogo da paleta por nome e versão de pacote, no diretório de cache do usuário. | F3 | T |

### 3.6 Restrições de projeto

| ID | Restrição |
| --- | --- |
| DC-01 | O código Dart e YAML do projeto é a única representação persistente da interface. Não há formato intermediário. |
| DC-02 | O projeto do usuário não recebe dependência, anotação nem arquivo do Studio. A anotação `@Preview` é do SDK. |
| DC-03 | A interface e o shell são implementados em Flutter. Código nativo só onde o Flutter não alcança: host de design e textura. |
| DC-04 | A base é um fork de `flutter/devtools`, mantido como fila de patches registrada em `PATCHES.md`. |
| DC-05 | Todo componente que analisa ou executa o código do projeto roda com o SDK do projeto. |
| DC-06 | Identificadores são em inglês. Textos de interface são localizados. |
| DC-07 | O código herdado mantém a licença BSD de três cláusulas e seus avisos. |
| DC-08 | Windows x64 é a plataforma primária. macOS e Linux são secundárias. |

### 3.7 Atributos do sistema

Agrupados pelas características da ISO/IEC 25010:2023.

| ID | Requisito | Inc. | Ver. |
| --- | --- | --- | --- |
| NFR-REL-001 | Se o processo do app alvo terminar inesperadamente, então o Studio DEVE permanecer operante, preservar os documentos e oferecer o reinício do alvo. | F1 | T |
| NFR-REL-002 | Se o analysis server ou o Dart Tooling Daemon terminar, então o Studio DEVE reiniciá-lo e restabelecer registros e documentos abertos. | F0 | T |
| NFR-REL-003 | O Studio DEVE gravar arquivos de forma atômica, de modo que nenhuma falha deixe arquivo do projeto parcialmente escrito. | F0 | T |
| NFR-REL-004 | Quando todas as edições de uma sessão são desfeitas, os arquivos do projeto DEVEM ficar idênticos, byte a byte, ao estado inicial. | F1 | T |
| NFR-SEC-001 | Quando um projeto é aberto pela primeira vez, o Studio DEVE pedir confirmação antes de executar código dele. | F2 | D |
| NFR-SEC-002 | O serviço `Studio` DEVE ser alcançável somente pelo endereço local do Dart Tooling Daemon da sessão, que inclui o segredo gerado por ele. | F1 | T |
| NFR-SEC-003 | Se o alvo de uma operação estiver fora das raízes do projeto, então o serviço `Studio` DEVE recusá-la. | F1 | T |
| NFR-SEC-004 | Quando o Studio baixa um binário de engine, DEVE verificar seu hash SHA-256 contra o manifesto distribuído com o Studio antes de carregá-lo. | F5 | T |
| NFR-SEC-005 | O Studio NÃO DEVE enviar telemetria. | F0 | I |
| NFR-MNT-001 | Todo patch sobre código herdado do DevTools DEVE estar registrado em `PATCHES.md`, com motivo e situação no upstream. | F0 | I |
| NFR-MNT-002 | O fork DEVE ser rebaseado sobre o upstream em intervalo não superior a 7 dias. | F0 | I |
| NFR-MNT-003 | O pacote `studio_source_engine` NÃO DEVE depender do Flutter. | F3 | I |
| NFR-MNT-004 | Os testes herdados do DevTools DEVEM continuar passando, exceto os de funcionalidade removida, listados em `PATCHES.md`. | F0 | T |
| NFR-MNT-005 | O código próprio DEVE cumprir o Padrão de código, e o comando `st verify` DEVE reprovar toda mudança que o viole. | F0 | T |
| NFR-MNT-006 | Os tipos do serviço `Studio` e dos layouts binários DEVEM ser gerados de uma única fonte, para Dart e para Rust. | F1, F5 | T |
| NFR-MNT-007 | A referência de API DEVE ser gerada do código e do documento OpenRPC a cada versão, sem avisos do gerador. | F1 | T |
| NFR-MNT-008 | Toda exceção ao Padrão de código DEVE constar do registro de dispensas, com justificativa, aprovação e validade. | F0 | I |
| NFR-FLEX-001 | O Studio DEVE operar com as quatro versões estáveis mais recentes do Flutter. | F0 | T |
| NFR-FLEX-002 | O Studio DEVE executar em Windows x64, macOS arm64 e x64, e Linux x64. | F0, F4 | T |
| NFR-COMP-001 | O Studio NÃO DEVE manter trava sobre arquivo do projeto. | F0 | T |
| NFR-COMP-002 | O Studio NÃO DEVE alterar a configuração global do SDK Flutter do usuário. | F0 | T |

## 4. Verificação

Todo requisito das seções 3.1 a 3.7 traz seu método de verificação. O procedimento, os oráculos e os critérios de aprovação estão no plano de verificação, que mantém a matriz de rastreabilidade.

## 5. Apêndices

### A. Premissas e dependências

Cada premissa é confirmada por experimento no incremento F0 e tem consequência definida se for falsa.

| ID | Premissa | Se for falsa |
| --- | --- | --- |
| ASM-01 | O binário `flutter_tester` do SDK serve de dispositivo interativo para o host de design e renderiza as fontes do projeto. | O host sem toolchain passa a ser um dispositivo desktop, que exige toolchain nativo. FR-HST-002 fica adiado para F5. |
| ASM-02 | `dart/textDocument/editableArguments` responde apenas em construtores de widget. | Se responder em outros construtores, parte de FR-PRP-004 deixa de exigir o motor próprio. |
| ASM-03 | O Flutter Outline informa a que parâmetro do pai cada filho pertence. | Os slots passam a ser calculados pelo motor de edição. |
| ASM-04 | O pacote de embedder publicado para macOS inclui arm64. | Compilar o engine para arm64 ou executar o host x64 por tradução. |
| ASM-05 | O recurso de custom devices pode ser habilitado sem alterar a configuração global do SDK. | O host próprio usa um pipeline de reload do Studio: compilador residente mais VM Service. |
| ASM-06 | `devtools_app` compila e executa em Windows desktop com ajustes localizados. | Custo adicional em F0 para completar as implementações de desktop. |
| ASM-07 | Existe pacote Flutter de editor de código adequado a FR-COD-001. | Motor de editor próprio em F4. |
| ASM-08 | As metas da seção 3.2 são atingíveis com o hot reload padrão do SDK. | Pipeline de reload próprio, ou revisão das metas registrada em ADR. |

Dependências externas: SDK Flutter; métodos `editableArguments` e `editArgument` do analysis server; Dart Tooling Daemon; adaptador de debug; extensões de serviço do inspector; anotação `@Preview`.

### B. Alocação por incremento

A coluna Inc. de cada requisito prevalece. Esta tabela resume, por entrega, os requisitos funcionais e os de desempenho.

| Incremento | Entrega | Requisitos |
| --- | --- | --- |
| F0 Fundação | Fork limpo, build desktop, shell com daemon, analysis server e adaptador de debug, `DocumentStore` | FR-PRJ-001 a 004, FR-DOC-001, FR-RUN-001 e 003, IR-001 a 003, NFR-REL-002 e 003, NFR-MNT-005 e 008 |
| F1 Inspetor que escreve | Seleção ligada ao código, propriedades simples, assists, API | FR-DOC-002, 003 e 005 a 007, FR-INS, FR-PRP-001, 003, 007, 008 e 011, FR-STR-001 e 007, FR-HST-005, FR-API-001 e 002, NFR-MNT-006 e 007 |
| F2 Canvas | Host de design, quadros, espelho de cena, modos, superfícies | FR-CNV-001 a 009, FR-HST-001 a 003, FR-PRP-002, FR-API-004, NFR-PERF-001 a 003 e 005 |
| F3 Motor estrutural | Edição estrutural, objetos compostos, paleta, eventos, transação, histórico | FR-STR-002 a 006, 008 e 009, FR-PAL, FR-PRP-004 a 006, FR-EVT-001 a 003, FR-DOC-008 a 010, FR-API-003, NFR-PERF-004 |
| F4 Ambiente completo | Editor de código, depuração, assistentes, localização, teclas | FR-COD, FR-RUN-002 e 004, FR-PRJ-005 a 007, FR-EVT-004, FR-DOC-004, NFR-INTR |
| F5 Host próprio | Embedder nativo, textura compartilhada, ajuste ao vivo | FR-HST-004, FR-PRP-009 e 010, NFR-SEC-004, NFR-PERF-005 |
| F6 Alcance | Build web, painel dentro de outro editor, MCP | FR-API-005 |
