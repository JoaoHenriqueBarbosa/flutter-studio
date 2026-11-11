# ADR-0015: Assets e fontes do código herdado resolvidos no binding do shell

Estado: proposta.

## Contexto e problema

O `devtools_app` carrega imagens, a gramática de realce e fontes pelas chaves que eles têm quando o pacote é o aplicativo raiz: `assets/dart_syntax.json`, `icons/...`, família `RobotoMono`. O shell é outro aplicativo, que usa o `devtools_app` como dependência (seção 6.1 do padrão de código), e nesse caso a ferramenta do Flutter empacota os mesmos arquivos sob `packages/devtools_app/` e registra as famílias com esse prefixo. Sem tratamento, o shell compila e cai na partida. São 12 pontos de carga de asset e três famílias de fonte no commit base.

Há três caminhos de carga, e cada um passa por um lugar diferente do framework: `rootBundle.load`, pelo canal `flutter/assets` do mensageiro binário; `AssetImage`, pelo `DefaultAssetBundle` e daí direto ao engine; e as fontes, pelo manifesto lido pelo engine.

## Opções consideradas

1. Patch em cada ponto de carga do código herdado.
2. O runner de plataforma mora no `devtools_app`, que continua sendo o aplicativo raiz.
3. Copiar os assets para o `studio_shell` no build.
4. Resolver no shell, em tempo de execução, por um binding próprio.

## Decisão

Opção 4. O `StudioWidgetsBinding` substitui o mensageiro binário por um decorador, o `InheritedAssetMessenger`, que repete com o prefixo do pacote o pedido de asset que não achou nada. O mesmo binding envolve a raiz num `DefaultAssetBundle` que lê imagens pelo mensageiro. O `InheritedFontRegistry` lê o manifesto de fontes na partida e carrega de novo cada família do pacote sob o nome sem prefixo.

O código herdado recebe um único patch, o `STUDIO-PATCH(2)`: `runDevTools` e `setupErrorHandling` aceitam a função que inicializa o binding, porque o binding precisa nascer dentro da zona que `setupErrorHandling` cria.

O padrão Decorator, de Gamma et al., entra no catálogo da seção 6.3 do padrão de código para este caso.

A opção 1 espalha patches por 12 pontos que o upstream muda com frequência. A opção 2 inverte o grafo de dependências e deixa de fora os assets e os plugins do próprio shell. A opção 3 duplica arquivos e a lista de assets.

## Consequências

- Bom: um patch pequeno e estável no código herdado; ponto de carga novo no upstream funciona sem mudança; os assets do próprio shell têm precedência, porque o prefixo só é tentado depois da falha.
- Ruim: cada asset herdado custa dois pedidos ao engine no primeiro acesso; as variantes de resolução (`2.0x`) dos assets herdados não são escolhidas pelo manifesto, e hoje o DevTools não as usa; o shell depende de dois pontos de extensão do binding, `createBinaryMessenger` e `wrapWithDefaultView`.

## Confirmação

NFR-FLEX-002; testes de unidade em `studio_shell/test/inherited_assets/`; a cada rebase, o shell abre sem erro de asset.
