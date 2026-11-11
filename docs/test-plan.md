# Plano de verificação

Como cada requisito do Studio é verificado, na estrutura de plano de teste da ISO/IEC/IEEE 29119-3. Versão 0.2, rascunho para revisão.

## 1. Escopo, itens de teste e abordagem

Este plano cobre todos os requisitos do SRS. Os itens de teste são os pacotes `studio_*`, o contrato do serviço `Studio` e o código herdado do DevTools com seus patches.

| Nível | O que exercita | Quando roda | Requisitos típicos |
| --- | --- | --- | --- |
| Unidade | Operações do `studio_source_engine` e o `DocumentStore`, sem processos externos | A cada commit | FR-DOC, FR-STR, FR-PRP-004 |
| Widget | Painéis do shell com serviços simulados | A cada commit | FR-INS-003, NFR-INTR-004 |
| Herdado | Os testes do DevTools | A cada commit e a cada rebase | NFR-MNT-004 |
| Contrato | Cada método e cada erro do serviço `Studio` contra o documento OpenRPC; cada elemento consumido do SDK | A cada commit, em toda a matriz de SDKs | FR-API, IR, RSK-01 |
| Sistema | O Studio completo, sem interface gráfica, dirigido pelo serviço `Studio` sobre os projetos de referência | A cada commit, em toda a matriz | FR-PRJ, FR-CNV, FR-HST, FR-RUN |
| Qualidade | Latência, caos e auto-hospedagem | Diariamente | NFR-PERF, NFR-REL |
| Usabilidade | Tarefa cronometrada com participantes | Por incremento, a partir de F4 | NFR-INTR-006 |

Nenhum teste de sistema clica em pixel. A interface gráfica usa a mesma API (FR-API-002), então exercitar a API exercita o comportamento.

## 2. Oráculos

Um oráculo é um procedimento automático com critério de aprovação fixo. Cada um responde por uma propriedade do sistema.

| ID | Propriedade | Procedimento | Critério |
| --- | --- | --- | --- |
| ORC-01 | Corpus: as operações de edição não quebram código real | Para cada local de criação de widget do corpus, aplicar cada operação aplicável | O arquivo é sintaticamente válido, os diagnósticos não aumentam e a operação inversa restaura os bytes. Meta para liberar F3: 100 mil aplicações sem violação |
| ORC-02 | Diferencial: o motor concorda com o analysis server | Onde existe assist do servidor para a operação, executar as duas implementações | Resultados idênticos byte a byte |
| ORC-03 | Junção: o local de criação cai no nó certo | Para cada elemento do projeto na árvore em execução, resolver o local na árvore de fonte e comparar a classe | 99,9% ou mais; cada exceção catalogada por causa |
| ORC-04 | Pixels: o canvas mostra o que o engine produz | Comparar o quadro recebido pelo shell com a imagem de referência do `flutter test` para a mesma superfície e configuração | Igualdade de pixels no host sem toolchain |
| ORC-05 | Latência | Medir, com o relógio do shell, do evento de entrada ao quadro exibido, 200 repetições por cenário | Limites de NFR-PERF-001 a 005 |
| ORC-06 | Caos | Matar o app alvo, o analysis server e o daemon em momentos sorteados; gravar arquivos por fora durante edições; submeter edições inválidas | NFR-REL-001 a 003 e FR-STR-008 valem em todas as execuções |
| ORC-07 | Auto-hospedagem | O Studio abre o próprio repositório, altera uma propriedade da própria barra de ferramentas e recarrega | A sessão continua operante e o diff é o esperado |
| ORC-08 | Desfazer exato | Sequência sorteada de operações, depois desfazer tudo | Hash de cada arquivo igual ao inicial |
| ORC-09 | Projeto intocado | Abrir um projeto, navegar, abrir superfícies e fechar, sem editar | Nenhuma diferença no diretório do projeto fora de `.dart_tool/` |
| ORC-10 | Contrato | Validar requisições e respostas reais contra o documento OpenRPC | Nenhuma divergência de esquema |
| ORC-11 | Portão de qualidade: o código cumpre o Padrão de código | Executar `st verify` sobre o repositório inteiro, em cada pull request e em cada versão | Passos QG-01 a QG-13 aprovados; nenhuma dispensa vencida |

