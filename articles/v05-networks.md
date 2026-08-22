# Networks and stability

## Purpose

Network construction is distinct from network interpretation. The native
engine is always available; biblionetwork can accelerate coauthorship
construction.

## Workflow

``` r

x <- as_biblio_project(example_biblio())
g <- bibliographic_network(x, "coauthor")
network_centrality(g)
#>                node degree strength betweenness  pagerank
#> A000008c4 A000008c4      3        3  0.03333333 0.1290688
#> A00000905 A00000905      2        3  0.12222222 0.1267212
#> A00000f4d A00000f4d      4        4  0.12222222 0.1648773
#> A00000f73 A00000f73      3        4  0.27777778 0.1612960
#> A00000621 A00000621      3        3  0.05555556 0.1273099
#> A000008ad A000008ad      2        4  0.20000000 0.1617880
#> A0000043f A0000043f      3        3  0.12222222 0.1289388
network_communities(g)
#>        node community
#> 1 A000008c4         1
#> 2 A00000905         2
#> 3 A00000f4d         1
#> 4 A00000f73         2
#> 5 A00000621         1
#> 6 A000008ad         2
#> 7 A0000043f         1
network_stability(x, B = 20, seed = 4)
#>        node mean_rank  sd_rank replicates
#> 1 A0000043f  4.550000 1.494728         20
#> 2 A00000621  4.600000 1.586124         20
#> 3 A000008ad  3.350000 1.836043         20
#> 4 A000008c4  4.973684 1.558789         19
#> 5 A00000905  4.750000 1.543237         20
#> 6 A00000f4d  2.900000 1.781484         20
#> 7 A00000f73  2.775000 1.609797         20
if (requireNamespace("biblionetwork", quietly = TRUE)) {
  gb <- bibliographic_network(x, "coauthor", engine = "biblionetwork")
  attr(gb, "engine")
}
#> [1] "biblionetwork"
```

## Interpretation

Results should be interpreted in relation to database coverage, time
window, entity normalization and analytical thresholds. Provenance
should be retained whenever data are merged, deduplicated or enriched.
