# Create a Biblium-ready data frame

Create a Biblium-ready data frame

## Usage

``` r
to_biblium(x)
```

## Arguments

- x:

  A `biblio_project`.

## Value

A data frame with Biblium canonical field names.

## Examples

``` r
to_biblium(as_biblio_project(example_biblio()))
#>                                     Title Year              Authors
#> 1  Silicon and salinity tolerance in rice 2018   Silva A; Pereira W
#> 2           Soil carbon under cover crops 2019   Martins B; Costa C
#> 3      Remote sensing of soybean nitrogen 2020    Lima D; Pereira W
#> 4      Silicon nutrition in maize drought 2021     Silva A; Gomez E
#> 5        Cover crops and soil aggregation 2022    Martins B; Lima D
#> 6         Machine learning for crop yield 2023       Costa C; Rao F
#> 7             Salinity responses of wheat 2017     Gomez E; Silva A
#> 8          Soil microbiome under rotation 2020     Rao F; Martins B
#> 9              UAV phenotyping of soybean 2024      Lima D; Costa C
#> 10        Meta-analysis of silicon stress 2025   Pereira W; Silva A
#> 11       Nitrogen use efficiency in maize 2022       Rao F; Gomez E
#> 12          Climate-smart soil management 2024 Martins B; Pereira W
#>                      Author Keywords
#> 1            silicon; salinity; rice
#> 2           soil carbon; cover crops
#> 3  remote sensing; soybean; nitrogen
#> 4            silicon; drought; maize
#> 5     cover crops; aggregation; soil
#> 6            machine learning; yield
#> 7                    salinity; wheat
#> 8          soil microbiome; rotation
#> 9          uav; soybean; phenotyping
#> 10    silicon; meta-analysis; stress
#> 11       nitrogen; maize; efficiency
#> 12   climate-smart; soil; management
head(to_biblium(as_biblio_project(example_biblio())),3)
#>                                    Title Year            Authors
#> 1 Silicon and salinity tolerance in rice 2018 Silva A; Pereira W
#> 2          Soil carbon under cover crops 2019 Martins B; Costa C
#> 3     Remote sensing of soybean nitrogen 2020  Lima D; Pereira W
#>                     Author Keywords
#> 1           silicon; salinity; rice
#> 2          soil carbon; cover crops
#> 3 remote sensing; soybean; nitrogen
names(to_biblium(as_biblio_project(example_biblio())))
#> [1] "Title"           "Year"            "Authors"         "Author Keywords"
```
