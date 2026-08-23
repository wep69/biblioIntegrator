# Summarize corpus using LLM

Generates an intelligent summary of the bibliographic corpus,
synthesizing across works rather than listing them.

## Usage

``` r
llm_summarize(
  x,
  work_ids = NULL,
  style = "executive",
  provider = NULL,
  model = NULL
)
```

## Arguments

- x:

  A `biblio_project`.

- work_ids:

  Character vector. Specific work IDs to summarize.

- style:

  Character. Summary style: "executive", "methods", "gaps", or
  "comprehensive".

- provider:

  Character. LLM provider override.

- model:

  Character. Model override.

## Value

Character. The generated summary text.

## Examples

``` r
if (FALSE) { # \dontrun{
llm_configure(provider = "ollama")
x <- as_biblio_project(example_biblio())
summary <- llm_summarize(x, style = "executive")
cat(summary)
} # }
```
