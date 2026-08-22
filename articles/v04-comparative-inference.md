# Comparative inference

## Purpose

The native engine handles exclusive or overlapping groups. For overlaps
it permutes complete membership rows, preserving the overlap pattern.

## Workflow

``` r

x <- as_biblio_project(example_biblio())
g <- ifelse(x$works$year < 2022, "early", "recent")
z <- compare_groups(x, g, permutations = 99, bootstrap = 49, seed = 10)
z
#> <biblio_group_comparison> native engine
#> Chi-square: 21.29  p: 0.83  V: 0.816
head(association_residuals(z))
#>                  group        entity    residual observed expected
#> 1  factor(groups)early   aggregation -0.95436677        0  0.46875
#> 2 factor(groups)recent   aggregation  0.95436677        1  0.53125
#> 3  factor(groups)early climate-smart -0.95436677        0  0.46875
#> 4 factor(groups)recent climate-smart  0.95436677        1  0.53125
#> 5  factor(groups)early   cover crops  0.09146591        1  0.93750
#> 6 factor(groups)recent   cover crops -0.09146591        1  1.06250
group_ca(z)
#> $rows
#>                            [,1]         [,2]
#> factor(groups)early  -0.8683744 9.965416e-17
#> factor(groups)recent  0.7662127 9.965416e-17
#> 
#> $columns
#>                         [,1]          [,2]
#> aggregation       0.93933644  5.441281e-16
#> climate-smart     0.93933644 -2.240543e-17
#> cover crops      -0.06262243 -1.078038e-18
#> drought          -1.06458129  1.013426e-17
#> efficiency        0.93933644 -2.240543e-17
#> machine learning  0.93933644 -2.240543e-17
#> maize            -0.06262243 -1.078038e-18
#> management        0.93933644 -2.240543e-17
#> meta-analysis     0.93933644 -2.240543e-17
#> nitrogen         -0.06262243 -1.078038e-18
#> phenotyping       0.93933644 -2.240543e-17
#> remote sensing   -1.06458129  1.013426e-17
#> rice             -1.06458129  1.013426e-17
#> rotation         -1.06458129  1.013426e-17
#> salinity         -1.06458129  5.753652e-17
#> silicon          -0.39660872 -5.822949e-18
#> soil              0.93933644 -6.980768e-17
#> soil carbon      -1.06458129  1.013426e-17
#> soil microbiome  -1.06458129  1.013426e-17
#> soybean          -0.06262243 -1.078038e-18
#> stress            0.93933644 -2.240543e-17
#> uav               0.93933644 -2.240543e-17
#> wheat            -1.06458129  1.013426e-17
#> yield             0.93933644 -2.240543e-17
#> 
#> $singular_values
#> [1] 8.156957e-01 9.965416e-17
sensitivity_analysis(x, g, thresholds = 1:2, permutations = 49, seed = 10)
#>   threshold entities cramers_v p_value
#> 1         1       24 0.8156957    0.82
#> 2         2        7 0.5345225    0.78
```

## Interpretation

Results should be interpreted in relation to database coverage, time
window, entity normalization and analytical thresholds. Provenance
should be retained whenever data are merged, deduplicated or enriched.
