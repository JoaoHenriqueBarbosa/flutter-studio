<!-- STUDIO-PATCH(1): Replaces the upstream file to load the Studio documents. -->

# Studio

Editor visual de Flutter, escrito em Flutter, que renderiza o código do projeto como está e grava cada alteração nos próprios arquivos. O repositório está na baseline de projeto: os documentos em `docs/` são especificação a implementar, não descrição de software pronto.

## Código herdado

O repositório é um fork de `flutter/devtools` mantido como fila de patches (ADR-0002): o `master` do upstream fica por baixo, e os commits do Studio, por cima. Os pacotes `devtools_*`, a ferramenta `dt` e os demais arquivos do upstream são código herdado.

- Antes de tocar em arquivo herdado, leia e siga o `AGENTS.md` e o `STYLE.md` da raiz, que são do upstream.
- Toda alteração em arquivo herdado leva o marcador `STUDIO-PATCH(n)` e uma linha em `PATCHES.md`, que também registra o commit base do fork.
- `docs/README.md` e os arquivos em maiúsculas da raiz (`CONTRIBUTING.md`, `TESTING.md` e os demais) são do upstream. A documentação do Studio é a do mapa em `docs/guide.md`.

## Sempre no contexto

Os dois documentos abaixo são importados inteiros em toda sessão. Siga-os sem precisar abrir os arquivos.

- Guia (mapa dos documentos, convenções, identificadores): @docs/guide.md
- Padrão de código (regras CS e portão de qualidade): @docs/engineering/coding-standard.md

## Leia quando a tarefa pedir

Estes não são carregados sozinhos. Abra o que a tarefa tocar antes de escrever código.

| Documento | Quando abrir |
| --- | --- |
| `docs/requirements/srs.md` | Para saber o que um requisito (`FR`, `NFR`, `IR`, `DC`, `ASM`) exige, e em que incremento (F0 a F6) ele entra |
| `docs/architecture/arc42.md` | Para entender a estrutura, os cenários de qualidade (`QS`) e os riscos (`RSK`) |
| `docs/decisions/` (índice em `README.md`, um arquivo por ADR) | Antes de mudar algo coberto por uma ADR, ou para registrar uma decisão nova |
| `docs/interfaces/icd.md` | Ao mexer em contrato entre processos ou com o SDK (`IF`) |
| `docs/verification/test-plan.md` | Ao escrever teste ou conferir se um incremento está pronto (`ORC`) |

## Documentação viva

Os documentos de `docs/` são a especificação vigente, e quem trabalha no repositório os mantém verdadeiros. Documento que contradiz o código ou outro documento é defeito, do mesmo peso que um teste quebrado.

Faça isto sem esperar pedido, no mesmo commit do trabalho que causou a mudança:

1. **Atualize o documento afetado.** Se o trabalho muda, acrescenta ou invalida um requisito, uma interface, uma regra, um risco, uma premissa ou a estrutura, edite o texto no documento que é dono do assunto. Não registre a mudança só no changelog.
2. **Suba a versão do documento.** Cada documento traz a própria versão na linha de abertura ("Versão 0.2, rascunho para revisão"). Mudança de conteúdo sobe o número; correção de grafia ou de formatação não sobe.
3. **Registre na tabela de mudanças do guia.** Acrescente uma linha à tabela no fim de `docs/guide.md`, com a versão nova da baseline, a data e o que mudou, citando os identificadores (`FR-...`, `ADR-...`, `CS-...`). Vale a mesma régua do item 2: sem mudança de conteúdo, sem linha.
4. **Escreva no `CHANGELOG.md` e no `JOURNAL.md`**, conforme a seção abaixo.

Limites que os próprios documentos impõem:

- ADR aceita não é editada: uma ADR nova a substitui, em arquivo novo, com linha no índice de `docs/decisions/README.md` e o estado da antiga trocado para "substituída".
- Identificador retirado nunca é reutilizado.
- Regra e limite do padrão de código só mudam por ADR (CS-GOV-004).
- Cada conhecimento fica em um documento só; os outros citam o identificador (CS-DRY-011).

Se o trabalho pedir uma mudança de requisito ou de decisão que o dono do produto ainda não aprovou, escreva-a como proposta (ADR em estado "proposta", ou item na seção de pendências do documento) e avise no relatório. Não mude requisito aceito por conta própria.

## Changelog e diário

Dois registros na raiz, com públicos diferentes. Os dois recebem entrada no mesmo commit do trabalho, e nenhum leva atribuição a ferramenta ou a agente (CS-ASC-012).

| Arquivo | Para quem | O que entra | Forma |
| --- | --- | --- | --- |
| `CHANGELOG.md` | Quem implementa | O que mudou no repositório, com precisão técnica: pacotes, arquivos, contratos, identificadores, comandos | Keep a Changelog 1.1.0: seção "Não lançado" no topo, grupos Adicionado, Alterado, Descontinuado, Removido, Corrigido e Segurança |
| `JOURNAL.md` | Quem aprova | O que foi feito e por quê, o que ficou decidido, o que está pendente e o que depende do dono do produto, em linguagem direta e sem jargão desnecessário | Uma seção por dia (`## DD/MM/AAAA`), a mais recente no topo; dentro do dia, uma entrada curta por item de trabalho |

O changelog diz o que mudou; o diário diz o que isso significa. Não copie um no outro: o diário pode citar um identificador ou um commit em vez de repetir o detalhe.

Todo commit que muda conteúdo ganha entrada no changelog. O diário ganha entrada quando há algo que o dono do produto precisa saber: uma entrega, uma decisão, um desvio do plano, um bloqueio. Trabalho puramente mecânico não precisa de entrada no diário.
