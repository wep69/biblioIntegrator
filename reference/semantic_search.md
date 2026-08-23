# Semantic search in bibliographic corpus

Uses an LLM to find works relevant to a natural language query, going
beyond keyword matching to understand meaning and context.

## Usage

``` r
semantic_search(x, query, n = 10, provider = NULL, model = NULL, api_key = NULL)
```

## Arguments

- x:

  A `biblio_project`.

- query:

  Character. Natural language search query.

- n:

  Integer. Maximum number of results. Default: 10.

- provider:

  Character. LLM provider override.

- model:

  Character. Model override.

- api_key:

  Character. API key override.

## Value

A data frame with columns: work_id, title, score, reason.

## Examples

``` r
if (FALSE) { # \dontrun{
llm_configure(provider = "ollama")
x <- as_biblio_project(example_biblio())
results <- semantic_search(x, "sustainable agriculture")
head(results)
} # }
```
