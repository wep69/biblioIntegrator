# Descriptive bibliometrics and impact

## Purpose

Descriptive indicators are useful summaries, but their interpretation
depends on coverage and citation window. Normalized scores compare
within explicit strata.

## Workflow

``` r

x <- as_biblio_project(example_biblio())
describe_biblio(x)
#> $n_documents
#> [1] 12
#> 
#> $years
#> [1] 2017 2025
#> 
#> $total_citations
#> [1] 309
#> 
#> $annual
#>   year documents citations
#> 1 2017         1        55
#> 2 2018         1        42
#> 3 2019         1        35
#> 4 2020         2        54
#> 5 2021         1        31
#> 6 2022         2        39
#> 7 2023         1        18
#> 8 2024         2        26
#> 9 2025         1         9
#> 
#> $top_sources
#> 
#>            Soil Science    Agricultural Systems        Agronomy Reviews 
#>                       2                       1                       1 
#>            Crop Science             Field Crops         Plant Nutrition 
#>                       1                       1                       1 
#>            Plant Stress   Precision Agriculture          Remote Sensing 
#>                       1                       1                       1 
#>            Soil Biology Sustainable Agriculture 
#>                       1                       1 
#> 
#> $top_keywords
#> 
#>          silicon      cover crops            maize         nitrogen 
#>                3                2                2                2 
#>         salinity             soil          soybean      aggregation 
#>                2                2                2                1 
#>    climate-smart          drought       efficiency machine learning 
#>                1                1                1                1 
#>       management    meta-analysis      phenotyping   remote sensing 
#>                1                1                1                1 
#>             rice         rotation      soil carbon  soil microbiome 
#>                1                1                1                1 
#>           stress              uav            wheat            yield 
#>                1                1                1                1
biblio_metrics(x)
#>              author documents citations h_index g_index   m_index
#> A0000043f     Rao F         3        61       3       3 0.7500000
#> A00000621    Lima D         3        62       3       3 0.6000000
#> A000008ad   Silva A         4       137       4       4 0.4444444
#> A000008c4   Costa C         3        65       3       3 0.5000000
#> A00000905   Gomez E         3       103       3       3 0.5000000
#> A00000f4d Martins B         4        97       4       4 0.6666667
#> A00000f73 Pereira W         4        93       4       4 0.5000000
normalized_citations(x)
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
citation_velocity(x, current_year = 2026)
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
```

## Interpretation

Results should be interpreted in relation to database coverage, time
window, entity normalization and analytical thresholds. Provenance
should be retained whenever data are merged, deduplicated or enriched.
