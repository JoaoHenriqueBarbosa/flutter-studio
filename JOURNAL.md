# Diário

Registro informal do andamento, para quem aprova: o que foi feito e por quê, o que ficou decidido e o que está pendente. O detalhe técnico fica em `CHANGELOG.md`. A entrada mais recente fica no topo.

## 11/11/2026

**Extrair widget, converter para StatefulWidget e a árvore do app na API.** A barra de estrutura ganhou "Extrair para um widget novo": pede o nome da classe e move o widget selecionado, com tudo o que há dentro, para uma classe nova no mesmo arquivo; o que ele usava de fora vira parâmetro. Converter um `StatelessWidget` em `StatefulWidget` existe na API e ainda não tem botão, porque a interface ainda não tem onde selecionar uma classe. A API também passou a devolver a árvore do app em execução, com o local de criação de cada widget do projeto.

Com isso, dos requisitos até o F1 que pedem teste, ficam sem teste só quatro: o painel de layout e flex (FR-PRP-011), os testes herdados (NFR-MNT-004, que passam mas rodam fora do portão), a referência de API gerada (NFR-MNT-007) e nada mais do lado funcional.

**O canvas avisa quando não dá para ligar o que se vê ao código.** Se o app for compilado sem o rastreamento de criação de widgets, o agente informa, o canvas mostra um aviso e deixa de selecionar por clique nessa execução (FR-INS-007). Nas execuções normais em modo debug o rastreamento vem ligado, e nada muda.

**Dois erros meus, achados e corrigidos.** O patch 4 no código herdado quebrava a compilação de dois testes do DevTools: eu tinha rodado só os 61 testes vizinhos da mudança, e não a suíte inteira. Corrigido, e a suíte herdada inteira passa de novo (1683 testes). E um commit levou junto cinco arquivos temporários que a suíte herdada cria enquanto roda; saíram no commit seguinte, mas continuam no histórico do commit `78522f971`. Passei a rodar a suíte herdada inteira depois de todo patch e a não commitar enquanto ela roda.

**A API já remove argumento e aceita expressão; a interface ainda não.** Pelo serviço `Studio`, `setProperty` agora tira um argumento do código (o widget volta ao valor padrão) e troca o valor de um argumento por qualquer expressão, não só por um literal. Um agente conectado ao daemon já consegue usar. Na interface não há como pedir isso ainda: o painel de propriedades é o do DevTools, que só edita literais; vem com o painel próprio do Studio.

Essas duas edições mexem no texto direto, sem a conferência pelo analisador que o projeto prevê para edições estruturais. Uma expressão digitada errada é gravada como veio; desfazer resolve. Está na dívida técnica, até o motor de edição existir.

**As imagens do projeto aparecem no canvas. Há uma decisão esperando aprovação.** O conserto anunciado na entrada abaixo está feito: no canvas, o app acha as imagens e as fontes declaradas no `pubspec.yaml` do projeto. Um teste roda um app com uma imagem do projeto e outra que não existe, e confere que só a segunda falha.

Para não manter duas cópias do mesmo mecanismo (o shell já fazia isso para as imagens do DevTools), criei um pacote pequeno, `studio_package_assets`, usado pelos dois lados. Isso acrescenta um pacote e duas ligações ao desenho que o padrão de código fixa, o que pela regra só vale com decisão registrada. Escrevi a ADR-0016 como proposta, e o código já segue o que ela diz, como aconteceu com a ADR-0015.

Depende do dono do produto: aprovar ou recusar a ADR-0016. Se for recusada, o caminho de volta é devolver as classes ao shell e copiar o mecanismo no agente.

**Clicar no canvas seleciona o widget.** Com o app rodando no canvas, um clique sobre um texto, um botão ou qualquer widget escrito no projeto seleciona esse widget: ele ganha um contorno no canvas, fica marcado na Estrutura, e as Propriedades e a barra de estrutura passam a valer para ele. A partir daí o ciclo completo acontece numa janela só: clicar no que se vê, mudar no painel, ver mudar.

