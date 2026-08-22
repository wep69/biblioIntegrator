# Compare user-defined bibliometric groups

Tests group-entity association. For overlapping groups, the null
distribution is obtained by permuting complete membership rows,
preserving each document's overlap pattern. Standardized residuals
identify the direction of local associations.

## Usage

``` r
compare_groups(
  x,
  groups,
  entity = c("keyword", "author"),
  permutations = 999,
  bootstrap = 0,
  seed = NULL,
  engine = c("native", "biblium", "auto")
)
```

## Arguments

- x:

  A `biblio_project`.

- groups:

  Group definition accepted by
  [`form_groups()`](https://wep69.github.io/biblioIntegrator/reference/form_groups.md).

- entity:

  Entity type, currently `"keyword"` or `"author"`.

- permutations:

  Number of random permutations. Use zero for asymptotic inference.

- bootstrap:

  Number of document-level bootstrap replicates for Cramer's V interval.

- seed:

  Random seed.

- engine:

  `"native"`, `"biblium"`, or `"auto"`.

## Value

A `biblio_group_comparison` list.

## Examples

``` r
x <- as_biblio_project(example_biblio()); g <- ifelse(x$works$year<2022,"early","late")
compare_groups(x,g,permutations=49,seed=1)
#> <biblio_group_comparison> native engine
#> Chi-square: 21.29  p: 0.84  V: 0.816 
compare_groups(x,cbind(pre=x$works$year<=2021,post=x$works$year>=2021),permutations=49,seed=2)
#> <biblio_group_comparison> native engine
#> Chi-square: 20.03  p: 0.74  V: 0.756 
compare_groups(x,g,entity="author",permutations=19,bootstrap=19,seed=3)
#> <biblio_group_comparison> native engine
#> Chi-square: 2.333  p: 0.85  V: 0.312 
```
