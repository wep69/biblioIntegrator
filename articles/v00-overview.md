# Overview and design

## Purpose

The package uses a harmonized relational project as the common
analytical object. This avoids treating one database export schema as
the universal data model.

## Workflow

``` r

library(biblioIntegrator)
x <- as_biblio_project(example_biblio())
x
#> <biblio_project> 12 works; 7 authors; 32 work-keyword links
biblio_health(x)
#>                  check n
#> 1        missing_title 0
#> 2         missing_year 0
#> 3          missing_doi 0
#> 4        duplicate_doi 0
#> 5 duplicate_title_year 0
#> 6   negative_citations 0
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
audit_biblio(x)
#>                    timestamp         operation           details
#> 1 2026-08-22 23:10:55.107064 as_biblio_project source=user; n=12
```

## Interpretation

Results should be interpreted in relation to database coverage, time
window, entity normalization and analytical thresholds. Provenance
should be retained whenever data are merged, deduplicated or enriched.