Para isso entraram duas peças previstas no projeto: o agente de design, um trecho de código do Studio que roda dentro do app e informa onde está cada widget do projeto na tela; e o projeto host, gerado em `.dart_tool/studio/host/` do projeto aberto, que liga o agente ao app sem acrescentar nada ao `pubspec.yaml` nem aos fontes do usuário. Um teste com o SDK real confere que as posições informadas pelo agente são as mesmas da árvore de fonte.

Limites que valem saber antes de usar em projeto de verdade:

- Imagens e fontes declaradas no `pubspec.yaml` do projeto ainda não aparecem no canvas. O app de exemplo não tem nenhuma; um app real quase sempre tem. É o próximo conserto, e está na dívida técnica.
- O app no canvas não recebe mouse nem teclado: clicar seleciona, não aciona o botão. Para usar o app, "Executar em janela".
- Widgets que vêm de pacotes não são selecionáveis no canvas; o clique cai no widget do projeto que os contém.

**O app agora aparece dentro do Studio.** Run passou a executar o projeto no host de design do SDK, sem abrir outra janela e sem compilar nada nativo: o app sobe em poucos segundos e a imagem dele aparece na aba Canvas, no centro da bancada. Trocar uma propriedade ou envolver um widget atualiza o canvas logo depois do reload (cerca de um quarto de segundo no exemplo). Parar o app deixa o último quadro, esmaecido e com aviso. Quem quiser a janela de verdade tem um segundo botão, "Executar em janela".

É o primeiro degrau do canvas, e convém não confundir com o canvas do F2:

- Só exibe. Não dá para clicar num widget no canvas para selecioná-lo, não há contorno da seleção e o app não recebe mouse nem teclado ali. A seleção continua pela Estrutura ou pelo Inspetor.
- Mostra o app inteiro a partir do `main`, não uma tela isolada.
- A imagem vem de uma chamada interna do engine, em PNG, duas vezes por segundo. O transporte previsto, pelo agente de design, é outro.

Um defeito apareceu só na interface e vale o registro: com o canvas pedindo quadros o tempo todo, o primeiro hot reload travava o app do host para sempre. Um teste passou a repetir o caso (oito edições seguidas com captura quase contínua) e a captura agora espera o reload terminar.

**Duas premissas testadas; a do host de design veio boa.** O binário de teste do SDK (`flutter_tester`) roda o app de exemplo inteiro, sem compilar nada nativo e em poucos segundos, com hot reload, e entrega a imagem da tela com o texto e os ícones certos. Era o maior risco do canvas (ASM-01, RSK-03). Ainda falta conferir fonte própria do projeto, entrada de mouse e teclado e os outros sistemas, então a premissa fica como parcialmente confirmada. A outra (ASM-02) confirmou o que o plano supunha: o analysis server só edita argumentos de construtores de widget, e objetos compostos como `ThemeData` e `TextStyle` dependem do motor próprio.

**Dá para editar sem executar o app.** O Studio ganhou o painel Estrutura, à esquerda: a árvore de widgets tirada do código do arquivo, que existe com o app parado e mostra também o que não está na tela. Clicar num widget ali carrega as propriedades dele e acende a barra de estrutura; as edições gravam no arquivo e a árvore se refaz. Conferi em display virtual, sem iniciar o app: selecionar o `Column`, envolver com `SizedBox`, ver a árvore mudar, desfazer.

A posição de cada widget na árvore de fonte é a mesma que o framework registra quando o app roda, o que é a base da ligação entre as duas árvores (ADR-0005); um teste com o SDK real confere isso para o `Column` do exemplo.

Duas coisas que ficaram a meio caminho:

- A seleção vai do inspetor do app para a Estrutura, mas não volta: selecionar na Estrutura não move a seleção no inspetor herdado. Está na dívida técnica.
- A premissa ASM-03 se mostrou falsa: o analysis server não diz a que parâmetro do pai cada filho pertence (`child`, `body`, `appBar`). A árvore mostra os filhos sem o nome do slot. Como o SRS previa, os slots ficam para o motor de edição, no F3.

