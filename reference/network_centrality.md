# Network centrality table

Network centrality table

## Usage

``` r
network_centrality(graph)
```

## Arguments

- graph:

  An igraph object.

## Value

A data frame of degree, strength, betweenness and PageRank.

## Examples

``` r
g <- bibliographic_network(as_biblio_project(example_biblio()),"coauthor"); network_centrality(g)
#>                node degree strength betweenness  pagerank
#> A000008c4 A000008c4      3        3  0.03333333 0.1290688
#> A00000905 A00000905      2        3  0.12222222 0.1267212
#> A00000f4d A00000f4d      4        4  0.12222222 0.1648773
#> A00000f73 A00000f73      3        4  0.27777778 0.1612960
#> A00000621 A00000621      3        3  0.05555556 0.1273099
#> A000008ad A000008ad      2        4  0.20000000 0.1617880
#> A0000043f A0000043f      3        3  0.12222222 0.1289388
head(network_centrality(g),3)
#>                node degree strength betweenness  pagerank
#> A000008c4 A000008c4      3        3  0.03333333 0.1290688
#> A00000905 A00000905      2        3  0.12222222 0.1267212
#> A00000f4d A00000f4d      4        4  0.12222222 0.1648773
network_centrality(bibliographic_network(as_biblio_project(example_biblio()),"keyword"))
#>                              node degree strength betweenness   pagerank
#> cover crops           cover crops      3        3  0.01581028 0.05408732
#> soil carbon           soil carbon      1        1  0.00000000 0.02157474
#> silicon                   silicon      6        6  0.18181818 0.08640333
#> maize                       maize      4        4  0.16600791 0.05643655
#> nitrogen                 nitrogen      4        4  0.14229249 0.05692476
#> drought                   drought      2        2  0.00000000 0.03048324
#> climate-smart       climate-smart      2        2  0.00000000 0.03568058
#> soil                         soil      4        4  0.02371542 0.06713569
#> remote sensing     remote sensing      2        2  0.00000000 0.03097144
#> soybean                   soybean      4        4  0.08695652 0.05941145
#> uav                           uav      2        2  0.00000000 0.03282597
#> salinity                 salinity      3        3  0.04743083 0.04956778
#> soil microbiome   soil microbiome      1        1  0.00000000 0.04166667
#> aggregation           aggregation      2        2  0.00000000 0.03584108
#> meta-analysis       meta-analysis      2        2  0.00000000 0.03215734
#> machine learning machine learning      1        1  0.00000000 0.04166667
#> efficiency             efficiency      2        2  0.00000000 0.03033928
#> management             management      2        2  0.00000000 0.03568058
#> phenotyping           phenotyping      2        2  0.00000000 0.03282597
#> rice                         rice      2        2  0.00000000 0.03253468
#> rotation                 rotation      1        1  0.00000000 0.04166667
#> stress                     stress      2        2  0.00000000 0.03215734
#> wheat                       wheat      1        1  0.00000000 0.02029421
#> yield                       yield      1        1  0.00000000 0.04166667
```
