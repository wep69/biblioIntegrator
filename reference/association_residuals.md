# Extract standardized association residuals

Extract standardized association residuals

## Usage

``` r
association_residuals(x, min_abs = 0)
```

## Arguments

- x:

  A `biblio_group_comparison`.

- min_abs:

  Minimum absolute residual retained.

## Value

Long data frame of group-entity residuals.

## Examples

``` r
z <- compare_groups(as_biblio_project(example_biblio()),rep(c("a","b"),6),permutations=19)
association_residuals(z)
#>              group           entity    residual observed expected
#> 1  factor(groups)a      aggregation  0.95436677        1  0.53125
#> 2  factor(groups)b      aggregation -0.95436677        0  0.46875
#> 3  factor(groups)a    climate-smart -1.08161568        0  0.53125
#> 4  factor(groups)b    climate-smart  1.08161568        1  0.46875
#> 5  factor(groups)a      cover crops -0.09146591        1  1.06250
#> 6  factor(groups)b      cover crops  0.09146591        1  0.93750
#> 7  factor(groups)a          drought -1.08161568        0  0.53125
#> 8  factor(groups)b          drought  1.08161568        1  0.46875
#> 9  factor(groups)a       efficiency  0.95436677        1  0.53125
#> 10 factor(groups)b       efficiency -0.95436677        0  0.46875
#> 11 factor(groups)a machine learning -1.08161568        0  0.53125
#> 12 factor(groups)b machine learning  1.08161568        1  0.46875
#> 13 factor(groups)a            maize -0.09146591        1  1.06250
#> 14 factor(groups)b            maize  0.09146591        1  0.93750
#> 15 factor(groups)a       management -1.08161568        0  0.53125
#> 16 factor(groups)b       management  1.08161568        1  0.46875
#> 17 factor(groups)a    meta-analysis -1.08161568        0  0.53125
#> 18 factor(groups)b    meta-analysis  1.08161568        1  0.46875
#> 19 factor(groups)a         nitrogen  1.37198868        2  1.06250
#> 20 factor(groups)b         nitrogen -1.37198868        0  0.93750
#> 21 factor(groups)a      phenotyping  0.95436677        1  0.53125
#> 22 factor(groups)b      phenotyping -0.95436677        0  0.46875
#> 23 factor(groups)a   remote sensing  0.95436677        1  0.53125
#> 24 factor(groups)b   remote sensing -0.95436677        0  0.46875
#> 25 factor(groups)a             rice  0.95436677        1  0.53125
#> 26 factor(groups)b             rice -0.95436677        0  0.46875
#> 27 factor(groups)a         rotation -1.08161568        0  0.53125
#> 28 factor(groups)b         rotation  1.08161568        1  0.46875
#> 29 factor(groups)a         salinity  1.37198868        2  1.06250
#> 30 factor(groups)b         salinity -1.37198868        0  0.93750
#> 31 factor(groups)a          silicon -0.72160390        1  1.59375
#> 32 factor(groups)b          silicon  0.72160390        2  1.40625
#> 33 factor(groups)a             soil -0.09146591        1  1.06250
#> 34 factor(groups)b             soil  0.09146591        1  0.93750
#> 35 factor(groups)a      soil carbon -1.08161568        0  0.53125
#> 36 factor(groups)b      soil carbon  1.08161568        1  0.46875
#> 37 factor(groups)a  soil microbiome -1.08161568        0  0.53125
#> 38 factor(groups)b  soil microbiome  1.08161568        1  0.46875
#> 39 factor(groups)a          soybean  1.37198868        2  1.06250
#> 40 factor(groups)b          soybean -1.37198868        0  0.93750
#> 41 factor(groups)a           stress -1.08161568        0  0.53125
#> 42 factor(groups)b           stress  1.08161568        1  0.46875
#> 43 factor(groups)a              uav  0.95436677        1  0.53125
#> 44 factor(groups)b              uav -0.95436677        0  0.46875
#> 45 factor(groups)a            wheat  0.95436677        1  0.53125
#> 46 factor(groups)b            wheat -0.95436677        0  0.46875
#> 47 factor(groups)a            yield -1.08161568        0  0.53125
#> 48 factor(groups)b            yield  1.08161568        1  0.46875
head(association_residuals(z,min_abs=1))
#>              group           entity  residual observed expected
#> 3  factor(groups)a    climate-smart -1.081616        0  0.53125
#> 4  factor(groups)b    climate-smart  1.081616        1  0.46875
#> 7  factor(groups)a          drought -1.081616        0  0.53125
#> 8  factor(groups)b          drought  1.081616        1  0.46875
#> 11 factor(groups)a machine learning -1.081616        0  0.53125
#> 12 factor(groups)b machine learning  1.081616        1  0.46875
subset(association_residuals(z), residual>0)
#>              group           entity   residual observed expected
#> 1  factor(groups)a      aggregation 0.95436677        1  0.53125
#> 4  factor(groups)b    climate-smart 1.08161568        1  0.46875
#> 6  factor(groups)b      cover crops 0.09146591        1  0.93750
#> 8  factor(groups)b          drought 1.08161568        1  0.46875
#> 9  factor(groups)a       efficiency 0.95436677        1  0.53125
#> 12 factor(groups)b machine learning 1.08161568        1  0.46875
#> 14 factor(groups)b            maize 0.09146591        1  0.93750
#> 16 factor(groups)b       management 1.08161568        1  0.46875
#> 18 factor(groups)b    meta-analysis 1.08161568        1  0.46875
#> 19 factor(groups)a         nitrogen 1.37198868        2  1.06250
#> 21 factor(groups)a      phenotyping 0.95436677        1  0.53125
#> 23 factor(groups)a   remote sensing 0.95436677        1  0.53125
#> 25 factor(groups)a             rice 0.95436677        1  0.53125
#> 28 factor(groups)b         rotation 1.08161568        1  0.46875
#> 29 factor(groups)a         salinity 1.37198868        2  1.06250
#> 32 factor(groups)b          silicon 0.72160390        2  1.40625
#> 34 factor(groups)b             soil 0.09146591        1  0.93750
#> 36 factor(groups)b      soil carbon 1.08161568        1  0.46875
#> 38 factor(groups)b  soil microbiome 1.08161568        1  0.46875
#> 39 factor(groups)a          soybean 1.37198868        2  1.06250
#> 42 factor(groups)b           stress 1.08161568        1  0.46875
#> 43 factor(groups)a              uav 0.95436677        1  0.53125
#> 45 factor(groups)a            wheat 0.95436677        1  0.53125
#> 48 factor(groups)b            yield 1.08161568        1  0.46875
```
