# Topic trajectories by year

Topic trajectories by year

## Usage

``` r
trend_topics(x, min_total = 1)
```

## Arguments

- x:

  A `biblio_project`.

- min_total:

  Minimum corpus-wide keyword frequency.

## Value

Long data frame of keyword counts by year.

## Examples

``` r
trend_topics(as_biblio_project(example_biblio()))
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
trend_topics(as_biblio_project(example_biblio()),min_total=2)
#>    year     keyword n
#> 1  2019 cover crops 1
#> 2  2022 cover crops 1
#> 3  2021       maize 1
#> 4  2022       maize 1
#> 5  2020    nitrogen 1
#> 6  2022    nitrogen 1
#> 7  2017    salinity 1
#> 8  2018    salinity 1
#> 9  2018     silicon 1
#> 10 2021     silicon 1
#> 11 2025     silicon 1
#> 12 2022        soil 1
#> 13 2024        soil 1
#> 14 2020     soybean 1
#> 15 2024     soybean 1
head(trend_topics(as_biblio_project(example_biblio())),4)
#>   year       keyword n
#> 1 2022   aggregation 1
#> 2 2024 climate-smart 1
#> 3 2019   cover crops 1
#> 4 2022   cover crops 1
```
