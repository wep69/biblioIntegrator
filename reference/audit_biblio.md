# Inspect the provenance log

Inspect the provenance log

## Usage

``` r
audit_biblio(x)
```

## Arguments

- x:

  A `biblio_project`.

## Value

A data frame.

## Examples

``` r
audit_biblio(as_biblio_project(example_biblio()))
#>                   timestamp         operation           details
#> 1 2026-08-23 13:28:31.76012 as_biblio_project source=user; n=12
nrow(audit_biblio(as_biblio_project(head(example_biblio()))))
#> [1] 1
names(audit_biblio(as_biblio_project(example_biblio())))
#> [1] "timestamp" "operation" "details"  
```
