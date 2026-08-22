# Convert to bibliometrix field-tag data

Convert to bibliometrix field-tag data

## Usage

``` r
to_bibliometrix(x)
```

## Arguments

- x:

  A `biblio_project`.

## Value

A data frame compatible with common `bibliometrix` workflows.

## Examples

``` r
to_bibliometrix(as_biblio_project(example_biblio()))
#>                                        TI   PY              DI
#> 1  Silicon and salinity tolerance in rice 2018  10.1000/agri.1
#> 2           Soil carbon under cover crops 2019  10.1000/agri.2
#> 3      Remote sensing of soybean nitrogen 2020  10.1000/agri.3
#> 4      Silicon nutrition in maize drought 2021  10.1000/agri.4
#> 5        Cover crops and soil aggregation 2022  10.1000/agri.5
#> 6         Machine learning for crop yield 2023  10.1000/agri.6
#> 7             Salinity responses of wheat 2017  10.1000/agri.7
#> 8          Soil microbiome under rotation 2020  10.1000/agri.8
#> 9              UAV phenotyping of soybean 2024  10.1000/agri.9
#> 10        Meta-analysis of silicon stress 2025 10.1000/agri.10
#> 11       Nitrogen use efficiency in maize 2022 10.1000/agri.11
#> 12          Climate-smart soil management 2024 10.1000/agri.12
#>                         SO TC                  AU
#> 1              Field Crops 42   Silva A;Pereira W
#> 2             Soil Science 35   Martins B;Costa C
#> 3           Remote Sensing 28    Lima D;Pereira W
#> 4          Plant Nutrition 31     Silva A;Gomez E
#> 5             Soil Science 22    Martins B;Lima D
#> 6     Agricultural Systems 18       Costa C;Rao F
#> 7             Plant Stress 55     Gomez E;Silva A
#> 8             Soil Biology 26     Rao F;Martins B
#> 9    Precision Agriculture 12      Lima D;Costa C
#> 10        Agronomy Reviews  9   Pereira W;Silva A
#> 11            Crop Science 17       Rao F;Gomez E
#> 12 Sustainable Agriculture 14 Martins B;Pereira W
#>                                 DE
#> 1            silicon;salinity;rice
#> 2          soil carbon;cover crops
#> 3  remote sensing;soybean;nitrogen
#> 4            silicon;drought;maize
#> 5     cover crops;aggregation;soil
#> 6           machine learning;yield
#> 7                   salinity;wheat
#> 8         soil microbiome;rotation
#> 9          uav;soybean;phenotyping
#> 10    silicon;meta-analysis;stress
#> 11       nitrogen;maize;efficiency
#> 12   climate-smart;soil;management
nrow(to_bibliometrix(as_biblio_project(head(example_biblio()))))
#> [1] 6
names(to_bibliometrix(as_biblio_project(example_biblio())))
#> [1] "TI" "PY" "DI" "SO" "TC" "AU" "DE"
```
