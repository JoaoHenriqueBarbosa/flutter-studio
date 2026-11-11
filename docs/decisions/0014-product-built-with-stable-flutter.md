# ADR-0014: Produto construído com o Flutter estável

Estado: aceita.

## Contexto e problema

A ADR-0002 aceitou, como consequência do fork, que a versão de Flutter do Studio ficasse atrelada à do DevTools. O upstream fixa em `flutter-candidate.txt` uma pré-versão do Flutter e a troca quase toda semana. No primeiro dia do F0, o candidato `de37392d` (3.50.0-1.0.pre-437) desenhou a janela de qualquer app em Linux deslocada em meia janela com o driver proprietário da NVIDIA ([flutter/flutter#195885](https://github.com/flutter/flutter/issues/195885)), enquanto o mesmo código, compilado com o estável 3.47.9, desenhou certo (RSK-11).

O `pubspec.yaml` dos pacotes herdados aceita uma faixa de versões (`flutter: ^3.41.0` no commit base), então o código herdado compila com versões estáveis.

## Direcionadores

- O produto entregue não pode depender de uma pré-versão do engine.
- Os testes herdados só valem como garantia na versão em que o upstream os valida (NFR-MNT-004).
- Custo de manter dois SDKs no mesmo repositório.

## Opções consideradas

1. Tudo com o candidato do upstream, como a ADR-0002 previa.
2. Tudo com o estável.
3. Produto com o estável; código herdado testado com o candidato.

## Decisão

Opção 3. Os pacotes `studio_*` formam um workspace do pub próprio, em `studio/`, com `pubspec.lock` próprio, resolvido com a versão estável fixada em `studio/flutter-version.txt`. Esse workspace usa os pacotes herdados por caminho. O workspace herdado, na raiz, continua resolvido e testado com o candidato de `flutter-candidate.txt`, sem patch no `pubspec.yaml` nem no `pubspec.lock` do upstream.

A versão fixada é a estável mais recente que satisfaz as restrições dos pacotes herdados. Se um rebase trouxer restrição que nenhuma estável satisfaz, o produto volta ao candidato até a estável seguinte, e o fato é registrado no diário.

Esta decisão troca uma consequência da ADR-0002, a de a versão de Flutter do Studio ficar atrelada à do DevTools. A decisão da ADR-0002, o fork como fila de patches, segue vigente.

## Consequências

- Bom: o engine do produto é o de uma versão estável; uma regressão do candidato não chega ao usuário; o workspace herdado fica sem patch de configuração.
- Ruim: o código herdado roda no produto numa versão diferente daquela em que o upstream o testa, e um uso de API mais nova que a estável só aparece no build do produto, a cada rebase; há dois SDKs e dois `pubspec.lock` no repositório; o portão precisa rodar cada workspace com o seu SDK.
- A ferramenta do Flutter estável reescreve o `analysis_options.yaml` de pacote com runner de plataforma para excluir os diretórios de build e de plataforma. Nesses pacotes o arquivo deixa de ter uma linha só (padrão de código, seção 2.2), mas continua sem declarar regra (CS-QLT-002).

## Confirmação

RSK-11; CS-ASC-010, com as duas versões fixadas em arquivo; a cada rebase, build do `studio_shell` e testes herdados aprovados, cada um com o seu SDK.
