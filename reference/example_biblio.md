# Example bibliographic corpus

Returns a small agronomy-oriented corpus used in examples and tests.

## Usage

``` r
example_biblio()
```

## Value

A data frame.

## Examples

``` r
d <- example_biblio(); head(d)
#>                                    title year            doi            authors
#> 1 Silicon and salinity tolerance in rice 2018 10.1000/agri.1 Silva A; Pereira W
#> 2          Soil carbon under cover crops 2019 10.1000/agri.2 Martins B; Costa C
#> 3     Remote sensing of soybean nitrogen 2020 10.1000/agri.3  Lima D; Pereira W
#> 4     Silicon nutrition in maize drought 2021 10.1000/agri.4   Silva A; Gomez E
#> 5       Cover crops and soil aggregation 2022 10.1000/agri.5  Martins B; Lima D
#> 6        Machine learning for crop yield 2023 10.1000/agri.6     Costa C; Rao F
#>                            keywords citations               source
#> 1           silicon; salinity; rice        42          Field Crops
#> 2          soil carbon; cover crops        35         Soil Science
#> 3 remote sensing; soybean; nitrogen        28       Remote Sensing
#> 4           silicon; drought; maize        31      Plant Nutrition
#> 5    cover crops; aggregation; soil        22         Soil Science
#> 6           machine learning; yield        18 Agricultural Systems
nrow(example_biblio())
#> [1] 12
names(example_biblio())
#> [1] "title"     "year"      "doi"       "authors"   "keywords"  "citations"
#> [7] "source"   
```
