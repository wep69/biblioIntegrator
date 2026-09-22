# Tutorial de Bibliometria Agrícola — biblioIntegrator

**O que é.** Tutorial progressivo de bibliometria aplicada à Agronomia para
doutorandos, construído sobre o pacote `biblioIntegrator`. Doze módulos cobrem as
59 funções exportadas, com três corpora (didático, simulado com verdades
plantadas e real obtido por API), figuras e tabelas interpretadas, tarefas em
três níveis e gabaritos comentados. O módulo 10 usa o pacote Python Biblium 2.16
para validação cruzada dos motores estatísticos.

## Arquivos

| Arquivo | Papel |
|---|---|
| `biblioIntegrator-agronomia.qmd` | documento principal (fonte única) |
| `biblioIntegrator-agronomia.html` | saída HTML autocontida, com sumário e busca |
| `biblioIntegrator-agronomia.pdf` | saída PDF (Typst) |
| `exercicios-aluno.R` | preparação dos dados e esqueletos das tarefas, **sem respostas** |
| `gabaritos/gNN-X.qmd` | um arquivo por exercício com o gabarito comentado |
| `_setup_corpora.R` | gera os três corpora e os objetos compartilhados |
| `_montar.R` | monta o documento, extrai os gabaritos e gera o arquivo do aluno |
| `_fragmentos/` | fontes por módulo (corpo e gabaritos) |
| `_cache/` | cache das chamadas de rede (OpenAlex) |
| `_auditoria/` | sondagens que fundamentam as afirmações do texto |

## Como gerar

```bash
# montar o documento a partir dos fragmentos
Rscript _montar.R

# renderizar as duas saídas
quarto render biblioIntegrator-agronomia.qmd --to html
quarto render biblioIntegrator-agronomia.qmd --to typst
```

## Requisitos

- R 4.6 ou superior, com `biblioIntegrator`, `ggplot2` e `igraph`.
- Opcionais: `arrow` e `duckdb` (Módulo 8), `reticulate` mais um Python com
  `biblium==2.16.0` (Módulo 10), servidor LLM (Módulo 11).
- Para o Módulo 10, aponte o interpretador antes de renderizar:

```bash
set BIBLIOINTEGRATOR_PYTHON=C:\caminho\para\python.exe   # Windows
export BIBLIOINTEGRATOR_PYTHON=/caminho/para/python      # Linux/macOS
```

Se nenhum Python com Biblium estiver disponível, os trechos do Módulo 10
mostram a mensagem de indisponibilidade e o documento continua íntegro.

## Reprodutibilidade

Todas as simulações usam a semente `2026`. **Nenhum número de resultado está
digitado na prosa**: todos são calculados no momento da renderização, de modo que
alterar a semente ou o gerador atualiza o texto automaticamente. As chamadas de
rede ficam em `_cache/`, portanto a segunda renderização não depende de conexão.

## Verdades plantadas no corpus simulado

| Código | Verdade | Verificada em |
|---|---|---|
| V1 | três temas latentes com pesos desiguais | Módulos 5 e 6 |
| V2 | duas fontes com bônus de citações | Módulo 3 |
| V3 | metade das obras com coautoria internacional | Módulos 3 e 7 |
| V4 | termos de automação concentrados a partir de 2020 | Módulos 4 e 6 |
| V5 | autor central articulando a rede | Módulo 7 |
| V6 | três duplicatas plantadas e defeitos de metadados | Módulo 2 |
| V7 | três laboratórios com padrão de coautoria próprio | Módulo 7 |

O Módulo 2 mostra um caso em que a rotina automática de deduplicação **não**
resolve todos os casos plantados, e explica a causa: a chave de comparação é o
DOI quando ele existe e o par título-ano quando ele falta, de modo que um
registro sem DOI não casa com o seu gêmeo que tem DOI. Esse é um achado
deliberado do material, e não uma falha escondida.

## Auditoria

As afirmações do tutorial vêm de sondagens executadas e guardadas em
`_auditoria/`, incluindo: inventário de `formals()` das 59 funções, verificação
de que as receitas de chamada rodam sem erro, e o teste de que apenas as funções
com argumento `seed` interferem no gerador aleatório do usuário.

## Publicação no site do pacote (pkgdown)

O tutorial também é um **artigo do site** do pacote, publicado em

<https://wep69.github.io/biblioIntegrator/articles/biblioIntegrator-agronomia.html>

A fonte do artigo no repositório é `vignettes/articles/biblioIntegrator-agronomia.qmd`
(mesmo conteúdo do tutorial montado, com YAML próprio de artigo) e o cache de
rede fica em `vignettes/articles/_cache/`. A pasta do artigo é excluída do
tarball por `.Rbuildignore` (`^vignettes/articles$`), como manda a convenção do
pkgdown para artigos que não são vinhetas.

### Como o artigo é montado

1. `_montar.R` gera `biblioIntegrator-agronomia.qmd` a partir de `_fragmentos/`.
2. `_auditoria/_preparar_artigo.R` converte esse documento na versão de artigo
   (YAML de artigo e cache dentro da pasta do artigo).
3. O build do site roda `pkgdown::build_site()` com o remendo
   `tools/pkgdown-patch.R` carregado antes.

### Remendo obrigatório do pkgdown

`tools/pkgdown-patch.R` corrige dois defeitos do pkgdown na renderização de
artigos Quarto. Sem ele, qualquer artigo `.qmd` faz o build do site falhar, e a
única pista é `System command 'quarto' failed`:

| Defeito | Sintoma | Correção no remendo |
|---|---|---|
| Booleanos do YAML | `Aeson exception: Error in $: expected Bool, but encountered String` | `yaml::write_yaml()` emite `yes`/`no` (YAML 1.1) e o Quarto lê `yes`/`no` como texto; o remendo converte para `true`/`false` |
| Caminho de saída | `os error 123: stat '...\vignettes\C:\Users\...'` (Windows) ou `No built file found` | o Quarto resolve `--output-dir` relativo à raiz do projeto; o remendo usa `<projeto>/.pkgdown-quarto-tmp` com caminho relativo e localiza o HTML gerado |

### Requisito do Módulo 10

O artigo executa o Módulo 10 de verdade, e para isso precisa de um interpretador
Python com `biblium==2.16.0`. Configure antes do build:

```bash
set BIBLIOINTEGRATOR_PYTHON=C:\caminho\para\python.exe   # Windows
export BIBLIOINTEGRATOR_PYTHON=/caminho/para/python      # Linux/macOS
```

Sem esse interpretador, o build do artigo PARA na chamada
`biblium_compare_groups()` com a mensagem
`Biblium 2.16 backend is unavailable or not importable.` — as demais vinhetas do
site continuam sendo construídas normalmente.

