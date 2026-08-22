# Term frequency from titles or abstracts

Term frequency from titles or abstracts

## Usage

``` r
term_frequency(
  x,
  field = c("title", "abstract"),
  stopwords = c("and", "the", "for", "with", "under", "of", "in", "to")
)
```

## Arguments

- x:

  A `biblio_project`.

- field:

  `"title"` or `"abstract"`.

- stopwords:

  Optional vector removed before counting.

## Value

Term-frequency data frame.

## Examples

``` r
term_frequency(as_biblio_project(example_biblio()))
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
head(term_frequency(as_biblio_project(example_biblio()),stopwords=c("and","the")),5)
#>      term n
#> 1    soil 4
#> 2 silicon 3
#> 3   cover 2
#> 4   crops 2
#> 5   maize 2
term_frequency(as_biblio_project(example_biblio()),field="abstract")
#> [1] n
#> <0 rows> (or 0-length row.names)
```
