# Status of the optional Biblium Python backend

Status of the optional Biblium Python backend

## Usage

``` r
biblium_backend_status(python = NULL)
```

## Arguments

- python:

  Optional Python executable.

## Value

A list with availability, Python path and Biblium version.

## Examples

``` r
biblium_backend_status()
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
names(biblium_backend_status())
#> [1] "available" "python"    "version"   "reason"   
```
