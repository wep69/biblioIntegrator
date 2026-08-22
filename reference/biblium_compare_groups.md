# Compare bibliometric groups with Biblium 2.16

Calls the public `BiblioGroup` association interface with permutation
inference, then converts the result to the same R structure used by the
native engine.

## Usage

``` r
biblium_compare_groups(
  x,
  groups,
  entity = c("keyword", "author"),
  permutations = 999,
  seed = NULL,
  python = NULL
)
```

## Arguments

- x:

  A `biblio_project`.

- groups:

  Group definition accepted by
  [`form_groups()`](https://wep69.github.io/biblioIntegrator/reference/form_groups.md).

- entity:

  `"keyword"` or `"author"`.

- permutations:

  Number of Biblium permutations.

- seed:

  Random seed.

- python:

  Optional Python executable.

## Value

A `biblio_group_comparison`.

## Examples

``` r
if (FALSE) { # \dontrun{
x <- as_biblio_project(example_biblio()); g <- rep(c("early","late"),6)
biblium_compare_groups(x,g,permutations=99,seed=1)
biblium_compare_groups(x,cbind(a=1:12<=7,b=1:12>=5),permutations=99,seed=2)
biblium_compare_groups(x,g,entity="author",permutations=99,seed=3)
} # }
```
