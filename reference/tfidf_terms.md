# TF-IDF terms by year or source

TF-IDF terms by year or source

## Usage

``` r
tfidf_terms(x, group = c("year", "source"), field = c("title", "abstract"))
```

## Arguments

- x:

  A `biblio_project`.

- group:

  `"year"` or `"source"`.

- field:

  Text field.

## Value

Long data frame with term frequency and TF-IDF.

## Examples

``` r
head(tfidf_terms(as_biblio_project(example_biblio())),6)
#>             term group n df    tfidf
#> 1    aggregation  2022 1  1 2.197225
#> 4         carbon  2019 1  1 2.197225
#> 5  climate-smart  2024 1  1 2.197225
#> 8           crop  2023 1  1 2.197225
#> 11       drought  2021 1  1 2.197225
#> 12    efficiency  2022 1  1 2.197225
head(tfidf_terms(as_biblio_project(example_biblio()),group="source"),6)
#>             term                   group n df    tfidf
#> 6          cover            Soil Science 2  1 4.795791
#> 8          crops            Soil Science 2  1 4.795791
#> 34          soil            Soil Science 2  3 2.598566
#> 1    aggregation            Soil Science 1  1 2.397895
#> 4         carbon            Soil Science 1  1 2.397895
#> 5  climate-smart Sustainable Agriculture 1  1 2.397895
subset(tfidf_terms(as_biblio_project(example_biblio())), tfidf>0)[1:3,]
#>            term group n df    tfidf
#> 1   aggregation  2022 1  1 2.197225
#> 4        carbon  2019 1  1 2.197225
#> 5 climate-smart  2024 1  1 2.197225
```
