# Bootstrap/subsampling stability of node centrality

Bootstrap/subsampling stability of node centrality

## Usage

``` r
network_stability(
  x,
  type = c("coauthor", "keyword"),
  B = 100,
  fraction = 0.8,
  seed = NULL
)
```

## Arguments

- x:

  A `biblio_project`.

- type:

  Network type.

- B:

  Number of subsamples.

- fraction:

  Fraction of works retained per subsample.

- seed:

  Random seed.

## Value

Node-wise mean and SD of degree ranks.

## Examples

``` r
x <- as_biblio_project(example_biblio()); network_stability(x,B=10,seed=1)
#>        node mean_rank   sd_rank replicates
#> 1 A0000043f      4.65 1.6167526         10
#> 2 A00000621      5.05 1.6574747         10
#> 3 A000008ad      2.25 0.8897565         10
#> 4 A000008c4      4.35 1.8566697         10
#> 5 A00000905      5.10 1.6633300         10
#> 6 A00000f4d      3.80 1.6363917         10
#> 7 A00000f73      2.80 1.8885621         10
network_stability(x,type="keyword",B=8,fraction=.8,seed=2)
#>                node mean_rank   sd_rank replicates
#> 1       aggregation  9.833333 0.8755950          6
#> 2     climate-smart  9.916667 0.9703951          6
#> 3       cover crops  8.812500 6.3354868          8
#> 4           drought  9.666667 1.1254629          6
#> 5        efficiency 10.000000 0.6123724          5
#> 6  machine learning 18.062500 0.9425459          8
#> 7             maize  6.562500 3.7267134          8
#> 8        management  9.916667 0.9703951          6
#> 9     meta-analysis  9.500000 1.0000000          7
#> 10         nitrogen  8.625000 2.8504386          8
#> 11      phenotyping  9.625000 0.9910312          8
#> 12   remote sensing  9.250000 1.1902381          4
#> 13             rice 10.100000 0.6519202          5
#> 14         rotation 18.200000 1.2041595          5
#> 15         salinity 10.562500 6.4333811          8
#> 16          silicon  1.500000 0.4629100          8
#> 17             soil  5.562500 3.5900408          8
#> 18      soil carbon 17.583333 0.3763863          6
#> 19  soil microbiome 18.200000 1.2041595          5
#> 20          soybean  5.937500 4.3788249          8
#> 21           stress  9.500000 1.0000000          7
#> 22              uav  9.625000 0.9910312          8
#> 23            wheat 17.583333 0.3763863          6
#> 24            yield 18.062500 0.9425459          8
head(network_stability(x,B=6,seed=3),3)
#>        node mean_rank   sd_rank replicates
#> 1 A0000043f  5.500000 1.3416408          6
#> 2 A00000621  5.333333 1.5055453          6
#> 3 A000008ad  2.416667 0.7359801          6
```