**Dá para mexer na estrutura sem abrir o código.** Com um widget selecionado, o painel Propriedades ganhou uma barra: "Envolver com" (Center, Container, Padding, SizedBox, Column, Row e os builders; Expanded e Flexible quando o pai é uma linha ou coluna), mover para cima e para baixo entre os irmãos, trocar com o pai ou com o filho, e remover o widget mantendo os filhos. Cada botão só acende quando a operação vale para o widget selecionado. Tudo passa pelo serviço `Studio`, entra no desfazer e recarrega o app. Isso cobre a primeira metade do critério de saída do F1 ("alterar uma propriedade e envolver um widget sem abrir o código"); falta fazê-lo em dispositivo físico.

Quem faz a edição é o analysis server, com as mesmas ações que os outros editores oferecem. A lista de widgets para envolver é a que ele conhece; envolver com um widget qualquer depende do motor de edição, do F3.

Conferido por teste de sistema (envolver o `Column` com `Center` e desfazer, arquivo idêntico ao original) e na interface, em display virtual: envolver com `Padding`, desfazer, mover um `Text` para baixo, desfazer.

Decisões que tomei e que vale conferir:

- O contrato ganhou três operações que a especificação de interfaces não previa: `getStructureOptions` (o que o widget aceita), `reorderWidget` e `swapWidget`. Sem a primeira a interface não saberia que botões acender; as outras duas são pedidas por FR-STR-001. O contrato está na versão 0.2.0.
- A interface chama o serviço dentro do próprio processo, pelo mesmo objeto que atende o daemon, e não por uma volta pelo daemon. As regras conferidas são as mesmas.

**O Studio convive com outro editor aberto no mesmo projeto.** Quando outro programa salva um arquivo Dart do projeto, o Studio relê o arquivo, avisa o analysis server e recarrega o app, sem ninguém pedir (FR-DOC-003). Uma edição do Studio calculada sobre o texto antigo é recusada, em vez de apagar o que o outro programa gravou. O preço: depois de uma alteração feita por fora, as edições anteriores do Studio não podem mais ser desfeitas pelo Studio, porque o texto sobre o qual foram feitas não existe mais. Conferido em Linux, por teste com o SDK real.

**O Studio agora edita pela própria API, e tem desfazer.** O desvio temporário de FR-API-002, aprovado para o primeiro entregável, está encerrado: quando se troca um valor no painel Propriedades, o painel chama o serviço `Studio`, e é o serviço que confere a versão do documento, pede a edição ao analysis server, grava e manda recarregar. A mesma porta fica aberta a qualquer programa que se conecte ao daemon da sessão, que é por onde um agente vai editar.

O que entrou, em cinco commits:

- Desfazer e refazer. Há dois botões na barra, ao lado de Run. Desfazer devolve o arquivo byte a byte ao que era; um teste aplica cem edições sorteadas, desfaz todas e compara.
- O contrato do serviço, escrito em OpenRPC, com sete operações: versão, seleção (ler e mudar), propriedades (ler e alterar), desfazer e refazer. Os tipos Dart saem desse arquivo por `st generate`, e o portão ganhou o passo QG-09, que reprova código gerado desatualizado. Três dos treze passos do portão rodam agora.
- O Studio passou a manter no analysis server os documentos que edita, com número de versão. Um pedido feito sobre uma versão antiga é recusado em vez de editar no lugar errado.

Como foi conferido: um teste de sistema faz um cliente externo ler as propriedades do `Column`, trocar o alinhamento, tentar de novo com a versão antiga (recusado) e desfazer, com o SDK real. Na interface, repeti o fluxo num display virtual, sem usar a tela desta máquina: editar, desfazer, refazer e desfazer, com o diff do projeto vazio no fim e o app recarregando a cada passo.

O que mudou para pior, de propósito: os botões "Wrap with…" do painel de propriedades sumiram. Eles editavam por fora do serviço. Voltam quando o serviço tiver a operação de envolver widget (FR-STR-001), que é o próximo passo.

O que continua faltando no F1: envolver e remover widget, árvore de fonte, recarga de arquivo alterado por fora, remover argumento (voltar ao valor padrão) e expressão não literal como texto editável.

