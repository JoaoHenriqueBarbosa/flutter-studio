# Studio

Editor visual de Flutter, escrito em Flutter, que renderiza o código do projeto como está e grava cada alteração nos próprios arquivos. O repositório está na baseline de projeto: os documentos em `docs/` são especificação a implementar, não descrição de software pronto.

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
