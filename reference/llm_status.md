# Check if LLM is configured and available

Checks whether the LLM provider is configured and accessible.

## Usage

``` r
llm_status(provider = NULL, verbose = TRUE)
```

## Arguments

- provider:

  Character. Provider to check. If NULL, uses current config.

- verbose:

  Logical. Print diagnostic messages. Default: TRUE.

## Value

Logical. TRUE if LLM is available.

## Examples

``` r
if (FALSE) { # \dontrun{
llm_status()
llm_status(provider = "ollama")
} # }
```
