# Backward-compatible Python backend status

Backward-compatible Python backend status

## Usage

``` r
python_backend_status(python = NULL)
```

## Arguments

- python:

  Optional Python executable.

## Value

Same result as
[`biblium_backend_status()`](https://wep69.github.io/biblioIntegrator/reference/biblium_backend_status.md).

## Examples

``` r
python_backend_status()
#> $available
#> [1] FALSE
#> 
#> $python
#> [1] "/home/runner/.cache/R/reticulate/uv/cache/archive-v0/ka0OLm6bEvr-E1K5/bin/python"
#> 
#> $version
#> [1] NA
#> 
#> $reason
#> [1] "Biblium could not be imported"
#> 
names(python_backend_status())
#> [1] "available" "python"    "version"   "reason"   
is.list(python_backend_status())
#> [1] TRUE
```
