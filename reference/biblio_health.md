# Diagnose corpus quality

Diagnose corpus quality

## Usage

``` r
biblio_health(x)
```

## Arguments

- x:

  A `biblio_project`.

## Value

A data frame of checks and counts.

## Examples

``` r
biblio_health(as_biblio_project(example_biblio()))
#>                  check n
#> 1        missing_title 0
#> 2         missing_year 0
#> 3          missing_doi 0
#> 4        duplicate_doi 0
#> 5 duplicate_title_year 0
#> 6   negative_citations 0
biblio_health(as_biblio_project(head(example_biblio())))
#>                  check n
#> 1        missing_title 0
#> 2         missing_year 0
#> 3          missing_doi 0
#> 4        duplicate_doi 0
#> 5 duplicate_title_year 0
#> 6   negative_citations 0
subset(biblio_health(as_biblio_project(example_biblio())), n>0)
#> [1] check n    
#> <0 rows> (or 0-length row.names)
```
