# Import and harmonization

## Purpose

Import is separated from harmonization. CSV, TSV and JSON have native
paths, while other common bibliographic formats can use bibliometrix
when installed.

## Workflow

``` r

d <- example_biblio()
x <- as_biblio_project(d, source = "teaching corpus")
head(x$works)
#>     work_id                                  title year            doi
#> 1 W0001f7e3 Silicon and salinity tolerance in rice 2018 10.1000/agri.1
#> 2 W000160f5          Soil carbon under cover crops 2019 10.1000/agri.2
#> 3 W0001b6e0     Remote sensing of soybean nitrogen 2020 10.1000/agri.3
#> 4 W0001b6e2     Silicon nutrition in maize drought 2021 10.1000/agri.4
#> 5 W0001932e       Cover crops and soil aggregation 2022 10.1000/agri.5
#> 6 W00017da4        Machine learning for crop yield 2023 10.1000/agri.6
#>                 source cited_by_count abstract
#> 1          Field Crops             42         
#> 2         Soil Science             35         
#> 3       Remote Sensing             28         
#> 4      Plant Nutrition             31         
#> 5         Soil Science             22         
#> 6 Agricultural Systems             18
head(x$authorships)
#>              work_id author_id
#> Silva A    W0001f7e3 A000008ad
#> Pereira W  W0001f7e3 A00000f73
#> Martins B  W000160f5 A00000f4d
#> Costa C    W000160f5 A000008c4
#> Lima D     W0001b6e0 A00000621
#> Pereira W1 W0001b6e0 A00000f73
head(x$keywords)
#>     work_id        keyword
#> 1 W0001f7e3        silicon
#> 2 W0001f7e3       salinity
#> 3 W0001f7e3           rice
#> 4 W000160f5    soil carbon
#> 5 W000160f5    cover crops
#> 6 W0001b6e0 remote sensing
to_bibliometrix(x)
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
to_biblium(x)
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
```

## Interpretation

Results should be interpreted in relation to database coverage, time
window, entity normalization and analytical thresholds. Provenance
should be retained whenever data are merged, deduplicated or enriched.
