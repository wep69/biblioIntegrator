# Enable an existing Python backend

Enable an existing Python backend

## Usage

``` r
enable_python_backend(python)
```

## Arguments

- python:

  Python executable.

## Value

Backend status.

## Examples

``` r
if (FALSE) { # \dontrun{
enable_python_backend("path/to/python")
enable_python_backend(Sys.which("python"))
enable_python_backend(reticulate::virtualenv_python("r-bibliointegrator"))
} # }
```
