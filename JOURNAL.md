# Diário

Registro informal do andamento, para quem aprova: o que foi feito e por quê, o que ficou decidido e o que está pendente. O detalhe técnico fica em `CHANGELOG.md`. A entrada mais recente fica no topo.

## 11/11/2026

**O repositório virou o fork do DevTools.** Começou o incremento F0. O código do DevTools (commit `9b8d6457`, de 10/11/2026) entrou por baixo dos nossos commits, como a ADR-0002 descreve, por decisão do dono do produto entre três formas possíveis. Para isso o histórico do `main` foi reescrito uma vez e enviado com force push; o conteúdo dos documentos não mudou. Isso vai se repetir a cada rebase semanal. O `PATCHES.md` registra o commit base e a fila de patches, que tem um item: o nosso `CLAUDE.md` no lugar do deles.

**GitHub Actions desligado no repositório.** O upstream traz workflows próprios, e quatro deles rodam por agenda, um sem checar em que repositório está. Para não gastarem minutos nem mexerem em issues, o Actions foi desligado nas configurações do repositório. Volta a ser ligado quando o Studio tiver o próprio CI chamando `st verify`.

Pendente do F0, em ordem: compilar e rodar o `devtools_app` em desktop com os testes herdados passando; criar os pacotes `studio_*` e o `st verify`; shell com daemon, analysis server e adaptador de debug; `DocumentStore`; experimentos das premissas ASM-01 a ASM-08.

**Repositório criado e baseline publicada.** O repositório privado `flutter-studio` existe no GitHub e já tem a baseline de projeto: os seis documentos e o guia. Ainda não há código; tudo é especificação.

**Documentos nas pastas definitivas.** Os documentos estavam todos soltos em `docs/` e o guia apontava para subpastas. Agora estão onde o guia diz. As decisões, que eram um arquivo só, viraram treze arquivos, um por ADR, com um índice. Os nomes dos arquivos das decisões foram traduzidos para o inglês, seguindo a regra de caminhos em inglês; vale uma conferida nesses nomes.

**Sessões já começam com o guia e o padrão de código.** O `CLAUDE.md` carrega os dois em toda sessão, e os outros documentos são abertos conforme a tarefa. O custo é cerca de 600 linhas de contexto por sessão.

**A documentação passou a ser mantida junto com o trabalho.** Quem mexer no repositório atualiza o documento afetado, sobe a versão dele, registra na tabela de mudanças do guia e escreve aqui e no changelog, tudo no mesmo commit. Mudança de requisito ou de decisão ainda não aprovada entra como proposta, não como fato.

Pendente:

- O guia diz, no primeiro parágrafo, que o conjunto é a "baseline de projeto v0.1", enquanto a tabela de mudanças já está em 0.3. Falta decidir se a frase se refere à versão do produto ou se deve acompanhar a tabela.
- As pendências do padrão de código (seção 9.5) continuam abertas: licença do DCM, idioma dos comentários, licença do produto, local de publicação da referência.
