# Correspondence analysis of group-entity associations

Correspondence analysis of group-entity associations

## Usage

``` r
group_ca(x, ndim = 2)
```

## Arguments

- x:

  A `biblio_group_comparison`.

- ndim:

  Number of dimensions.

## Value

Row/column coordinates and singular values.

## Examples

``` r
z <- compare_groups(as_biblio_project(example_biblio()),rep(c("a","b"),6),permutations=19)
group_ca(z)
#> $rows
#>                       [,1] [,2]
#> factor(groups)a -0.8015268    0
#> factor(groups)b  0.9083970    0
#> 
#> $columns
#>                         [,1] [,2]
#> aggregation      -0.93933644    0
#> climate-smart     1.06458129    0
#> cover crops       0.06262243    0
#> drought           1.06458129    0
#> efficiency       -0.93933644    0
#> machine learning  1.06458129    0
#> maize             0.06262243    0
#> management        1.06458129    0
#> meta-analysis     1.06458129    0
#> nitrogen         -0.93933644    0
#> phenotyping      -0.93933644    0
#> remote sensing   -0.93933644    0
#> rice             -0.93933644    0
#> rotation          1.06458129    0
#> salinity         -0.93933644    0
#> silicon           0.39660872    0
#> soil              0.06262243    0
#> soil carbon       1.06458129    0
#> soil microbiome   1.06458129    0
#> soybean          -0.93933644    0
#> stress            1.06458129    0
#> uav              -0.93933644    0
#> wheat            -0.93933644    0
#> yield             1.06458129    0
#> 
#> $singular_values
#> [1] 0.8532904 0.0000000
#> 
group_ca(z,ndim=1)$rows
#>                       [,1]
#> factor(groups)a -0.8015268
#> factor(groups)b  0.9083970
group_ca(z)$singular_values
#> [1] 0.8532904 0.0000000
```
