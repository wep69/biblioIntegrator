# Annual bibliometric growth

Annual bibliometric growth

## Usage

``` r
temporal_growth(x)
```

## Arguments

- x:

  A `biblio_project`.

## Value

Annual documents, citations and year-over-year document growth.

## Examples

``` r
temporal_growth(as_biblio_project(example_biblio()))
#>   year documents citations growth_pct
#> 1 2017         1        55         NA
#> 2 2018         1        42          0
#> 3 2019         1        35          0
#> 4 2020         2        54        100
#> 5 2021         1        31        -50
#> 6 2022         2        39        100
#> 7 2023         1        18        -50
#> 8 2024         2        26        100
#> 9 2025         1         9        -50
tail(temporal_growth(as_biblio_project(example_biblio())),3)
#>   year documents citations growth_pct
#> 7 2023         1        18        -50
#> 8 2024         2        26        100
#> 9 2025         1         9        -50
summary(temporal_growth(as_biblio_project(example_biblio()))$documents)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   1.000   1.000   1.000   1.333   2.000   2.000 
```
