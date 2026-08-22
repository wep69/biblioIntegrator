# Export a network for VOSviewer

Export a network for VOSviewer

## Usage

``` r
export_vosviewer(graph, path)
```

## Arguments

- graph:

  An igraph network.

- path:

  Output network text file.

## Value

Output path invisibly.

## Examples

``` r
x <- as_biblio_project(example_biblio())
g <- bibliographic_network(x, "coauthor")
f <- tempfile()
export_vosviewer(g, f)
file.exists(f)
#> [1] TRUE
g <- bibliographic_network(x, "keyword")
f <- tempfile()
export_vosviewer(g, f)
readLines(f, n = 2)
#> [1] "from\tto\tweight"            "cover crops\taggregation\t1"
g <- bibliographic_network(x, "coauthor")
f <- tempfile()
invisible(export_vosviewer(g, f))
```
