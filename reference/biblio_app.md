# Interactive bibliometric workbench

Interactive bibliometric workbench

## Usage

``` r
biblio_app(data = NULL)
```

## Arguments

- data:

  Optional initial data frame or `biblio_project`.

## Value

A Shiny application object.

## Examples

``` r
if (FALSE) { # \dontrun{
biblio_app()
biblio_app(example_biblio())
shiny::runApp(biblio_app(as_biblio_project(example_biblio())))
} # }
```
