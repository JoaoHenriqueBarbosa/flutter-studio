# Studio: documentação do sistema

11/11/2026 · João Henrique Barbosa

## Finalidade e alcance

Este conjunto é a baseline de projeto v0.1 do Studio: um editor visual de Flutter, escrito em Flutter, que renderiza o código do projeto como está e grava cada alteração nos próprios arquivos. Nada aqui descreve software já construído. Tudo é especificação a implementar, e cada decisão está marcada como proposta ou aceita.

Os leitores são quem implementa (um agente de IA trabalhando no repositório) e quem aprova (o dono do produto). Cada documento segue uma norma ou um modelo público, nomeado no mapa abaixo, para que estrutura e vocabulário não dependam de quem escreveu.

"Studio" é nome provisório. Fato verificado no código do DevTools ou na documentação do SDK aparece com a fonte. Hipótese aparece como premissa numerada (SRS, apêndice A) ou como risco (Arquitetura, seção 11).

## Mapa de documentos

São seis documentos, um por aba, mais este guia. No repositório cada um vira Markdown versionado junto com o código (docs-as-code), no caminho indicado.

| Documento | O que responde | Norma ou modelo | Destino no repositório |
| --- | --- | --- | --- |
| Requisitos (SRS) | O que o sistema deve fazer e sob quais limites | ISO/IEC/IEEE 29148:2018; requisitos em sintaxe EARS | `docs/requirements/srs.md` |
| Arquitetura (arc42) | Como o sistema se estrutura e por quê | arc42 (12 seções); diagramas C4; qualidade pela ISO/IEC 25010:2023 | `docs/architecture/arc42.md` |
| Decisões (ADR) | Qual decisão foi tomada, entre quais opções, com que consequências | MADR 4.0.0 | `docs/decisions/NNNN-title-with-dashes.md` |
| Interfaces (ICD) | Qual é o contrato entre os processos e com o SDK | JSON-RPC 2.0; OpenRPC 1.4; BCP 14 | `docs/interfaces/icd.md`; o documento OpenRPC fica no pacote `studio_protocol` |
| Verificação | Como cada requisito é verificado e quando um incremento está pronto | ISO/IEC/IEEE 29119-3:2021, plano de teste | `docs/verification/test-plan.md` |
| Padrão de código | Como o código é escrito, nomeado, comentado, documentado e verificado | Effective Dart; Rust API Guidelines; manutenibilidade pela ISO/IEC 25010:2023 | `docs/engineering/coding-standard.md` |

Ficam fora desta baseline a documentação de usuário e o guia de contribuição. Entram quando houver software para descrever.

## Convenções

**Palavras normativas.** DEVE, NÃO DEVE, DEVERIA, NÃO DEVERIA e PODE têm o sentido de MUST, MUST NOT, SHOULD, SHOULD NOT e MAY da BCP 14, e só quando escritas em maiúsculas.

**Sintaxe dos requisitos.** Cada requisito é uma frase em um dos padrões EARS:

| Padrão | Forma |
| --- | --- |
| Ubíquo | O Studio DEVE *resposta*. |
| Dirigido por evento | Quando *gatilho*, o Studio DEVE *resposta*. |
| Dirigido por estado | Enquanto *estado*, o Studio DEVE *resposta*. |
| Recurso opcional | Onde *recurso presente*, o Studio DEVE *resposta*. |
| Comportamento indesejado | Se *condição*, então o Studio DEVE *resposta*. |

**Identificadores.** São estáveis: um identificador retirado nunca é reutilizado.

| Prefixo | Identifica | Exemplo |
| --- | --- | --- |
| `FR-<group>-NNN` | Requisito funcional | `FR-STR-002` |
| `NFR-<group>-NNN` | Requisito de qualidade | `NFR-PERF-002` |
| `IR-NNN` | Requisito de interface | `IR-003` |
| `DC-NN` | Restrição de projeto | `DC-01` |
| `ASM-NN` | Premissa | `ASM-01` |
| `ADR-NNNN` | Decisão de arquitetura | `ADR-0004` |
| `QS-NN` | Cenário de qualidade | `QS-03` |
| `RSK-NN` | Risco | `RSK-02` |
| `IF-NN` | Interface | `IF-06` |
| `ORC-NN` | Oráculo de verificação | `ORC-01` |
| `CS-<group>-NNN` | Regra de código | `CS-DRY-005` |
| `QG-NN` | Passo do portão de qualidade | `QG-06` |
| `WVR-NNN` | Dispensa de regra de código | `WVR-001` |

**Rastreabilidade.** Todo teste cita o requisito que verifica, em comentário `// Verifies: FR-STR-002`. Toda ADR cita os requisitos que a motivam.

**Incrementos.** F0 a F6 nomeiam os incrementos de entrega, definidos no apêndice B do SRS.

**Método de verificação.** T é teste automatizado, D é demonstração, A é análise e I é inspeção de código ou de artefato.

**Idioma.** O texto é em português. Identificadores, nomes de método, caminhos e chaves são em inglês.

## Referências e controle de mudanças

Normas e modelos adotados:

