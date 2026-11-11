# ADR-0016: Assets de pacote dependente resolvidos por um pacote compartilhado

Estado: proposta.

## Contexto e problema

O mecanismo da ADR-0015 faz o código de um pacote achar seus assets e suas fontes quando o pacote roda como dependência de outro aplicativo. O shell precisa dele para o `devtools_app`. O host de design precisa do mesmo mecanismo para o projeto do usuário: no projeto host (ADR-0008) o projeto é uma dependência, e a própria ADR-0008 registra que recursos e fontes precisam ser reexpostos ali. Sem isso, um app que usa imagem ou fonte própria aparece no canvas sem elas.

As duas necessidades são o mesmo conhecimento, em dois processos e sobre dois SDKs: o shell compila com o SDK do Studio, e o agente de design, com o SDK do projeto. O grafo de dependências (seção 6.1 do padrão de código) não tem pacote que os dois possam importar além do `studio_protocol`, que não pode depender do Flutter.

## Opções consideradas

1. Repetir o mecanismo no `studio_design_agent`.
2. O shell importa o mecanismo do `studio_design_agent`.
3. Um pacote novo, `studio_package_assets`, que só depende do SDK do Flutter e que o shell e o agente importam.

## Decisão

Opção 3. O pacote `studio_package_assets` recebe as classes que estavam no `studio_shell`, com nomes que não citam o código herdado: `PackageAssetBinding`, `PackageAssetMessenger`, `PackageFontRegistry` e `MessageChannelAssetBundle`. O shell as usa para o `devtools_app`; o agente, para o pacote do projeto, antes de chamar o `main` dele.

O grafo de dependências ganha duas arestas: `studio_shell` e `studio_design_agent` passam a depender de `studio_package_assets`, que não depende de nenhum pacote do Studio. A restrição do agente na seção 6.1 do padrão de código passa a admitir esse pacote, e a linha do Decorator no catálogo da seção 6.3 passa a citar `PackageAssetMessenger`.

A opção 1 mantém duas cópias da mesma lógica (CS-DRY-002). A opção 2 cria uma dependência do shell para um pacote que roda em outro processo e carrega o que não é do shell.

## Consequências

- Bom: uma implementação só, com um conjunto só de testes; o projeto do usuário continua sem dependência nem arquivo do Studio (DC-02).
- Ruim: mais um pacote que precisa compilar em todos os SDKs da janela (NFR-FLEX-001); o binding do aplicativo no host de design passa a ser o do Studio, e um app que exige binding próprio antes do `runApp` recebe o que já existe.

## Confirmação

FR-HST-001; teste de sistema do `studio_core` em que o host de design carrega um asset do projeto e falha num asset que o projeto não tem.
