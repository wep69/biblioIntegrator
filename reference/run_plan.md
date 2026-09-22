# Execute an integrated bibliometric plan

Execute an integrated bibliometric plan

## Usage

``` r
run_plan(plan, data = NULL)
```

## Arguments

- plan:

  A `biblio_plan`.

- data:

  Data frame or `biblio_project`; if missing, `plan$source` is imported.

## Value

Named list of analysis results.

## Examples

``` r
run_plan(form_plan(),example_biblio())
#> $project
#> <biblio_project> 12 works; 7 authors; 32 work-keyword links
#> 
#> $health
#>                  check n
#> 1        missing_title 0
#> 2         missing_year 0
#> 3          missing_doi 0
#> 4        duplicate_doi 0
#> 5 duplicate_title_year 0
#> 6   negative_citations 0
#> 
#> $descriptive
#> $descriptive$n_documents
#> [1] 12
#> 
#> $descriptive$years
#> [1] 2017 2025
#> 
#> $descriptive$total_citations
#> [1] 309
#> 
#> $descriptive$annual
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
#> $descriptive$top_sources
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
#> $descriptive$top_keywords
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
#> 
#> 
#> $temporal
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
#> 
#> $network
#> IGRAPH 873fac0 UNW- 7 10 -- 
#> + attr: name (v/c), weight (e/n)
#> + edges from 873fac0 (vertex names):
#>  [1] A000008c4--A00000621 A00000905--A000008ad A000008c4--A00000f4d
#>  [4] A00000f4d--A00000f73 A00000f4d--A0000043f A000008c4--A0000043f
#>  [7] A00000f73--A000008ad A00000f4d--A00000621 A00000905--A0000043f
#> [10] A00000f73--A00000621
#> 
#> $centrality
#>                node degree strength betweenness  pagerank
#> A000008c4 A000008c4      3        3  0.03333333 0.1290688
#> A00000905 A00000905      2        3  0.12222222 0.1267212
#> A00000f4d A00000f4d      4        4  0.12222222 0.1648773
#> A00000f73 A00000f73      3        4  0.27777778 0.1612960
#> A00000621 A00000621      3        3  0.05555556 0.1273099
#> A000008ad A000008ad      2        4  0.20000000 0.1617880
#> A0000043f A0000043f      3        3  0.12222222 0.1289388
#> 
#> $terms
#>             term n
#> 1           soil 4
#> 2        silicon 3
#> 3          cover 2
#> 4          crops 2
#> 5          maize 2
#> 6       nitrogen 2
#> 7       salinity 2
#> 8        soybean 2
#> 9    aggregation 1
#> 10        carbon 1
#> 11 climate-smart 1
#> 12          crop 1
#> 13       drought 1
#> 14    efficiency 1
#> 15      learning 1
#> 16       machine 1
#> 17    management 1
#> 18 meta-analysis 1
#> 19    microbiome 1
#> 20     nutrition 1
#> 21   phenotyping 1
#> 22        remote 1
#> 23     responses 1
#> 24          rice 1
#> 25      rotation 1
#> 26       sensing 1
#> 27        stress 1
#> 28     tolerance 1
#> 29           uav 1
#> 30           use 1
#> 31         wheat 1
#> 32         yield 1
#> 
#> attr(,"class")
#> [1] "biblio_run" "list"      
run_plan(form_plan(analyses=c("health","text")),as_biblio_project(example_biblio()))
#> $project
#> <biblio_project> 12 works; 7 authors; 32 work-keyword links
#> 
#> $health
#>                  check n
#> 1        missing_title 0
#> 2         missing_year 0
#> 3          missing_doi 0
#> 4        duplicate_doi 0
#> 5 duplicate_title_year 0
#> 6   negative_citations 0
#> 
#> $terms
#>             term n
#> 1           soil 4
#> 2        silicon 3
#> 3          cover 2
#> 4          crops 2
#> 5          maize 2
#> 6       nitrogen 2
#> 7       salinity 2
#> 8        soybean 2
#> 9    aggregation 1
#> 10        carbon 1
#> 11 climate-smart 1
#> 12          crop 1
#> 13       drought 1
#> 14    efficiency 1
#> 15      learning 1
#> 16       machine 1
#> 17    management 1
#> 18 meta-analysis 1
#> 19    microbiome 1
#> 20     nutrition 1
#> 21   phenotyping 1
#> 22        remote 1
#> 23     responses 1
#> 24          rice 1
#> 25      rotation 1
#> 26       sensing 1
#> 27        stress 1
#> 28     tolerance 1
#> 29           uav 1
#> 30           use 1
#> 31         wheat 1
#> 32         yield 1
#> 
#> attr(,"class")
#> [1] "biblio_run" "list"      
names(run_plan(form_plan(analyses="network"),example_biblio()))
#> [1] "project"    "network"    "centrality"
```
