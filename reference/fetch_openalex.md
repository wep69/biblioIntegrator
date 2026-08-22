# Fetch works from OpenAlex

Fetch works from OpenAlex

## Usage

``` r
fetch_openalex(query, n = 25, mailto = NULL)
```

## Arguments

- query:

  Search string.

- n:

  Maximum records requested.

- mailto:

  Optional contact email for polite API use.

## Value

A `biblio_project`.

## Examples

``` r
if (FALSE) { # \dontrun{
fetch_openalex("silicon salinity plants",n=10)
fetch_openalex("soil carbon cover crops",n=5)
x <- fetch_openalex("soybean remote sensing",n=3); x$works
} # }
```