**Primeiro entregável concluído: a primeira edição visual.** No Studio, em Linux: abre-se um projeto Flutter, clica-se em Run, o app sobe e a árvore de widgets aparece; seleciona-se o `Column` na árvore e o painel Propriedades lista os parâmetros do construtor; troca-se `mainAxisAlignment` de `.center` para `.end` na lista do painel. O arquivo `lib/main.dart` do projeto muda só nesse argumento, o app recarrega em cerca de um quarto de segundo e o texto desce para o pé da janela. Nenhuma linha de código foi aberta. Os seis marcos do caminho estão feitos.

Como foi conferido: o fluxo foi executado duas vezes na interface, com captura das janelas antes e depois e o diff do arquivo; e dois testes de sistema fazem o mesmo sem interface, com o SDK real, um comparando o arquivo byte a byte e o outro esperando o hot reload do app em execução.

O que o entregável não é:

- Só roda em Linux, e só foi conferido nesta máquina.
- Não tem desfazer. Uma edição errada se corrige editando de novo, ou pelo Git do projeto.
- O painel de propriedades e a árvore são os do DevTools, em inglês. A casca do Studio em volta (barra, títulos, mensagens) está em português e inglês, conforme o idioma do sistema.
- O desvio de FR-API-002 está em vigor: a edição não passa pelo serviço `Studio`, que ainda não existe.

Achados que ficam registrados como dívida na arquitetura (seção 11):

- O analysis server lê os arquivos do disco; o Studio ainda não mantém os documentos abertos nele.
- O daemon de ferramentas do Dart não morre com o pai. O Studio o encerra ao fechar a janela e ao receber sinal de término; se o Studio for morto à força, o daemon fica rodando.

Ruídos do código herdado vistos no log, sem efeito no fluxo: um aviso de "Concurrent modification" a cada seleção no inspetor; um erro "Future already completed" a cada hot reload; e uma asserção de `AppLifecycleListener` ao fechar a janela, só em modo debug. Nenhum vem de código do Studio. Vale investigar antes de propor os patches ao upstream.

O código herdado ganhou o patch 3, que só exporta o painel de propriedades.

Próximos passos naturais, dentro do F1: o serviço `Studio` com o contrato OpenRPC, encerrando o desvio; desfazer e refazer; a árvore de fonte.

**Definido o primeiro entregável: a primeira edição visual.** Num projeto Flutter de exemplo rodando em Linux, seleciona-se um widget no inspetor, muda-se um valor no painel de propriedades, o Studio grava só aquele argumento no arquivo e o app recarregado mostra a mudança, sem abrir o código. O dono do produto aprovou o caminho abaixo, que corta na vertical o F0 e o mínimo do F1 (FR-PRP-001, FR-PRP-003, FR-DOC-002 e parte de FR-INS-003). O trabalho começa quando ele der o sinal.

| # | Marco | O que entra | Como se confere |
| --- | --- | --- | --- |
| 0 | Shell abre em Linux | Feito (como os marcos 1 a 6, ver a entrada acima) | Janela do `studio_shell` com o DevTools herdado |
| 1 | Abrir projeto | Escolher o diretório, localizar o SDK e checar a janela de versões (FR-PRJ-001 a 003) | O shell mostra o projeto e a versão do SDK; nada muda no diretório fora de `.dart_tool/` |
| 2 | Ferramentas do SDK no ar | Supervisor de processos; daemon; analysis server como cliente LSP; pareamento dos dois (FR-PRJ-004, IR-001) | Os diagnósticos do projeto chegam ao shell; o analysis server volta depois de morto |
| 3 | `DocumentStore` | Documentos abertos no servidor, aplicação de `WorkspaceEdit`, gravação atômica (FR-DOC-001, NFR-REL-003) | Um `editArgument` disparado por teste muda no disco só os bytes do argumento |
| 4 | App rodando e inspetor ligado | Cliente DAP: iniciar, recarregar, encerrar, saída do app (FR-RUN-001 e 003); inspetor herdado conectado à sessão (FR-INS-001) | O app de exemplo abre pelo Studio e a árvore dele aparece no inspetor |
| 5 | Seleção alimenta as propriedades | Serviço `Editor` no daemon; seleção do inspetor vira posição ativa; painel de propriedades herdado dentro do shell (FR-PRP-001) | Selecionar um widget lista os parâmetros do construtor dele |
| 6 | A edição | Valor alterado no painel, `editArgument`, gravação pelo `DocumentStore`, hot reload (FR-PRP-003, FR-DOC-002) | Demonstração ao vivo e um teste de sistema que faz o mesmo sem interface e compara o diff |

