# Detect network communities

Detect network communities

## Usage

``` r
network_communities(graph, method = c("louvain", "walktrap", "label_prop"))
```

## Arguments

- graph:

  Undirected igraph network.

- method:

  `"louvain"`, `"walktrap"`, or `"label_prop"`.

## Value

A data frame with node membership.

## Examples

``` r
g <- bibliographic_network(as_biblio_project(example_biblio()),"coauthor"); network_communities(g)
#>        node community
#> 1 A000008c4         1
#> 2 A00000905         2
#> 3 A00000f4d         1
#> 4 A00000f73         2
#> 5 A00000621         1
#> 6 A000008ad         2
#> 7 A0000043f         1
network_communities(g,"walktrap")
#>        node community
#> 1 A000008c4         2
#> 2 A00000905         1
#> 3 A00000f4d         2
#> 4 A00000f73         1
#> 5 A00000621         2
#> 6 A000008ad         1
#> 7 A0000043f         2
network_communities(g,"label_prop")
#>        node community
#> 1 A000008c4         1
#> 2 A00000905         1
#> 3 A00000f4d         1
#> 4 A00000f73         1
#> 5 A00000621         1
#> 6 A000008ad         1
#> 7 A0000043f         1
```
