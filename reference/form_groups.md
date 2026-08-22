# Define bibliometric groups

Creates exclusive or overlapping document-group membership matrices.

## Usage

``` r
form_groups(x, groups)
```

## Arguments

- x:

  A `biblio_project`.

- groups:

  Factor/character vector, matrix/data frame, or function returning one.

## Value

A binary membership matrix with work IDs as row names.

## Examples

``` r
x <- as_biblio_project(example_biblio()); form_groups(x, ifelse(x$works$year<2022,"early","late"))
#>           factor(groups)early factor(groups)late
#> W0001f7e3                   1                  0
#> W000160f5                   1                  0
#> W0001b6e0                   1                  0
#> W0001b6e2                   1                  0
#> W0001932e                   0                  1
#> W00017da4                   0                  1
#> W00014309                   1                  0
#> W000176af                   1                  0
#> W000134bf                   0                  1
#> W00018e53                   0                  1
#> W000196f7                   0                  1
#> W00016cdd                   0                  1
#> attr(,"assign")
#> [1] 1 1
#> attr(,"contrasts")
#> attr(,"contrasts")$`factor(groups)`
#> [1] "contr.treatment"
#> 
form_groups(x, cbind(old=x$works$year<=2021,recent=x$works$year>=2021))
#>           old recent
#> W0001f7e3   1      0
#> W000160f5   1      0
#> W0001b6e0   1      0
#> W0001b6e2   1      1
#> W0001932e   0      1
#> W00017da4   0      1
#> W00014309   1      0
#> W000176af   1      0
#> W000134bf   0      1
#> W00018e53   0      1
#> W000196f7   0      1
#> W00016cdd   0      1
form_groups(x, function(w) ifelse(w$year<2020,"older","newer"))
#>           factor(groups)newer factor(groups)older
#> W0001f7e3                   0                   1
#> W000160f5                   0                   1
#> W0001b6e0                   1                   0
#> W0001b6e2                   1                   0
#> W0001932e                   1                   0
#> W00017da4                   1                   0
#> W00014309                   0                   1
#> W000176af                   1                   0
#> W000134bf                   1                   0
#> W00018e53                   1                   0
#> W000196f7                   1                   0
#> W00016cdd                   1                   0
#> attr(,"assign")
#> [1] 1 1
#> attr(,"contrasts")
#> attr(,"contrasts")$`factor(groups)`
#> [1] "contr.treatment"
#> 
```