O marco 5 é o de maior incerteza: o painel de propriedades herdado já fala com o serviço `Editor` e com o analysis server pelo daemon, mas foi feito para rodar embutido num IDE.

Fica de fora até o entregável: desfazer e refazer, árvore de fonte, recarga de arquivo alterado por fora e "envolver widget" (o restante do F1); Windows e macOS, de modo que o F0 não fecha com este entregável; os experimentos das premissas que o caminho não responde de passagem; e o portão completo, que segue reprovando enquanto a licença do DCM estiver pendente.

Desvio aprovado, temporário: no marco 6 o painel herdado chama o analysis server direto pelo daemon, sem passar pelo serviço `Studio`, o que a FR-API-002 proíbe. O requisito não mudou. O serviço `Studio` entra na frente logo depois do entregável, ainda dentro do F1; fazer na ordem da regra exigiria gerar o contrato OpenRPC antes da primeira edição.

**O portão de qualidade começou a existir.** O comando `st verify` roda e já confere formato e análise do código Dart do Studio; os dois passos de Rust saem como "não se aplica", porque ainda não há código Rust. Os outros nove passos aparecem como "não executado" e reprovam o portão, de propósito: o portão só aprova quando os treze passos rodarem, então hoje ele reprova toda mudança. Isso é o estado real, não um defeito.

Falta para o portão aprovar: instalar e fixar as versões do cspell e do PMD; decidir a licença do DCM, que segue pendente e trava os passos QG-03 e parte do QG-06; e escrever os passos próprios (estrutura, geração, marcadores, documentação, rastreabilidade e dispensas).

**ADR-0015 aceita.** O dono do produto aprovou o mecanismo de assets do shell. Não há mais decisão em estado de proposta.

**ADR-0003 a ADR-0013 estão aceitas.** O dono do produto informou que aprovou todas ao publicar a baseline em `docs/`, e que só faltou trocar o estado. Trocado. A ADR-0015, escrita depois, continua como proposta.

**Decidido: o produto é construído com o Flutter estável.** O dono do produto aceitou a alternativa levantada mais abaixo, e ela virou a ADR-0014. Os pacotes do Studio ficam em `studio/`, com dependências resolvidas pelo estável 3.47.9, e o código herdado continua sendo testado com a pré-versão que o upstream usa. O preço é ter dois SDKs no repositório e conferir, a cada rebase, se o código herdado ainda compila com o estável.

**O shell do Studio existe e abre em Linux.** O pacote `studio_shell` é um app próprio que sobe o DevTools herdado por dentro. Nesta máquina a janela abre inteira, com ícones e fontes iguais aos do DevTools rodando sozinho. Por enquanto ele não faz nada além disso: é a casca onde o resto do F0 entra. Para funcionar foi preciso um patch pequeno no código herdado (o patch 2 do `PATCHES.md`) e um mecanismo no shell que acha as imagens e as fontes do DevTools.

Depende do dono do produto:

- A ADR-0015, que descreve esse mecanismo, está como proposta. Ela também põe o padrão Decorator no catálogo do padrão de código, o que pela regra só vale com ADR aceita. O código já está escrito segundo ela.
- O identificador do aplicativo em Linux ficou `dev.flutterstudio.studio_shell`, provisório como o nome "Studio".
- Os arquivos novos estão sem cabeçalho de licença, porque o texto depende da licença do produto, ainda pendente (padrão de código, seção 9.5).

Ainda não verificado: das ferramentas do portão, só o formatador e o analisador do Dart rodaram sobre o código novo. DCM, cspell e PMD não estão instalados, e o `st verify` ainda não existe.

