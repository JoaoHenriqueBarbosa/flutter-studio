# Padrão de código

Regras de código do Studio, cada uma com identificador, enunciado normativo e forma de verificação. Versão 0.6, rascunho para revisão.

## 1. Propósito, alcance e precedência

Este documento fixa como o código do Studio é escrito, nomeado, comentado e documentado. Cada regra tem identificador, enunciado normativo e forma de verificação; o que não pode ser verificado não entra como regra.

As regras realizam a característica de manutenibilidade da ISO/IEC 25010:2023. São exigidas pelos requisitos NFR-MNT-005 a NFR-MNT-008, em Requisitos (SRS).

### 1.1 Alcance

| Território | O que inclui | Regras que valem |
| --- | --- | --- |
| Código próprio | Pacotes `studio_*`, o código Rust do host nativo, o pacote de ferramentas `studio_tool`, geradores, testes, fixtures, exemplos e configuração de CI | Este documento, inteiro |
| Código herdado | Pacotes `devtools_*` e a ferramenta `dt` do upstream | `STYLE.md`, `AGENTS.md` e `analysis_options.yaml` do upstream |
| Trecho `STUDIO-PATCH` | Linhas alteradas em arquivo herdado (ADR-0002) | Regras do upstream, o marcador da seção 7.2 e a proibição de diagnóstico novo |
| Código gerado | Saída de `st generate`, `build_runner`, `flutter gen-l10n` e `bindgen` | Seção 5.3 |
| Código do projeto do usuário | O que o Studio escreve no projeto aberto | Fora do alcance: segue as convenções do próprio projeto (FR-COD, FR-EVT) |

### 1.2 Precedência

1. Restrições da linguagem, do SDK e das licenças.
2. Este documento.
3. Regras do upstream DevTools, no commit fixado.
4. Effective Dart, para Dart; Rust API Guidelines e o estilo padrão do `rustfmt`, para Rust.

No código próprio, este documento só acrescenta rigor ao upstream: nenhuma regra daqui afrouxa uma regra de lá. Em arquivo herdado vale só o item 3, e o patch imita o estilo do arquivo em que entra.

### 1.3 Identificadores

As palavras DEVE, NÃO DEVE, DEVERIA e PODE seguem a BCP 14, como no Guia. Regras usam `CS-<group>-NNN`, passos do portão usam `QG-NN` e dispensas usam `WVR-NNN`.

| Grupo | Assunto | Seção |
| --- | --- | --- |
| `ASC` | Ascetismo | 2 |
| `NAM` | Idioma e nomes | 3 |
| `QLT` | Formatação, análise estática e limites | 4 |
| `DRY` | Fonte única | 5 |
| `DSN` | Dependências e padrões de projeto | 6 |
| `CMT` | Comentários | 7 |
| `DOC` | Documentação gerada | 8 |
| `GOV` | Verificação e dispensas | 9 |

Na coluna Verificação, `QG-NN` aponta o passo do portão que reprova a violação (seção 9.1). "Revisão" aponta a lista de revisão (seção 9.3).

### 1.4 Referências

