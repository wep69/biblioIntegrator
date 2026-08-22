# Import a bibliographic file

Import a bibliographic file

## Usage

``` r
biblio_import(path, dbsource = NULL, format = NULL)
```

## Arguments

- path:

  CSV, TSV, JSON, RIS, BibTeX, or database export.

- dbsource:

  Optional source for
  [`bibliometrix::convert2df()`](https://rdrr.io/pkg/bibliometrix/man/convert2df.html).

- format:

  Optional format for
  [`bibliometrix::convert2df()`](https://rdrr.io/pkg/bibliometrix/man/convert2df.html).

## Value

A `biblio_project`.

## Examples

``` r
f <- tempfile(fileext = ".csv")
utils::write.csv(example_biblio(), f, row.names = FALSE)
biblio_import(f)
#> <biblio_project> 12 works; 7 authors; 32 work-keyword links
f2 <- tempfile(fileext=".json"); jsonlite::write_json(example_biblio(),f2); biblio_import(f2)
#> <biblio_project> 12 works; 7 authors; 32 work-keyword links
biblio_import(f, dbsource="auto")
#> <biblio_project> 12 works; 7 authors; 32 work-keyword links
```
