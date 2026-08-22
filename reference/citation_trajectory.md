# Citation trajectory

Citation trajectory

## Usage

``` r
citation_trajectory(x, current_year = as.integer(format(Sys.Date(), "%Y")))
```

## Arguments

- x:

  A `biblio_project`.

- current_year:

  Reference year.

## Value

Work-level age, citations and velocity.

## Examples

``` r
citation_trajectory(as_biblio_project(example_biblio()))
#>      work_id                                  title year age citations velocity
#> 1  W0001f7e3 Silicon and salinity tolerance in rice 2018   9        42 4.666667
#> 2  W000160f5          Soil carbon under cover crops 2019   8        35 4.375000
#> 3  W0001b6e0     Remote sensing of soybean nitrogen 2020   7        28 4.000000
#> 4  W0001b6e2     Silicon nutrition in maize drought 2021   6        31 5.166667
#> 5  W0001932e       Cover crops and soil aggregation 2022   5        22 4.400000
#> 6  W00017da4        Machine learning for crop yield 2023   4        18 4.500000
#> 7  W00014309            Salinity responses of wheat 2017  10        55 5.500000
#> 8  W000176af         Soil microbiome under rotation 2020   7        26 3.714286
#> 9  W000134bf             UAV phenotyping of soybean 2024   3        12 4.000000
#> 10 W00018e53        Meta-analysis of silicon stress 2025   2         9 4.500000
#> 11 W000196f7       Nitrogen use efficiency in maize 2022   5        17 3.400000
#> 12 W00016cdd          Climate-smart soil management 2024   3        14 4.666667
head(citation_trajectory(as_biblio_project(example_biblio())),3)
#>     work_id                                  title year age citations velocity
#> 1 W0001f7e3 Silicon and salinity tolerance in rice 2018   9        42 4.666667
#> 2 W000160f5          Soil carbon under cover crops 2019   8        35 4.375000
#> 3 W0001b6e0     Remote sensing of soybean nitrogen 2020   7        28 4.000000
citation_trajectory(as_biblio_project(example_biblio()),current_year=2026)
#>      work_id                                  title year age citations velocity
#> 1  W0001f7e3 Silicon and salinity tolerance in rice 2018   9        42 4.666667
#> 2  W000160f5          Soil carbon under cover crops 2019   8        35 4.375000
#> 3  W0001b6e0     Remote sensing of soybean nitrogen 2020   7        28 4.000000
#> 4  W0001b6e2     Silicon nutrition in maize drought 2021   6        31 5.166667
#> 5  W0001932e       Cover crops and soil aggregation 2022   5        22 4.400000
#> 6  W00017da4        Machine learning for crop yield 2023   4        18 4.500000
#> 7  W00014309            Salinity responses of wheat 2017  10        55 5.500000
#> 8  W000176af         Soil microbiome under rotation 2020   7        26 3.714286
#> 9  W000134bf             UAV phenotyping of soybean 2024   3        12 4.000000
#> 10 W00018e53        Meta-analysis of silicon stress 2025   2         9 4.500000
#> 11 W000196f7       Nitrogen use efficiency in maize 2022   5        17 3.400000
#> 12 W00016cdd          Climate-smart soil management 2024   3        14 4.666667
```