- Effective Dart, partes Style, Documentation, Usage e Design: [Documentation](https://dart.dev/effective-dart/documentation).
- [Customizing static analysis](https://dart.dev/tools/analysis) e [Linter rules](https://dart.dev/lints), em dart.dev.
- [dartdoc](https://pub.dev/documentation/dartdoc/latest/), o gerador de documentação do Dart.
- `STYLE.md`, `AGENTS.md` e `analysis_options.yaml` de [flutter/devtools](https://github.com/flutter/devtools), commit `9b8d6457`.
- [Rust API Guidelines, checklist](https://rust-lang.github.io/api-guidelines/checklist.html), e RFC 430.
- [Clippy](https://doc.rust-lang.org/clippy), grupos de lints.
- [PMD CPD](https://docs.pmd-code.org/pmd-doc-7.14.0/pmd_userdocs_cpd.html), detector de duplicação.
- [DCM](https://dcm.dev/docs/cli/code-quality-checks/code-duplication), regras, métricas e verificações para Dart.
- [cspell](https://github.com/streetsidesoftware/cspell), verificador ortográfico para código.
- Watson, A. H.; McCabe, T. J. Structured Testing: A Testing Methodology Using the Cyclomatic Complexity Metric. [NIST SP 500-235](https://doi.org/10.6028/NIST.SP.500-235), 1996.
- Hunt, A.; Thomas, D. The Pragmatic Programmer. Addison-Wesley, 1999.
- Gamma, E. et al. Design Patterns. Addison-Wesley, 1994.
- Fowler, M. Patterns of Enterprise Application Architecture. Addison-Wesley, 2002.
- Buschmann, F. et al. Pattern-Oriented Software Architecture, volume 1. Wiley, 1996.

## 2. Ascetismo como regras verificáveis

O acabamento do código não depende de quem vai lê-lo, nem do tamanho ou do destino do projeto. Código interno, privado, de teste, de ferramenta e de protótipo segue as mesmas regras do código público.

As regras abaixo traduzem esse princípio em condições que uma ferramenta ou um revisor conseguem checar. Onde outra seção for omissa, decide-se pelo lado mais estrito.

### 2.1 Regras

| ID | Regra | Verificação |
| --- | --- | --- |
| CS-ASC-001 | Toda regra deste documento DEVE valer igualmente para código de produção, de teste, de ferramenta, de geração, de exemplo e de CI. Não existe categoria isenta. | QG-01 a QG-13 rodam em toda a árvore do código próprio |
| CS-ASC-002 | O código próprio DEVE compilar e analisar sem nenhum diagnóstico: erro, aviso, info ou lint. NÃO DEVE existir linha de base de violações toleradas. | QG-02, QG-03, QG-05 |
| CS-ASC-003 | Uma supressão de diagnóstico DEVE citar uma dispensa `WVR-NNN` vigente e o motivo. Supressão de arquivo inteiro (`ignore_for_file`, `#![allow]`) NÃO DEVE existir fora de código gerado. | QG-02 (`document_ignores`, `unnecessary_ignore`), QG-05 (`allow_attributes`, `allow_attributes_without_reason`), QG-13 |
| CS-ASC-004 | NÃO DEVE existir código morto: declaração sem uso, arquivo sem referência, dependência sem import, parâmetro ignorado, ramo inalcançável. | QG-02, QG-03, QG-05 |
| CS-ASC-005 | NÃO DEVE existir código comentado. O que saiu do código fica no histórico do Git. | Revisão |
| CS-ASC-006 | Nada provisório DEVE chegar ao ramo principal: `print`, `debugPrint`, `dbg!`, `todo!`, `unimplemented!`, `UnimplementedError`, teste com `skip`, nomes como `tmp`, `foo`, `new2`, `old`. | QG-02 (`avoid_print`), QG-03 (`ban-name`), QG-05 (`dbg_macro`, `todo`, `unimplemented`), QG-10 |
| CS-ASC-007 | Um `TODO` DEVE ter dono e endereço de issue aberta. `FIXME`, `HACK` e `XXX` NÃO DEVEM ser usados. | QG-02 (`flutter_style_todos`), QG-10 |
| CS-ASC-008 | Onde existe convenção consolidada e publicada, ela DEVE ser usada em lugar de solução própria. O desvio exige ADR. | Revisão |
| CS-ASC-009 | Todo pacote DEVE ter a anatomia da seção 2.2, e todo arquivo, a ordem da seção 2.3. | QG-03 (`member-ordering`), QG-08 |
| CS-ASC-010 | As versões do SDK, do toolchain Rust e das ferramentas do portão DEVEM estar fixadas em arquivo do repositório. O portão DEVE ser o mesmo comando na máquina do autor e no CI. | QG-08 |
| CS-ASC-011 | Uma mudança DEVE deixar em conformidade integral cada arquivo próprio que toca. | QG-01 a QG-13; Revisão |
| CS-ASC-012 | Mensagens de commit, descrições de PR, issues e changelogs NÃO DEVEM conter rodapé nem atribuição de ferramenta, como `Co-Authored-By` de assistente ou "Generated with". | QG-10 |

### 2.2 Anatomia de pacote

Todo pacote Dart próprio tem a mesma forma.

| Caminho | Conteúdo |
| --- | --- |
| `lib/<package>.dart` | Biblioteca pública; contém só `export` |
| `lib/src/` | Implementação; um conceito por arquivo, com o nome da declaração principal |
| `test/` | Espelho de `lib/src/`: `lib/src/edit/edit_pipeline.dart` é testado em `test/edit/edit_pipeline_test.dart` |
| `README.md`, `CHANGELOG.md` | Página inicial da referência gerada; mudanças por versão |
| `pubspec.yaml` | Dependências em ordem alfabética; nenhuma sem uso |
| `analysis_options.yaml` | Inclui o arquivo comum (CS-QLT-002) e não declara regra. Em pacote Flutter, traz também as exclusões de diretório que a ferramenta do Flutter escreve e mantém (ADR-0014) |

O código Rust segue o layout padrão do Cargo, com os lints declarados na tabela `[workspace.lints]` do `Cargo.toml`.

### 2.3 Ordem dentro do arquivo

1. Cabeçalho de licença (CS-CMT-010).
2. Comentário de documentação da biblioteca, quando o arquivo é biblioteca pública.
3. Diretivas, na ordem do lint `directives_ordering`.
4. Declarações: a principal primeiro, as auxiliares privadas depois.

Dentro de uma classe: construtores, campos e propriedades, métodos públicos, métodos privados. Propriedade com campo privado segue a ordem do `STYLE.md` do upstream: getter público, campo privado, setter público.

## 3. Idioma e nomes

Todo identificador é escrito em inglês, em qualquer linguagem e em qualquer artefato. O português aparece só em conteúdo: texto de interface, ajuda do produto e esta documentação.

### 3.1 Idioma por artefato

| Artefato | Idioma |
| --- | --- |
| Tipos, membros, variáveis, parâmetros, constantes, pacotes, crates, arquivos e diretórios | Inglês |
| Métodos RPC, chaves JSON, nomes de erro, extensões de serviço, variáveis de ambiente, opções de linha de comando, chaves de configuração e chaves ARB | Inglês |
| Descrições de teste, mensagens de log, de exceção e de asserção | Inglês |
| Comentários e comentários de documentação | Inglês (pendência em 9.5) |
| Texto visível ao usuário | Português do Brasil e inglês, em arquivos ARB (Arquitetura, 8.7) |
| Ajuda e manual do produto | Português do Brasil |
| Documentação de sistema | Português, com identificadores em inglês |

### 3.2 Regras

| ID | Regra | Verificação |
| --- | --- | --- |
| CS-NAM-001 | Todo identificador DEVE ser formado por palavras inglesas, em ASCII. Palavra portuguesa, transliteração e mistura das duas línguas NÃO DEVEM aparecer. | QG-07; QG-05 (`non_ascii_idents`) |
| CS-NAM-002 | Dart: tipos, extensões e enums em `UpperCamelCase`; membros, variáveis, parâmetros e constantes em `lowerCamelCase`; pacotes, diretórios, arquivos e prefixos de import em `lowercase_with_underscores`. | QG-02 |
| CS-NAM-003 | Sigla com mais de duas letras DEVE ser escrita como palavra: `LspClient`, `DtdConnection`, `HttpServer`. | Revisão |
| CS-NAM-004 | Rust: RFC 430 e Rust API Guidelines. Tipos e traits em `UpperCamelCase`; funções, módulos e variáveis em `snake_case`; constantes em `SCREAMING_SNAKE_CASE`; getters sem `get_`; conversões `as_`, `to_`, `into_`. | QG-05 |
| CS-NAM-005 | Protocolo: métodos RPC e chaves JSON em `lowerCamelCase`; nomes de erro em `UpperCamelCase`; extensões de serviço em `ext.studio.<area>.<verb>`. | QG-09 |
| CS-NAM-006 | Texto visível ao usuário NÃO DEVE ser literal no código próprio. Vem de arquivo ARB; a chave ARB é identificador e segue CS-NAM-001. | QG-03 (`avoid-non-ascii-symbols`), QG-10 |
| CS-NAM-007 | Um conceito DEVE ter um único nome em todo o código: o do glossário (Arquitetura, 12). Sinônimos NÃO DEVEM coexistir. | QG-07; Revisão |
| CS-NAM-008 | O código DEVE usar o termo Flutter do glossário, como `widget` e `property`. O termo Delphi aparece só no texto de interface e na tabela de correspondência. | Revisão |
| CS-NAM-009 | Booleano DEVE ser predicado afirmativo: `isSelected`, `hasErrors`, `canUndo`. Método com efeito leva verbo no imperativo; método que só devolve valor leva substantivo. | Revisão |
| CS-NAM-010 | Abreviação NÃO DEVE ser usada fora da lista aprovada. Nome de uma letra só em índice de laço e em parâmetro de tipo. | QG-07 |
| CS-NAM-011 | `String` que guarda caminho ou URI DEVE terminar em `Path` ou `Uri`, como no upstream. Quantidade primitiva em protocolo DEVE levar a unidade: `timeoutMs`, `widthPx`. | Revisão |
| CS-NAM-012 | Nomes sem conteúdo NÃO DEVEM ser usados em tipo nem em arquivo: `Manager`, `Helper`, `Util`, `Utils`, `Misc`, `Common`. Cada função mora no módulo do conceito a que pertence. | QG-08 |
| CS-NAM-013 | Arquivo DEVE levar o nome da sua declaração principal em `snake_case`. Arquivo de teste termina em `_test.dart`. | QG-03 (`prefer-match-file-name`, `prefer-correct-test-file-name`) |

### 3.3 Como "inglês" é verificado

O `cspell` separa cada identificador em palavras, por `camelCase` e `snake_case`, e confere cada uma contra dicionários de inglês, Dart, Flutter e Rust. Palavra desconhecida reprova o portão: é corrigida ou entra na lista do projeto em `cspell.config.yaml`, sob revisão.

Essa lista é a única fonte de termos de domínio e de abreviações aceitas. Os sinônimos rejeitados de CS-NAM-007 ficam na chave `flagWords` do mesmo arquivo.

## 4. Qualidade de código: formatação, análise estática e limites

Formatação e análise são decididas por ferramenta, não por opinião. O que a ferramenta rejeita não entra; o que ela aceita não se discute em revisão.

### 4.1 Dart

| ID | Regra | Verificação |
| --- | --- | --- |
| CS-QLT-001 | O código Dart DEVE estar formatado por `dart format` na configuração padrão. O arquivo de análise NÃO DEVE ter seção `formatter`. | QG-01, QG-02 (`lines_longer_than_80_chars`) |
| CS-QLT-002 | A análise DEVE vir de um único arquivo comum, que inclui o `analysis_options.yaml` do upstream e só acrescenta regras. Pacote NÃO DEVE declarar regra própria. | QG-08 |
| CS-QLT-003 | Os modos `strict-casts`, `strict-inference` e `strict-raw-types` DEVEM estar ligados. `dynamic` só PODE aparecer na decodificação de JSON, dentro dos adaptadores de borda. | QG-02; QG-03 (`avoid-dynamic`) |
| CS-QLT-004 | As regras da seção 4.2 DEVEM estar ligadas além das herdadas, e todo diagnóstico DEVE reprovar a análise. | QG-02, QG-03 |
| CS-QLT-005 | Todo `Future` DEVE ser aguardado, encadeado ou marcado com `unawaited`. Toda assinatura de stream, controlador e listener DEVE ser liberada em `dispose`. | QG-02 (`unawaited_futures`, `discarded_futures`, `cancel_subscriptions`); QG-03 (`dispose-fields`, `always-remove-listener`) |
| CS-QLT-006 | Erro DEVE ser tipado. `catch` sem cláusula `on` e `catch` vazio NÃO DEVEM existir; só se lança subtipo de `Exception` ou de `Error`. | QG-02 (`avoid_catches_without_on_clauses`, `empty_catches`, `only_throw_errors`) |
| CS-QLT-007 | O operador de asserção não nula `!` NÃO DEVE ser usado. O nulo é tratado por promoção de tipo, por padrão ou por valor padrão. | QG-03 (`avoid-non-null-assertion`) |

Os três modos estritos estão desligados no upstream, pelo volume de ajustes que exigiriam lá. O código próprio nasce com eles ligados.

### 4.2 Regras acrescentadas ao conjunto do upstream

| Regra | Ferramenta | Serve a |
| --- | --- | --- |
| `public_member_api_docs` | Analisador | CS-DOC-001 |
| `flutter_style_todos` | Analisador | CS-ASC-007 |
| `document_ignores`, `unnecessary_ignore` | Analisador | CS-ASC-003 |
| `avoid_catches_without_on_clauses`, `only_throw_errors` | Analisador | CS-QLT-006 |
| `unreachable_from_main` | Analisador | CS-ASC-004 |
| `sort_pub_dependencies` | Analisador | Seção 2.2 |
| `missing_code_block_language_in_doc_comment` | Analisador | CS-DOC-008 |
| `lines_longer_than_80_chars` | Analisador | CS-QLT-001 |
| `avoid_positional_boolean_parameters` | Analisador | CS-DSN-013 |
| `member-ordering` | DCM | Seção 2.3 |
| `prefer-match-file-name`, `prefer-correct-test-file-name` | DCM | CS-NAM-013 |
| `avoid-non-ascii-symbols` | DCM | CS-NAM-006 |
| `no-magic-number` | DCM | CS-DRY-004 |
| `avoid-banned-imports` | DCM | CS-DSN-001 |
| `avoid-global-state` | DCM | CS-DSN-005 |
| `ban-name` | DCM | CS-ASC-006 |
| `format-comment` | DCM | CS-CMT-003 |
| `avoid-non-null-assertion` | DCM | CS-QLT-007 |

As regras do DCM desta tabela constam da configuração do upstream, desligadas. No código próprio entram ligadas desde o primeiro commit.

### 4.3 Limites

| Medida | Upstream | Código próprio |
| --- | --- | --- |
| Complexidade ciclomática por função (`cyclomatic-complexity`) | 20 | 10 |
| Parâmetros por função (`number-of-parameters`) | 4 | 4 |
| Nível de aninhamento (`maximum-nesting-level`) | 5 | 5 |
| Linhas de código por função (`source-lines-of-code`) | Sem limite | 50 |

O limite de 10 é o valor original de McCabe, que a NIST SP 500-235 mantém como ponto de partida. Em Rust os mesmos limites entram no `clippy.toml`, pelos lints `too_many_arguments`, `too_many_lines` e `cognitive_complexity`.

### 4.4 Rust

O código Rust do host nativo trata todo aviso do compilador e do Clippy como erro. Suas regras começam em CS-QLT-010.

| ID | Regra | Verificação |
| --- | --- | --- |
| CS-QLT-010 | O código Rust DEVE estar formatado por `rustfmt` na configuração padrão. | QG-04 |
| CS-QLT-011 | Os grupos padrão do Clippy e o grupo `pedantic` DEVEM reprovar a compilação. Do grupo `restriction` entram só os lints listados abaixo, um a um. | QG-05 |
| CS-QLT-012 | `unsafe` DEVE ficar confinado a dois crates: o de bindings gerados (`studio_embedder_sys`) e o que os envolve em API segura (`studio_host_platform`). Os demais DEVEM declarar `#![forbid(unsafe_code)]`. | QG-05, QG-08 |
| CS-QLT-013 | Todo bloco `unsafe` DEVE ter comentário `// SAFETY:`, e toda função `unsafe` DEVE ter seção `# Safety`. | QG-05 (`undocumented_unsafe_blocks`, `missing_safety_doc`) |
| CS-QLT-014 | Código que não é de teste NÃO DEVE usar `unwrap`, `expect`, `panic!` nem indexação que pode falhar. Falha é `Result` com enum de erro. | QG-05 |
| CS-QLT-015 | Supressão DEVE usar `#[expect]` com `reason`, nunca `#[allow]`. | QG-05 (`allow_attributes`, `allow_attributes_without_reason`), QG-13 |
| CS-QLT-016 | Recurso do sistema DEVE ser liberado por `Drop`: memória compartilhada, textura, processo filho. | Revisão |

Lints de `restriction` ligados: `undocumented_unsafe_blocks`, `unwrap_used`, `expect_used`, `panic`, `indexing_slicing`, `todo`, `unimplemented`, `dbg_macro`, `print_stdout`, `allow_attributes` e `allow_attributes_without_reason`. O grupo nunca entra inteiro: a documentação do Clippy o desaconselha, porque seus lints podem se contradizer.

Os nomes dos dois crates com `unsafe` são provisórios até o incremento F5.

## 5. DRY absoluto

Cada conhecimento do sistema tem uma única fonte com autoridade, e todo o resto é derivado dela por máquina. A regra mede conhecimento, não semelhança de texto: constante, formato, contrato, regra de negócio, configuração e vocabulário.

### 5.1 Regras

| ID | Regra | Verificação |
| --- | --- | --- |
| CS-DRY-001 | Um conhecimento DEVE ter uma única representação com autoridade. Toda outra ocorrência DEVE ser gerada dela ou apontar para ela. | QG-06, QG-09; Revisão |
| CS-DRY-002 | A segunda ocorrência de um trecho de lógica DEVE virar extração. Não se espera a terceira. | QG-06; Revisão |
| CS-DRY-003 | Duplicata apontada pela ferramenta DEVE ser eliminada. Se os dois trechos representam conhecimentos distintos, que mudam por motivos distintos, ficam separados sob dispensa que diga quais são. | QG-06, QG-13 |
| CS-DRY-004 | Literal com significado DEVE ser constante nomeada, declarada uma vez: número, nome de método, caminho, duração, cor, espaçamento. | QG-03 (`no-magic-number`), QG-10 |
| CS-DRY-005 | Tipos, constantes e nomes de protocolo DEVEM ser gerados das fontes da seção 5.2. NÃO DEVEM ser digitados em Dart nem em Rust. | QG-09, QG-10 |
| CS-DRY-006 | Código do upstream NÃO DEVE ser copiado para pacote próprio. Usa-se por import; se o símbolo é privado, um `STUDIO-PATCH` o exporta. | QG-06 |
| CS-DRY-007 | Uma lógica NÃO DEVE existir em Dart e em Rust ao mesmo tempo. O host contém só o que é do host; o que os dois lados compartilham é gerado. | QG-09; Revisão |
| CS-DRY-008 | Infraestrutura de teste DEVE ser compartilhada: fixtures, construtores de dados, fakes e matchers. Caso de teste duplicado é defeito. | QG-06 |
| CS-DRY-009 | Cada caso de teste DEVE declarar no próprio corpo as entradas e o resultado esperado. Esses valores especificam o caso; não são repetição. | Revisão |
| CS-DRY-010 | Cada assunto de configuração DEVE ter um único arquivo: análise, versões, dicionário, limites, passos do portão. | QG-08 |
| CS-DRY-011 | Documentação NÃO DEVE repetir o que outra fonte afirma. Comentário cita `ADR-NNNN` ou o identificador do requisito em vez de copiar o texto. | Revisão |

### 5.2 Fonte única por tipo de conhecimento

| Conhecimento | Fonte única | Derivados | Mecanismo |
| --- | --- | --- | --- |
| Contrato do serviço `Studio`: métodos, tipos, erros, exemplos | `studio.openrpc.json`, em `studio_protocol` | Tipos e stubs Dart, códigos de erro, referência da API, descrições para MCP | `st generate` (ADR-0013) |
| Layouts binários do quadro e do espelho de cena | Arquivo de layouts, em `studio_protocol` | Acessores Dart do agente, `struct` `#[repr(C)]` do host, tabelas do ICD | `st generate`; teste de bytes dourados nos dois lados |
| Nomes de serviço, método e extensão | Constantes geradas em `studio_protocol` | Todo uso no shell, no agente, no motor e no host | Literal fora do pacote reprova em QG-10 |
| Correspondência entre Delphi e Flutter | Tabela única de dados (Arquitetura, 8.7) | Rótulos, ajuda, tabela do glossário | Lida pelo produto; tabela do glossário gerada |
| Texto de interface | Arquivos ARB | Classe de localização | `flutter gen-l10n` |
| Cores, tipografia e espaçamento | Tema de `devtools_app_shared` | Todo widget próprio | `no-magic-number`; Revisão |
| Versão do produto | `pubspec.yaml` do `studio_shell` | Método `getVersion`, tela Sobre, changelog | Constante gerada |
| Regras de análise e limites | Arquivo comum de análise | `analysis_options.yaml` de cada pacote | `include` |
| Versões de toolchain | `studio/flutter-version.txt` para o produto, `flutter-candidate.txt`, herdado, para o código herdado (ADR-0014), e `rust-toolchain.toml` | CI e ambiente local | Lidos pelo `st` |
| Grafia de termos e abreviações | `cspell.config.yaml` | Identificadores, comentários e documentos | QG-07 |
| Passos do portão | Comando `st verify` | Hook local e CI | O CI só chama `st verify` |
| Rastreabilidade entre requisito e teste | Comentários `// Verifies:` nos testes | Matriz por requisito (Verificação, 5) | `st trace` |
| Incremento em construção | `studio/current-increment.txt` | Requisitos que `st trace --check` exige com teste | Lido pelo `st` |

### 5.3 Código gerado

| ID | Regra | Verificação |
| --- | --- | --- |
| CS-DRY-012 | Arquivo gerado DEVE abrir com `// GENERATED CODE - DO NOT MODIFY BY HAND`, seguido da fonte e do gerador. NÃO DEVE ser editado à mão. | QG-09 |
| CS-DRY-013 | Código gerado DEVE ser versionado. O CI DEVE regenerá-lo e reprovar qualquer diferença. | QG-09 |
| CS-DRY-014 | Código gerado DEVE passar por formatação e análise. O gerador DEVE emitir os comentários de documentação a partir das descrições da fonte. | QG-01, QG-02, QG-09 |

Código gerado é versionado porque é compilado e lido em revisão. A diferença aparece no mesmo commit que a mudança da fonte.

### 5.4 Detecção

A duplicação textual é medida pelo PMD CPD, que cobre Dart e Rust, com limiar inicial de 100 tokens. Código próprio e herdado entram juntos na comparação; conta toda duplicata com ao menos uma ocorrência em código próprio.

A duplicação estrutural de funções, métodos, construtores e casos de teste é medida pelo `dcm check-code-duplication`, que resiste a renomeação de variáveis. Os limiares ficam em um arquivo só e mudam por ADR.

A dispensa de uma duplicata fica no registro da seção 9.4, com os dois locais. Os marcadores de supressão das próprias ferramentas, `CPD-OFF` e `ignore: code-duplication`, NÃO DEVEM ser usados.

## 6. Padrões de projeto: regras de dependência e catálogo

Um padrão de projeto entra quando o problema que ele resolve está presente no código, e entra com o nome consagrado. Esta seção fixa a direção das dependências, as regras de desenho e o catálogo dos padrões em uso.

### 6.1 Direção das dependências

*Diagrama: dependências entre pacotes · 8 pacotes, 3 processos à parte (disponível no documento original).*

O grafo tem um sentido só: o shell conhece todos, e o `studio_protocol` não conhece ninguém. Motor, agente e host rodam em outros processos e só compartilham o contrato.

| Pacote | Restrição além do grafo |
| --- | --- |
| `studio_protocol` | Só o SDK do Dart; nenhum pacote de terceiros |
| `studio_source_engine` | Sem Flutter (NFR-MNT-003); de terceiros, só o `analyzer` e seus pacotes de apoio |
| `studio_design_agent` | Só o SDK do Flutter, o `studio_protocol` e o `studio_package_assets`; roda dentro do app do usuário |
| `studio_package_assets` | Só o SDK do Flutter; importado pelo `studio_shell` e pelo `studio_design_agent` (ADR-0016, proposta) |
| `studio_core` | Do Flutter, importa só `foundation`; não importa `devtools_app` |
| `studio_shell` | Único pacote com widgets próprios e único que importa `devtools_app` |
| `studio_design_host` | Recebe o contrato como módulo gerado; não reimplementa lógica do Dart |
| `studio_tool` | Fora do produto entregue; nenhum pacote depende dele |

### 6.2 Regras de desenho

| ID | Regra | Verificação |
| --- | --- | --- |
| CS-DSN-001 | As dependências entre pacotes DEVEM seguir o grafo da seção 6.1, sem ciclo. Aresta nova exige ADR. | QG-03 (`avoid-banned-imports`, `check-dependencies`), QG-08 |
| CS-DSN-002 | Um pacote NÃO DEVE importar arquivo de `src/` de outro pacote. Código em `lib/src/` NÃO DEVE importar a biblioteca pública do próprio pacote. | QG-02 (`implementation_imports`), QG-03 (`avoid-importing-entrypoint-exports`) |
| CS-DSN-003 | Só o `DocumentStore` DEVE escrever em arquivo do projeto do usuário (ADR-0004). | QG-08 |
| CS-DSN-004 | JSON cru NÃO DEVE passar da borda. Os adaptadores de LSP, DAP e DTD convertem para tipos do domínio na entrada e na saída. | Revisão |
| CS-DSN-005 | Dependência DEVE entrar pelo construtor. Código próprio NÃO DEVE criar singleton, estado global mutável nem localizador de serviço. | QG-03 (`avoid-global-state`); Revisão |
| CS-DSN-006 | Os globais do upstream DEVEM ser lidos só na raiz de composição, o `main` do `studio_shell`, e repassados por construtor. | QG-08 |
| CS-DSN-007 | Estado de interface DEVE usar o mecanismo do upstream: `ValueNotifier` e `ValueListenable`, com descarte por `DisposableController`, `AutoDisposeControllerMixin` e `AutoDisposeMixin`. NÃO DEVE entrar biblioteca de gerência de estado. | QG-03 (`check-dependencies`); Revisão |
| CS-DSN-008 | Widget NÃO DEVE conter regra de edição, de seleção nem de protocolo: ele observa e chama um controlador. Auxiliar de interface é widget, não método que devolve widget. | Revisão |
| CS-DSN-009 | Tipo de valor DEVE ser imutável: campos `final`, construtor `const`, igualdade por valor. Conjunto fechado de variantes DEVE ser `sealed class` com `switch` exaustivo, sem `default`. | Revisão |
| CS-DSN-010 | Identificador de domínio NÃO DEVE circular como `String` ou `int` cru. `WidgetRef`, versão de documento e id de superfície são tipos próprios: extension type em Dart, newtype em Rust. | Revisão |
| CS-DSN-011 | Interface DEVE existir só em costura real: fronteira de processo, ferramenta externa, código herdado, variação já presente ou fake exigido por teste. | Revisão |
| CS-DSN-012 | Reuso DEVE ser por composição. Herança só onde o framework exige e em hierarquia `sealed`. | Revisão |
| CS-DSN-013 | Parâmetro booleano posicional NÃO DEVE existir. | QG-02 (`avoid_positional_boolean_parameters`) |
| CS-DSN-014 | Tipo que aplica um padrão do catálogo DEVE dizê-lo no seu comentário de documentação. Padrão fora do catálogo exige ADR. | Revisão |

### 6.3 Catálogo de padrões

| Problema presente no Studio | Padrão | Onde |
| --- | --- | --- |
| Toda edição precisa ser registrada, desfeita e refeita | Command | Operações de edição; pilha no `DocumentStore` |
| Uma edição passa por etapas fixas: calcular, sobrepor, validar, confirmar, recarregar | Pipes and Filters | `EditPipeline` (ADR-0007) |
| A mesma operação tem três formas de execução, conforme o que o servidor oferece | Strategy | Níveis de edição (ADR-0006) |
| O quadro chega por transportes diferentes, conforme o host | Strategy | `FrameTransport` (ADR-0009) |
| LSP, DAP e DTD falam JSON e têm ciclo de vida próprio | Adapter, no papel de Gateway | Clientes em `studio_core` |
| Os painéis herdados têm API que o núcleo não pode importar | Adapter | Adaptadores no `studio_shell` |
| Toda capacidade tem uma única porta de entrada | Facade | `StudioService` (ADR-0012) |
| Árvore, canvas, propriedades e código refletem a mesma seleção sem se conhecer | Mediator | `SelectionController` |
| Quem exibe estado precisa saber quando ele muda | Observer | `ValueListenable` e `Stream` |
| Processos filhos têm estados e transições definidos | State | `ToolchainSupervisor`, com `sealed class` |
| Percorrer e transformar a árvore sintática | Visitor | `studio_source_engine`, sobre os visitors do `analyzer` |
| Montar um `WorkspaceEdit` passo a passo, com imports | Builder | `studio_source_engine` |
| O histórico local precisa de armazenamento separado da lógica | Repository | Histórico em `.dart_tool/studio/history/` |
| Canal de plataforma sem implementação não pode derrubar o app | Null Object | `studio_design_agent` |
| Recurso do sistema precisa de liberação garantida | RAII em Rust, `dispose` em Dart | Memória compartilhada, texturas, processos |
| O código de um pacote pede assets por chaves que só valem quando ele é o aplicativo raiz | Decorator | `PackageAssetMessenger` (ADR-0015; ADR-0016, proposta) |

O vocabulário é o de Gamma et al. para Command, Strategy, Adapter, Facade, Mediator, Observer, State, Visitor, Builder e Decorator. Gateway e Repository vêm de Fowler; Pipes and Filters, de Buschmann et al.; Null Object, de Woolf.

## 7. Comentários

O comentário registra o que o código não consegue dizer: o motivo, a invariante, a restrição externa. O que o código faz é dito pelo próprio código, com nomes.

### 7.1 Regras

| ID | Regra | Verificação |
| --- | --- | --- |
| CS-CMT-001 | Comentário DEVE explicar por quê: decisão, invariante, pré-condição, restrição do SDK ou do protocolo, consequência de alterar. NÃO DEVE repetir o que a linha faz. | Revisão |
| CS-CMT-002 | Bloco que precisa de comentário para dizer o que faz DEVE virar função com nome. | Revisão |
| CS-CMT-003 | Comentário DEVE ser frase completa em inglês, com inicial maiúscula e ponto final. | QG-03 (`format-comment`), QG-07 |
| CS-CMT-004 | `//` é para comentário de implementação e `///` para documentação. Comentário de bloco `/* */` NÃO DEVE ser usado. | QG-02 (`slash_for_doc_comments`); Revisão |
| CS-CMT-005 | NÃO DEVEM existir: faixa decorativa, separador de seção, arte ASCII, nome de autor, data, histórico de alteração. | QG-10; Revisão |
| CS-CMT-006 | Comentário DEVE mudar no mesmo commit que o código a que se refere. Comentário desatualizado é defeito. | Revisão |
| CS-CMT-007 | Contorno de defeito externo DEVE citar a issue do projeto de origem e a condição de remoção. | QG-10; Revisão |
| CS-CMT-008 | Motivo de arquitetura NÃO DEVE ser explicado em comentário: cita-se `ADR-NNNN`. Requisito é citado pelo identificador. | Revisão |
| CS-CMT-009 | Só os marcadores da seção 7.2 DEVEM ser usados. | QG-10 |
| CS-CMT-010 | Arquivo herdado DEVE manter o cabeçalho de licença do upstream. Arquivo próprio DEVE levar o cabeçalho do projeto, de texto único. | QG-10 |

### 7.2 Marcadores padronizados

| Marcador | Uso | Forma |
| --- | --- | --- |
| `TODO` | Trabalho pendente, com dono e issue | `// TODO(username): message, https://URL-to-issue.` |
| `STUDIO-PATCH` | Trecho alterado em arquivo herdado | `// STUDIO-PATCH(n): reason`, na linha acima; `n` existe em `PATCHES.md` |
| `Verifies` | Requisitos cobertos por um teste | `// Verifies: FR-STR-002, NFR-REL-004` |
| `SAFETY` | Justificativa de um bloco `unsafe` | `// SAFETY: explanation`, na linha acima do bloco |
| `ignore` | Supressão em Dart | Linha de justificativa com `WVR-NNN`, seguida de `// ignore: code` |
| `expect` | Supressão em Rust | `#[expect(lint, reason = "WVR-NNN: explanation")]` |
| `GENERATED CODE` | Primeira linha de arquivo gerado | `// GENERATED CODE - DO NOT MODIFY BY HAND` |

### 7.3 Exemplo

O primeiro comentário repete a linha e sai. O segundo registra motivo e consequência e fica.

```dart
// Increment the version.
version++;

// A WidgetRef is valid for one document version only. Advancing the version
// first makes every ref computed before this edit fail with StaleDocument.
version++;
```

## 8. Documentação gerada

A referência de API é gerada do código e do contrato a cada versão; ninguém a escreve nem a corrige à mão. O que se escreve são os comentários de documentação, e eles têm regras.

### 8.1 Comentários de documentação

| ID | Regra | Verificação |
| --- | --- | --- |
| CS-DOC-001 | Toda declaração pública de pacote próprio DEVE ter comentário `///`. Em Rust, todo item público DEVE ter `///`, e o crate DEVE negar `missing_docs`. | QG-02 (`public_member_api_docs`), QG-05 |
| CS-DOC-002 | Membro privado DEVE ser documentado quando tem contrato que nome e tipo não mostram: invariante, ordem de chamada, posse de recurso, efeito colateral. Usa `///`, como no upstream. | Revisão |
| CS-DOC-003 | A primeira frase DEVE resumir a declaração e ficar em parágrafo próprio. Função com efeito começa por verbo na terceira pessoa; tipo, por sintagma nominal; booleano, por "Whether". | Revisão |
| CS-DOC-004 | O comentário NÃO DEVE repetir a assinatura. DEVE dizer o que ela não mostra: unidade, intervalo válido, sentido de `null`, quando o `Future` completa, o que lança, quem descarta. | Revisão |
| CS-DOC-005 | Parâmetros, retorno e exceções DEVEM ser explicados em prosa, com os identificadores entre colchetes. Toda referência DEVE resolver. | QG-02 (`comment_references`), QG-11 |
| CS-DOC-006 | Toda biblioteca pública DEVE ter comentário de biblioteca, e todo crate, documentação de crate com exemplo. O `README.md` do pacote é a página inicial da referência. | QG-11; Revisão |
| CS-DOC-007 | Em Rust, função que devolve `Result`, que pode entrar em pânico ou que é `unsafe` DEVE ter a seção `# Errors`, `# Panics` ou `# Safety`. | QG-05 (`missing_errors_doc`, `missing_panics_doc`, `missing_safety_doc`) |
| CS-DOC-008 | Exemplo em comentário de documentação DEVE compilar e declarar a linguagem do bloco. Em Rust é doctest; em Dart o bloco é extraído e analisado. | QG-02 (`missing_code_block_language_in_doc_comment`), QG-11 |
| CS-DOC-009 | Parágrafo repetido em mais de um comentário DEVE ser declarado uma vez com `{@template}` e reusado com `{@macro}`. O nome do template leva o prefixo do pacote. | Revisão |
| CS-DOC-010 | Tipo gerado DEVE receber o comentário da descrição que está na fonte. Método do serviço `Studio` DEVE ter descrição, parâmetros, erros e ao menos um exemplo no documento OpenRPC. | QG-09, QG-11 |

### 8.2 Geração e publicação

| Saída | Fonte | Ferramenta | Reprova quando |
| --- | --- | --- | --- |
| Referência Dart, por pacote | Comentários de documentação | `dart doc` | Há aviso do gerador, como referência não resolvida |
| Referência Rust | Comentários de documentação | `cargo doc --no-deps` | Há aviso do rustdoc |
| Referência do serviço `Studio` | `studio.openrpc.json` | `st docs` | Método sem descrição ou sem exemplo; exemplo que falha no teste de contrato |
| Matriz de rastreabilidade | Comentários `// Verifies:` | `st trace` | Identificador inexistente; requisito do incremento sem teste |

| ID | Regra | Verificação |
| --- | --- | --- |
| CS-DOC-011 | A saída gerada NÃO DEVE ser versionada nem editada à mão. `doc/api/` e `target/doc/` ficam no `.gitignore`. | QG-08 |
| CS-DOC-012 | A configuração do `dart doc` DEVE tratar os avisos como erro, ligar cada símbolo ao código-fonte na revisão exata e agrupar as bibliotecas pelos blocos da arquitetura. | QG-11 |
| CS-DOC-013 | A referência DEVE ser gerada e publicada pelo CI a cada versão e a cada commit do ramo principal. | QG-11 |

A documentação gerada não é versionada porque só é lida; o código gerado é, porque é compilado (CS-DRY-013).

### 8.3 Exemplo

O exemplo mostra a forma do comentário; a assinatura real pertence ao código.

```dart
/// Applies [edit] to the open documents as one undoable step.
///
/// Completes after the analysis server reports no new error for the edited
/// files. Throws [EditRejected] if validation fails; the documents are left
/// unchanged in that case.
Future<EditResult> apply(WorkspaceEdit edit);
```

## 9. Verificação e exceções

Uma mudança entra no ramo principal só com o portão inteiro aprovado e uma revisão feita por quem não é o autor. Não há passo opcional, nem aprovação que substitua um passo reprovado.

### 9.1 Portão de qualidade

O portão é um comando, `st verify`, do pacote `studio_tool`, escrito em Dart à imagem do `dt presubmit` do upstream. O hook local e o CI chamam esse comando; nenhum dos dois tem passo próprio.

| Passo | O que roda | Reprova quando |
| --- | --- | --- |
| QG-01 | `dart format --output=none --set-exit-if-changed` | Há arquivo Dart fora do formato |
| QG-02 | `dart analyze --fatal-infos`, com o arquivo comum de análise | Há qualquer diagnóstico |
| QG-03 | `dcm analyze`, `dcm check-unused-code`, `dcm check-unused-files`, `dcm check-dependencies` | Há regra violada, limite estourado, ou código, arquivo ou dependência sem uso |
| QG-04 | `cargo fmt --all -- --check` | Há arquivo Rust fora do formato |
| QG-05 | `cargo clippy --all-targets --all-features -- -D warnings` | Há qualquer aviso do compilador ou do Clippy |
| QG-06 | `pmd cpd` em Dart e em Rust; `dcm check-code-duplication` | Há duplicata sem dispensa com ocorrência em código próprio |
| QG-07 | `cspell` em código, comentários e fontes de documentação | Há palavra fora dos dicionários ou termo proibido |
| QG-08 | Verificação de estrutura do `st` | Aresta fora do grafo, import ou nome proibido, pacote fora da anatomia, teste fora do espelho, configuração duplicada, versão não fixada, `unsafe` ou escrita em arquivo fora do lugar permitido, saída gerada versionada |
| QG-09 | `st generate --check` | O código gerado difere do que a fonte produz, ou a fonte viola a convenção de nomes |
| QG-10 | Verificação de marcadores do `st` | `TODO` sem issue, marcador proibido, item provisório, cabeçalho ausente, literal de protocolo ou de interface, rodapé de atribuição nos commits |
| QG-11 | `dart doc` por pacote, `cargo doc --no-deps`, análise dos exemplos, `st docs` | Há aviso do gerador, exemplo que não compila ou método sem exemplo |
| QG-12 | `st trace --check` | Teste cita identificador inexistente, ou requisito do incremento está sem teste |
| QG-13 | Verificação de dispensas do `st` | Supressão sem `WVR`, dispensa vencida ou sem uso |

Os testes rodam no mesmo pipeline e estão descritos no plano de verificação.

### 9.2 Quando roda

1. `st verify --changed`, em hook de pre-commit: os passos rápidos, sobre os arquivos alterados.
2. `st verify`, completo, antes do push e em todo pull request.
3. O ramo principal é protegido: sem portão aprovado não há merge, e nenhum job tem falha permitida.

### 9.3 Revisão

A revisão cobre o que a ferramenta não mede. O revisor confirma cada item:

- Os nomes usam os termos do glossário e dizem o que a coisa é.
- Cada comentário explica um motivo; nenhum descreve a linha.
- Nenhum conhecimento novo ficou em dois lugares.
- Cada padrão usado resolve um problema presente, e cada interface está numa costura real.
- Os comentários de documentação dizem o que a assinatura não mostra.
- Cada teste cita o requisito e declara entradas e resultado esperado.
- Nenhuma dispensa nova entrou sem aprovação registrada.

### 9.4 Dispensas

A dispensa é a única forma de exceção, e fica registrada em `docs/engineering/waivers.md`.

| Campo | Conteúdo |
| --- | --- |
| Identificador | `WVR-NNN` |
| Regra | Identificador `CS-...` ou nome do diagnóstico suprimido |
| Local | Arquivo e símbolo; os dois locais, quando é duplicata |
| Justificativa | Por que a regra não pode ser cumprida ali |
| Aprovação | Dono do produto, com data |
| Validade | Data ou condição de remoção, como a correção de uma issue externa |

| ID | Regra | Verificação |
| --- | --- | --- |
| CS-GOV-001 | Toda exceção a regra deste documento DEVE estar no registro e ser citada no ponto do código. | QG-13 |
| CS-GOV-002 | Dispensa vencida, sem uso no código ou citada sem registro DEVE reprovar o portão. | QG-13 |
| CS-GOV-003 | A contagem de dispensas vigentes DEVE constar das notas de cada versão. A meta é zero. | Revisão |
| CS-GOV-004 | Regra e limite deste documento mudam só por ADR, com nova versão do documento. | Revisão |

### 9.5 Pendências

- Documento original de ascetismo, escrito para Rust: não estava disponível nesta versão. As seções 2 e 4.4 partem do princípio declarado; falta conferir com o original.
- Idioma de comentários e de comentários de documentação: inglês nesta versão; falta confirmar.
- Licença do DCM: o upstream roda a ferramenta no CI; falta confirmar se a licença dele cobre o fork e os pacotes `studio_*`. Sem licença, QG-03 e a parte estrutural de QG-06 não rodam.
- Licença do produto e texto do cabeçalho dos arquivos próprios (CS-CMT-010).
- Local de publicação da referência gerada (CS-DOC-013).