- [ISO/IEC/IEEE 29148:2018](https://standards.iteh.ai/catalog/standards/iso/8cf2bc2b-8b5e-4907-a82a-d1c5676c9e85/iso-iec-ieee-29148-2018), engenharia de requisitos. O texto é pago; a estrutura do SRS segue o sumário público da cláusula 8.5.2.
- [arc42](https://arc42.org/overview), modelo de documentação de arquitetura em 12 seções.
- [C4 model](https://c4model.com/), diagramas de contexto, de contêiner e dinâmico.
- [MADR 4.0.0](https://adr.github.io/madr/), registros de decisão de arquitetura.
- [ISO/IEC 25010:2023](https://quality.arc42.org/standards/iso-25010), modelo de qualidade de produto com nove características.
- [ISO/IEC/IEEE 42010:2022](https://quality.arc42.org/standards/iso-42010), descrição de arquitetura: partes interessadas, preocupações e visões.
- [ISO/IEC/IEEE 29119-3:2021](https://standards.iteh.ai/catalog/standards/iso/b4f42a41-dd8f-446c-9674-238ba5dc90f1/iso-iec-ieee-29119-3-2021), documentação de teste.
- [EARS](https://en.wikipedia.org/wiki/Easy_Approach_to_Requirements_Syntax), sintaxe de requisitos (Mavin e outros, 2009).
- BCP 14: [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119.html) e [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174.html).
- [OpenRPC 1.4](https://spec.open-rpc.org/), descrição de APIs JSON-RPC 2.0.

Fontes técnicas verificadas para esta baseline:

- [flutter/devtools](https://github.com/flutter/devtools), lido no commit `9b8d645` de 10/11/2026.
- [Analysis server: LSP e métodos customizados](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server/tool/lsp_spec/README.md).
- [Debug Adapter Protocol no Flutter](https://dart.googlesource.com/external/github.com/flutter/flutter/+/7fe3565a9b335b6a3aa71de1698a82b2ff0fadee/packages/flutter_tools/lib/src/debug_adapters/README.md).
- [Extensões de serviço do inspector](https://codebrowser.dev/flutter/flutter/packages/flutter/lib/src/widgets/service_extensions.dart.html).
- [Flutter Widget Previewer](https://docs.flutter.dev/tools/widget-previewer.md) e [Flutter Property Editor](https://docs.flutter.dev/tools/property-editor.html).
- [Custom Flutter Engine Embedders](https://github.com/flutter/engine/blob/main/docs/Custom-Flutter-Engine-Embedders.md) e [custom devices no Flutter CLI](https://flutter.googlesource.com/mirrors/flutter/+/HEAD/docs/tool/Using-custom-embedders-with-the-Flutter-CLI.md).

| Versão | Data | Mudança |
| --- | --- | --- |
| 0.1 | 11/11/2026 | Primeira baseline: SRS, arquitetura, ADR-0001 a ADR-0012, interfaces e plano de verificação. |
| 0.2 | 11/11/2026 | Padrão de código, com as regras CS e o portão de qualidade; NFR-MNT-005 a 008; ADR-0013; ORC-11. |
| 0.3 | 11/11/2026 | Documentos movidos para os caminhos do mapa; decisões divididas em um arquivo por ADR, com índice; `CHANGELOG.md` e `JOURNAL.md` na raiz. |
| 0.4 | 11/11/2026 | Início do F0: situação das premissas no apêndice A do SRS, com o resultado parcial de ASM-06; RSK-11, sobre regressões no SDK candidato do upstream. |
| 0.5 | 11/11/2026 | ADR-0014, aceita: produto construído com o Flutter estável, em workspace próprio. ADR-0015, proposta: assets e fontes do código herdado resolvidos no binding do shell. Padrão de código 0.2: seções 2.2, 5.2 e 6.3. Arquitetura 0.4: RSK-11 e local dos pacotes `studio_*`. |
| 0.6 | 11/11/2026 | ADR-0003 a ADR-0013 passam a aceitas: o dono do produto as aprovou ao publicar a baseline, e o estado não tinha sido atualizado. |
| 0.7 | 11/11/2026 | ADR-0015 aceita; o padrão Decorator fica no catálogo do padrão de código (0.3) sem ressalva. |
| 0.8 | 11/11/2026 | Primeiro entregável. Arquitetura 0.5: três itens de dívida técnica (desvio de FR-API-002, documentos não abertos no analysis server, daemon órfão). Padrão de código 0.4: a exclusão de diretórios no `analysis_options.yaml` vale para todo pacote Flutter. |
| 0.9 | 11/11/2026 | Interfaces 0.2: local do documento OpenRPC, envelope do resultado no daemon, campo `options` em `Property`, tipo `TextDocumentEdit`, forma do evento `selectionChanged` e alcance do contrato 0.1.0 (IF-04, ADR-0013). |
| 0.10 | 11/11/2026 | Serviço `Studio` registrado no daemon. Interfaces 0.3: alcance de `setProperty` no contrato 0.1.0. Arquitetura 0.6: sai da dívida técnica o item dos documentos não abertos no analysis server. |

Esta tabela registra as mudanças de conteúdo da baseline. O detalhe técnico de cada mudança fica em `CHANGELOG.md`, e o relato para quem aprova, em `JOURNAL.md`, os dois na raiz do repositório.
