# Diário

Registro informal do andamento, para quem aprova: o que foi feito e por quê, o que ficou decidido e o que está pendente. O detalhe técnico fica em `CHANGELOG.md`. A entrada mais recente fica no topo.

## 11/11/2026

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
