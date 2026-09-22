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
#> [1] TRUE
#> 
#> $python
#> [1] "H:/uv/AppDataLocalUv/cache/archive-v0/MfuOKTFtveE-Nd3l_RFiM/Scripts/python.exe"
#> 
#> $version
#> [1] "2.16.0"
#> 
#> $reason
#> [1] "ok"
#> 
names(python_backend_status())
#> [1] "available" "python"    "version"   "reason"   
is.list(python_backend_status())
#> [1] TRUE
```