## 3. Ambiente

| Dimensão | Valores |
| --- | --- |
| Sistemas | Windows x64, macOS arm64 e Linux x64 |
| SDKs Flutter | As quatro versões estáveis mais recentes na data da execução |
| Máquina de referência | 8 núcleos, 16 GB de memória, SSD e GPU integrada. Modelo a fixar em F0 |
| Projeto de referência pequeno | Até 50 arquivos Dart, com 10 telas. Repositório e commit a fixar em F0 |
| Projeto de referência grande | O pacote `devtools_app`, cerca de 115 mil linhas |
| Corpus | Projetos Flutter abertos, fixados por commit, incluído o DevTools. Lista a fixar em F0 |

O que está marcado como a fixar é decidido no incremento F0 e registrado neste documento por mudança de versão.

## 4. Critérios de saída por incremento

Um incremento só é aceito quando seu critério é satisfeito e os dos incrementos anteriores continuam satisfeitos.

| Incremento | Critério de saída |
| --- | --- |
| F0 Fundação | Em toda a matriz: abrir um projeto, iniciar o app pelo adaptador de debug e ver os painéis herdados conectados. Testes herdados passando. Premissas ASM-01 a ASM-08 respondidas e registradas. ORC-11 aprovado, e assim em todo incremento seguinte |
| F1 Inspetor que escreve | Num app em execução em dispositivo físico: alterar uma propriedade e envolver um widget sem abrir o código. ORC-03, ORC-08 e ORC-09 aprovados |
| F2 Canvas | ORC-04 e ORC-05 aprovados no host sem toolchain. FR-CNV-008 e FR-CNV-009 demonstrados |
| F3 Motor estrutural | ORC-01 na meta. ORC-02, ORC-06 e ORC-10 aprovados |
| F4 Ambiente completo | ORC-07 aprovado. Um cadastro com listagem, inclusão, alteração e exclusão criado do zero sem sair do Studio. QS-06 medido com cinco participantes |
| F5 Host próprio | NFR-PERF-005 atendido no host nativo, em máquina sem toolchain nativo instalado. NFR-SEC-004 testado |
| F6 Alcance | Serviço `Studio` exercitado de ponta a ponta por um cliente MCP |

## 5. Matriz de rastreabilidade

Por grupo de requisitos. A matriz por requisito individual é gerada dos comentários `// Verifies:` e publicada pelo CI.

| Requisitos | Método | Verificação |
| --- | --- | --- |
| FR-PRJ | T | Testes de sistema; ORC-09 |
| FR-DOC | T, I | Testes de unidade do `DocumentStore`; ORC-08; ORC-01 para FR-DOC-007 a 009 |
| FR-INS | T | Testes de sistema; ORC-03 |
| FR-PRP | T, D | Testes de contrato de `editArgument`; ORC-01 para objetos compostos |
| FR-STR, FR-PAL | T, I | ORC-01, ORC-02 e ORC-06 |
| FR-CNV, FR-HST | T, I | ORC-04, ORC-05 e ORC-06 |
| FR-COD, FR-EVT | T, D | Testes de widget e de sistema; ORC-01 para a criação de tratador |
| FR-RUN | T, D | Testes de sistema sobre o adaptador de debug |
| FR-API | T, I | ORC-10; inspeção de FR-API-002 |
| NFR-PERF | T | ORC-05 |
| NFR-INTR | I, D | Inspeção; teste de usabilidade (QS-06) |
| IR | T | Testes de contrato na matriz de SDKs |
| NFR-DATA, DC | I, T | Inspeção; ORC-09 |
| NFR-REL | T | ORC-06 e ORC-08 |
| NFR-SEC | T, D | Testes de recusa (QS-11); demonstração de NFR-SEC-001 |
| NFR-MNT | I, T | Inspeção de `PATCHES.md`; testes herdados; ORC-11 para NFR-MNT-005 a 008 |
| NFR-FLEX, NFR-COMP | T | Matriz de SDKs e de sistemas; ORC-06 para a coexistência |
