# Optional backend status

Optional backend status

## Usage

``` r
backend_status()
```

## Value

A data frame indicating installed scalable backends.

## Examples

``` r
backend_status()
#>                     backend available
#> biblionetwork biblionetwork      TRUE
#> arrow                 arrow      TRUE
#> duckdb               duckdb      TRUE
#> DBI                     DBI      TRUE
#> bibliometrix   bibliometrix      TRUE
#> openalexR         openalexR      TRUE
subset(backend_status(), available)
#>                     backend available
#> biblionetwork biblionetwork      TRUE
#> arrow                 arrow      TRUE
#> duckdb               duckdb      TRUE
#> DBI                     DBI      TRUE
#> bibliometrix   bibliometrix      TRUE
#> openalexR         openalexR      TRUE
backend_status()$backend
#> [1] "biblionetwork" "arrow"         "duckdb"        "DBI"          
#> [5] "bibliometrix"  "openalexR"    
```
