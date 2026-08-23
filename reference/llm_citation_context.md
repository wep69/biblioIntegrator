# Analyze citation context using LLM

Classifies the context in which works are cited (support, contrast,
method, background, extension).

## Usage

``` r
llm_citation_context(x, text = NULL, provider = NULL, model = NULL)
```

## Arguments

- x:

  A `biblio_project`.

- text:

  Character. Text containing citations to analyze. If NULL, uses
  abstracts from the corpus.

- provider:

  Character. LLM provider override.

- model:

  Character. Model override.

## Value

A data frame with columns: cited_id, context_type, snippet, explanation.

## Examples

``` r
if (FALSE) { # \dontrun{
llm_configure(provider = "ollama")
x <- as_biblio_project(example_biblio())
contexts <- llm_citation_context(x)
print(contexts)
} # }
```
