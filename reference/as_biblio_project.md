# Construct a bibliometric project

Harmonizes a bibliographic data frame into relational tables while
retaining provenance.

## Usage

``` r
as_biblio_project(x, source = "user")
```

## Arguments

- x:

  Data frame or existing `biblio_project`.

- source:

  Source label recorded in provenance.

## Value

A `biblio_project`.

## Examples

``` r
x <- as_biblio_project(example_biblio())
x2 <- as_biblio_project(head(example_biblio(), 5), source="demo")
inherits(as_biblio_project(x), "biblio_project")
#> [1] TRUE
```
