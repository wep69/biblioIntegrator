# Sensitivity analysis for entity-frequency thresholds

Sensitivity analysis for entity-frequency thresholds

## Usage

``` r
sensitivity_analysis(
  x,
  groups,
  thresholds = c(1, 2, 3),
  entity = c("keyword", "author"),
  permutations = 99,
  seed = NULL
)
```

## Arguments

- x:

  A `biblio_project`.

- groups:

  Group definition.

- thresholds:

  Minimum entity frequencies.

- entity:

  Entity type.

- permutations:

  Number of permutations per threshold.

- seed:

  Seed.

## Value

A data frame with effect sizes and p-values by threshold.

## Examples

``` r
x <- as_biblio_project(example_biblio()); g <- rep(c("a","b"),6)
sensitivity_analysis(x,g,thresholds=1:2,permutations=19,seed=1)
#>   threshold entities cramers_v p_value
#> 1         1       24 0.8532904     0.7
#> 2         2        7 0.5916080     0.6
sensitivity_analysis(x,g,thresholds=c(1,3),permutations=9,seed=2)
#>   threshold entities cramers_v p_value
#> 1         1       24 0.8532904     0.6
#> 2         3        1        NA      NA
subset(sensitivity_analysis(x,g,1:2,permutations=9), entities>1)
#>   threshold entities cramers_v p_value
#> 1         1       24 0.8532904     0.5
#> 2         2        7 0.5916080     0.4
```
