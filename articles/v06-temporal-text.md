# Temporal and text analysis

## Purpose

Time and text modules provide transparent summaries without requiring
Python. They can be used before more complex semantic models.

## Workflow

``` r

x <- as_biblio_project(example_biblio())
temporal_growth(x)
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
trend_topics(x)
#>    year          keyword n
#> 1  2022      aggregation 1
#> 2  2024    climate-smart 1
#> 3  2019      cover crops 1
#> 4  2022      cover crops 1
#> 5  2021          drought 1
#> 6  2022       efficiency 1
#> 7  2023 machine learning 1
#> 8  2021            maize 1
#> 9  2022            maize 1
#> 10 2024       management 1
#> 11 2025    meta-analysis 1
#> 12 2020         nitrogen 1
#> 13 2022         nitrogen 1
#> 14 2024      phenotyping 1
#> 15 2020   remote sensing 1
#> 16 2018             rice 1
#> 17 2020         rotation 1
#> 18 2017         salinity 1
#> 19 2018         salinity 1
#> 20 2018          silicon 1
#> 21 2021          silicon 1
#> 22 2025          silicon 1
#> 23 2022             soil 1
#> 24 2024             soil 1
#> 25 2019      soil carbon 1
#> 26 2020  soil microbiome 1
#> 27 2020          soybean 1
#> 28 2024          soybean 1
#> 29 2025           stress 1
#> 30 2024              uav 1
#> 31 2017            wheat 1
#> 32 2023            yield 1
head(term_frequency(x), 10)
#>           term n
#> 1         soil 4
#> 2      silicon 3
#> 3        cover 2
#> 4        crops 2
#> 5        maize 2
#> 6     nitrogen 2
#> 7     salinity 2
#> 8      soybean 2
#> 9  aggregation 1
#> 10      carbon 1
head(tfidf_terms(x), 10)
#>             term group n df    tfidf
#> 1    aggregation  2022 1  1 2.197225
#> 4         carbon  2019 1  1 2.197225
#> 5  climate-smart  2024 1  1 2.197225
#> 8           crop  2023 1  1 2.197225
#> 11       drought  2021 1  1 2.197225
#> 12    efficiency  2022 1  1 2.197225
#> 13           for  2023 1  1 2.197225
#> 14      learning  2023 1  1 2.197225
#> 15       machine  2023 1  1 2.197225
#> 18    management  2024 1  1 2.197225
rpys(c(rep(2000, 6), 1995:2005))
#>    year n baseline deviation
#> 1  1995 1        1         0
#> 2  1996 1        1         0
#> 3  1997 1        1         0
#> 4  1998 1        1         0
#> 5  1999 1        1         0
#> 6  2000 7        1         6
#> 7  2001 1        1         0
#> 8  2002 1        1         0
#> 9  2003 1        1         0
#> 10 2004 1        1         0
#> 11 2005 1        1         0
```

## Interpretation

Results should be interpreted in relation to database coverage, time
window, entity normalization and analytical thresholds. Provenance
should be retained whenever data are merged, deduplicated or enriched.
