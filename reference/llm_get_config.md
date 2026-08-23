# Get current LLM configuration

Returns the current LLM provider configuration set by
[`llm_configure`](https://wep69.github.io/biblioIntegrator/reference/llm_configure.md).

## Usage

``` r
llm_get_config()
```

## Value

List with current LLM configuration, or NULL if not configured.

## Examples

``` r
llm_get_config()
#> NULL
```
