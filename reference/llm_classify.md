# Classify works into thematic categories using LLM

Assigns each work in the corpus to one or more user-defined (or
LLM-suggested) categories.

## Usage

``` r
llm_classify(x, categories = NULL, provider = NULL, model = NULL)
```

## Arguments

- x:

  A `biblio_project`.

- categories:

  Character vector. Categories to use. If NULL, the LLM will suggest
  categories.

- provider:

  Character. LLM provider override.

- model:

  Character. Model override.

## Value

A data frame with columns: work_id, title, primary, secondary,
confidence, reason.

## Examples

``` r
if (FALSE) { # \dontrun{
llm_configure(provider = "ollama")
x <- as_biblio_project(example_biblio())
classified <- llm_classify(x, categories = c("Agronomy", "Ecology"))
print(classified)
} # }
```
