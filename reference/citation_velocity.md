# Citation velocity

Citation velocity

## Usage

``` r
citation_velocity(x, current_year = as.integer(format(Sys.Date(), "%Y")))
```

## Arguments

- x:

  A `biblio_project`.

- current_year:

  Reference year.

## Value

Work-level citations per year.

## Examples

``` r
citation_velocity(as_biblio_project(example_biblio()))
#>      work_id year citations velocity
#> 1  W0001f7e3 2018        42 4.666667
#> 2  W000160f5 2019        35 4.375000
#> 3  W0001b6e0 2020        28 4.000000
#> 4  W0001b6e2 2021        31 5.166667
#> 5  W0001932e 2022        22 4.400000
#> 6  W00017da4 2023        18 4.500000
#> 7  W00014309 2017        55 5.500000
#> 8  W000176af 2020        26 3.714286
#> 9  W000134bf 2024        12 4.000000
#> 10 W00018e53 2025         9 4.500000
#> 11 W000196f7 2022        17 3.400000
#> 12 W00016cdd 2024        14 4.666667
head(citation_velocity(as_biblio_project(example_biblio())),3)
#>     work_id year citations velocity
#> 1 W0001f7e3 2018        42 4.666667
#> 2 W000160f5 2019        35 4.375000
#> 3 W0001b6e0 2020        28 4.000000
summary(citation_velocity(as_biblio_project(example_biblio()))$velocity)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   3.400   4.000   4.450   4.407   4.667   5.500 
```
