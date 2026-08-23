# Discover research topics using LLM

Uses an LLM to identify distinct research themes in the corpus without
requiring a predefined number of topics.

## Usage

``` r
llm_topic_discovery(x, n_topics = NULL, provider = NULL, model = NULL)
```

## Arguments

- x:

  A `biblio_project`.

- n_topics:

  Integer or NULL. Suggested number of topics. NULL = auto.

- provider:

  Character. LLM provider override.

- model:

  Character. Model override.

## Value

A list with: topics (data frame), raw_response.

## Examples

``` r
if (FALSE) { # \dontrun{
llm_configure(provider = "ollama")
x <- as_biblio_project(example_biblio())
topics <- llm_topic_discovery(x, n_topics = 3)
print(topics$topics)
} # }
```
