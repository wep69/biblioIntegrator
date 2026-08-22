# Fetch OpenCitations Index relations

Fetch OpenCitations Index relations

## Usage

``` r
fetch_opencitations(identifier, direction = c("citations", "references"))
```

## Arguments

- identifier:

  DOI or supported persistent identifier.

- direction:

  `"citations"` or `"references"`.

## Value

A data frame returned by the OpenCitations API.

## Examples

``` r
if (FALSE) { # \dontrun{
fetch_opencitations("10.1038/nature12373")
fetch_opencitations("10.1038/nature12373",direction="references")
head(fetch_opencitations("10.1038/nature12373"))
} # }
```
