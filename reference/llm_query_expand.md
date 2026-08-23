# Expand search query using LLM

Uses an LLM to expand a search query with synonyms, related terms, and
Boolean operators optimized for a specific database.

## Usage

``` r
llm_query_expand(query, database = "openalex", provider = NULL, model = NULL)
```

## Arguments

- query:

  Character. Original search query.

- database:

  Character. Target database: "scopus", "wos", "openalex", "pubmed", or
  "generic".

- provider:

  Character. LLM provider override.

- model:

  Character. Model override.

## Value

A list with: expanded_query, added_terms, explanation.

## Examples

``` r
if (FALSE) { # \dontrun{
llm_configure(provider = "ollama")
result <- llm_query_expand("soil carbon sequestration",
                           database = "openalex")
cat(result$expanded_query)
} # }
```
