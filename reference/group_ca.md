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
#>                       [,1]        [,2]
#> factor(groups)a -0.8015268 2.03212e-16
#> factor(groups)b  0.9083970 2.03212e-16
#> 
#> $columns
#>                         [,1]          [,2]
#> aggregation      -0.93933644  1.104267e-15
#> climate-smart     1.06458129  1.112184e-17
#> cover crops       0.06262243  2.259742e-18
#> drought           1.06458129  1.112184e-17
#> efficiency       -0.93933644 -3.510677e-17
#> machine learning  1.06458129  1.112184e-17
#> maize             0.06262243  2.259742e-18
#> management        1.06458129  1.112184e-17
#> meta-analysis     1.06458129  1.112184e-17
#> nitrogen         -0.93933644 -1.241601e-16
#> phenotyping      -0.93933644 -3.510677e-17
#> remote sensing   -0.93933644 -3.510677e-17
#> rice             -0.93933644 -3.510677e-17
#> rotation          1.06458129  1.112184e-17
#> salinity         -0.93933644 -1.241601e-16
#> silicon           0.39660872  1.714275e-17
#> soil              0.06262243  2.259742e-18
#> soil carbon       1.06458129  1.112184e-17
#> soil microbiome   1.06458129  1.112184e-17
#> soybean          -0.93933644 -1.241601e-16
#> stress            1.06458129  1.112184e-17
#> uav              -0.93933644 -3.510677e-17
#> wheat            -0.93933644 -3.510677e-17
#> yield             1.06458129  1.112184e-17
#> 
#> $singular_values
#> [1] 8.532904e-01 2.032120e-16
#> 
group_ca(z,ndim=1)$rows
#>                       [,1]
#> factor(groups)a -0.8015268
#> factor(groups)b  0.9083970
group_ca(z)$singular_values
#> [1] 8.532904e-01 2.032120e-16
```
