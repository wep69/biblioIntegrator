# Foundations-to-advanced tutorial

## Purpose

This tutorial links data architecture, audit, descriptive analysis,
formal group comparison, networks, sensitivity, scalable storage and
reporting in one agronomic workflow.

## Workflow

``` r

library(biblioIntegrator)
raw <- example_biblio()
x <- as_biblio_project(raw, source = "agronomy tutorial")
# 1. Diagnose the corpus
biblio_health(x)
#>                  check n
#> 1        missing_title 0
#> 2         missing_year 0
#> 3          missing_doi 0
#> 4        duplicate_doi 0
#> 5 duplicate_title_year 0
#> 6   negative_citations 0
# 2. Describe production and impact
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
# 3. Compare periods with inferential support
period <- ifelse(x$works$year <= 2021, "earlier", "recent")
cmp <- compare_groups(x, period, permutations = 199, bootstrap = 99, seed = 42)
cmp
#> <biblio_group_comparison> native engine
#> Chi-square: 21.29  p: 0.855  V: 0.816
head(association_residuals(cmp), 10)
#>                    group        entity    residual observed expected
#> 1  factor(groups)earlier   aggregation -0.95436677        0  0.46875
#> 2   factor(groups)recent   aggregation  0.95436677        1  0.53125
#> 3  factor(groups)earlier climate-smart -0.95436677        0  0.46875
#> 4   factor(groups)recent climate-smart  0.95436677        1  0.53125
#> 5  factor(groups)earlier   cover crops  0.09146591        1  0.93750
#> 6   factor(groups)recent   cover crops -0.09146591        1  1.06250
#> 7  factor(groups)earlier       drought  1.08161568        1  0.46875
#> 8   factor(groups)recent       drought -1.08161568        0  0.53125
#> 9  factor(groups)earlier    efficiency -0.95436677        0  0.46875
#> 10  factor(groups)recent    efficiency  0.95436677        1  0.53125
# 4. Study the collaboration structure
g <- bibliographic_network(x, "coauthor")
head(network_centrality(g))
#>                node degree strength betweenness  pagerank
#> A000008c4 A000008c4      3        3  0.03333333 0.1290688
#> A00000905 A00000905      2        3  0.12222222 0.1267212
#> A00000f4d A00000f4d      4        4  0.12222222 0.1648773
#> A00000f73 A00000f73      3        4  0.27777778 0.1612960
#> A00000621 A00000621      3        3  0.05555556 0.1273099
#> A000008ad A000008ad      2        4  0.20000000 0.1617880
network_communities(g)
#>        node community
#> 1 A000008c4         1
#> 2 A00000905         2
#> 3 A00000f4d         1
#> 4 A00000f73         2
#> 5 A00000621         1
#> 6 A000008ad         2
#> 7 A0000043f         1
network_stability(x, B = 30, seed = 42)
#>        node mean_rank  sd_rank replicates
#> 1 A0000043f  4.400000 1.599569         30
#> 2 A00000621  4.866667 1.553269         30
#> 3 A000008ad  3.450000 1.723819         30
#> 4 A000008c4  4.800000 1.589838         30
#> 5 A00000905  5.033333 1.473521         30
#> 6 A00000f4d  2.650000 1.480622         30
#> 7 A00000f73  2.800000 1.710011         30
# 5. Examine topical change
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
head(tfidf_terms(x))
#>             term group n df    tfidf
#> 1    aggregation  2022 1  1 2.197225
#> 4         carbon  2019 1  1 2.197225
#> 5  climate-smart  2024 1  1 2.197225
#> 8           crop  2023 1  1 2.197225
#> 11       drought  2021 1  1 2.197225
#> 12    efficiency  2022 1  1 2.197225
# 6. Check threshold sensitivity
sensitivity_analysis(x, period, 1:2, permutations = 99, seed = 42)
#>   threshold entities cramers_v p_value
#> 1         1       24 0.8156957    0.87
#> 2         2        7 0.5345225    0.74
# 7. Generate an auditable report
f <- tempfile(fileext = ".md")
biblio_report(x, f)
#> [1] "/tmp/Rtmp8wLPjc/file21a63897fb3e.md"
readLines(f, n = 12)
#>  [1] "# Bibliometric Analysis Report"       
#>  [2] ""                                     
#>  [3] "Generated: 2026-08-22 23:11:08.396483"
#>  [4] ""                                     
#>  [5] "## Corpus summary"                    
#>  [6] "Documents: **12**  "                  
#>  [7] "Total citations: **309**  "           
#>  [8] "Years: **2017-2025**"                 
#>  [9] ""                                     
#> [10] "## Data quality"                      
#> [11] "| check | n |"                        
#> [12] "| --- | --- |"
```

## Interpretation

Results should be interpreted in relation to database coverage, time
window, entity normalization and analytical thresholds. Provenance
should be retained whenever data are merged, deduplicated or enriched.