**O repositório virou o fork do DevTools.** Começou o incremento F0. O código do DevTools (commit `9b8d6457`, de 10/11/2026) entrou por baixo dos nossos commits, como a ADR-0002 descreve, por decisão do dono do produto entre três formas possíveis. Para isso o histórico do `main` foi reescrito uma vez e enviado com force push; o conteúdo dos documentos não mudou. Isso vai se repetir a cada rebase semanal. O `PATCHES.md` registra o commit base e a fila de patches, que tem um item: o nosso `CLAUDE.md` no lugar do deles.

**GitHub Actions desligado no repositório.** O upstream traz workflows próprios, e quatro deles rodam por agenda, um sem checar em que repositório está. Para não gastarem minutos nem mexerem em issues, o Actions foi desligado nas configurações do repositório. Volta a ser ligado quando o Studio tiver o próprio CI chamando `st verify`.

**Testes herdados passam em Linux.** Com o SDK que o upstream fixa (Flutter 3.50.0-1.0.pre-437, baixado pelo `dt` em `tool/flutter-sdk/`, fora do Git), passaram todos os testes de VM: 1683 no `devtools_app` (8 pulados pelo próprio upstream), 122 no `devtools_app_shared`, 114 no `devtools_shared`, 16 no `devtools_extensions` e 35 na ferramenta `dt`. Não rodaram os testes de navegador nem os de integração.

**O DevTools abre em Linux, mas não com o SDK do upstream nesta máquina.** O `devtools_app` compila e executa em Linux com um runner gerado, sem tocar em código herdado. Com o SDK candidato, porém, a janela sai deslocada: só um quarto do conteúdo aparece, e o resto fica preto. O mesmo acontece com um app Flutter em branco, então o defeito é do engine dessa pré-versão com o driver da NVIDIA (flutter/flutter#195885, aberto, sem contorno). Com o Flutter estável 3.47.9 o mesmo código compila e desenha certo. Ficou registrado como RSK-11.

**Achado para o shell.** O `devtools_app` carrega imagens e fontes por caminhos que só valem quando ele é o app principal. Dentro do `studio_shell` ele compila, mas cai na partida ao procurar `assets/dart_syntax.json`. São 12 pontos de carga de imagem e três famílias de fonte. O plano é o shell redirecionar esses caminhos na partida, com no máximo um patch no código herdado.

Levantado para o dono do produto, e decidido no mesmo dia (entrada acima): com que SDK o produto é construído. A ADR-0002 aceitava que a versão do Studio ficasse atrelada à do DevTools, que usa uma pré-versão trocada quase toda semana.

Pendente do F0, em ordem: o `st verify` e os demais pacotes `studio_*`; shell com daemon, analysis server e adaptador de debug; `DocumentStore`; experimentos das premissas ASM-01 a ASM-08.

**Repositório criado e baseline publicada.** O repositório privado `flutter-studio` existe no GitHub e já tem a baseline de projeto: os seis documentos e o guia. Ainda não há código; tudo é especificação.

**Documentos nas pastas definitivas.** Os documentos estavam todos soltos em `docs/` e o guia apontava para subpastas. Agora estão onde o guia diz. As decisões, que eram um arquivo só, viraram treze arquivos, um por ADR, com um índice. Os nomes dos arquivos das decisões foram traduzidos para o inglês, seguindo a regra de caminhos em inglês; vale uma conferida nesses nomes.

**Sessões já começam com o guia e o padrão de código.** O `CLAUDE.md` carrega os dois em toda sessão, e os outros documentos são abertos conforme a tarefa. O custo é cerca de 600 linhas de contexto por sessão.

**A documentação passou a ser mantida junto com o trabalho.** Quem mexer no repositório atualiza o documento afetado, sobe a versão dele, registra na tabela de mudanças do guia e escreve aqui e no changelog, tudo no mesmo commit. Mudança de requisito ou de decisão ainda não aprovada entra como proposta, não como fato.

Pendente:

- O guia diz, no primeiro parágrafo, que o conjunto é a "baseline de projeto v0.1", enquanto a tabela de mudanças já está em 0.3. Falta decidir se a frase se refere à versão do produto ou se deve acompanhar a tabela.
- As pendências do padrão de código (seção 9.5) continuam abertas: licença do DCM, idioma dos comentários, licença do produto, local de publicação da referência.
