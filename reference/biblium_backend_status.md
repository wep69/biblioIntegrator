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
#> Downloading uv...
#> Done!
#> $available
#> [1] FALSE
#> 
#> $python
#> [1] "/home/runner/.cache/R/reticulate/uv/cache/archive-v0/FmQDvvVmOV6c0PMR/bin/python"
#> 
#> $version
#> [1] NA
#> 
#> $reason
#> [1] "Biblium could not be imported"
#> 
python_backend_status()
#> $available
#> [1] FALSE
#> 
#> $python
#> [1] "/home/runner/.cache/R/reticulate/uv/cache/archive-v0/FmQDvvVmOV6c0PMR/bin/python"
#> 
#> $version
#> [1] NA
#> 
#> $reason
#> [1] "Biblium could not be imported"
#> 
names(biblium_backend_status())
#> [1] "available" "python"    "version"   "reason"   
```
