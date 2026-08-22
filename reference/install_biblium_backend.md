# Install an isolated Biblium backend

Install an isolated Biblium backend

## Usage

``` r
install_biblium_backend(
  envname = "r-bibliointegrator",
  python = NULL,
  version = "2.16.0"
)
```

## Arguments

- envname:

  Virtual environment name or path.

- python:

  Python executable used to create the environment.

- version:

  Biblium version.

## Value

Invisible virtual environment path.

## Examples

``` r
if (FALSE) { # \dontrun{
install_biblium_backend()
install_biblium_backend(version="2.16.0")
install_biblium_backend(envname="r-bibliointegrator")
} # }
```
