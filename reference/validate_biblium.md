# Cross-validate native and Biblium group inference

Cross-validate native and Biblium group inference

## Usage

``` r
validate_biblium(
  x,
  groups,
  entity = c("keyword", "author"),
  permutations = 999,
  seed = 1
)
```

## Arguments

- x:

  A `biblio_project`.

- groups:

  Group definition.

- entity:

  Entity type.

- permutations:

  Number of permutations.

- seed:

  Seed used by both engines.

## Value

A comparison data frame and both fitted objects.

## Examples

``` r
if (FALSE) { # \dontrun{
x <- as_biblio_project(example_biblio())
g <- rep(c("a", "b"), 6)
validate_biblium(x, g, permutations = 99, seed = 1)
validate_biblium(x,g,entity="author",permutations=99,seed=2)
validate_biblium(x,cbind(a=1:12<=7,b=1:12>=5),permutations=99,seed=3)
} # }
```
