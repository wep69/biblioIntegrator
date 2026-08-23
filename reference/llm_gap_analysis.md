# Identify research gaps using LLM

Analyzes the corpus to identify understudied areas, methodological gaps,
or geographic biases.

## Usage

``` r
llm_gap_analysis(x, focus = "thematic", provider = NULL, model = NULL)
```

## Arguments

- x:

  A `biblio_project`.

- focus:

  Character. Analysis focus: "thematic", "methodological", "geographic",
  or "temporal".

- provider:

  Character. LLM provider override.

- model:

  Character. Model override.

## Value

A data frame with columns: gap, evidence, impact, suggestion.

## Examples

``` r
if (FALSE) { # \dontrun{
llm_configure(provider = "ollama")
x <- as_biblio_project(example_biblio())
gaps <- llm_gap_analysis(x, focus = "thematic")
print(gaps)
} # }
```
