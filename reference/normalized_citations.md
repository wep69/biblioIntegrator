# Field/year normalized citations

Field/year normalized citations

## Usage

``` r
normalized_citations(x, strata = "year")
```

## Arguments

- x:

  A `biblio_project`.

- strata:

  Character columns in `works` defining comparable strata.

## Value

Work-level normalized citation scores.

## Examples

``` r
normalized_citations(as_biblio_project(example_biblio()))
#>      work_id citations expected normalized
#> 1  W0001f7e3        42     42.0  1.0000000
#> 2  W000160f5        35     35.0  1.0000000
#> 3  W0001b6e0        28     27.0  1.0370370
#> 4  W0001b6e2        31     31.0  1.0000000
#> 5  W0001932e        22     19.5  1.1282051
#> 6  W00017da4        18     18.0  1.0000000
#> 7  W00014309        55     55.0  1.0000000
#> 8  W000176af        26     27.0  0.9629630
#> 9  W000134bf        12     13.0  0.9230769
#> 10 W00018e53         9      9.0  1.0000000
#> 11 W000196f7        17     19.5  0.8717949
#> 12 W00016cdd        14     13.0  1.0769231
head(normalized_citations(as_biblio_project(example_biblio())),4)
#>     work_id citations expected normalized
#> 1 W0001f7e3        42       42   1.000000
#> 2 W000160f5        35       35   1.000000
#> 3 W0001b6e0        28       27   1.037037
#> 4 W0001b6e2        31       31   1.000000
mean(normalized_citations(as_biblio_project(example_biblio()))$normalized,na.rm=TRUE)
#> [1] 1
```
