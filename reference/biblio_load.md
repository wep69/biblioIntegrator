# Load a stored bibliometric project

Load a stored bibliometric project

## Usage

``` r
biblio_load(path, engine = c("arrow", "duckdb"))
```

## Arguments

- path:

  Directory or DuckDB file.

- engine:

  Storage engine.

## Value

A `biblio_project`.

## Examples

``` r
# \donttest{
x <- as_biblio_project(example_biblio())
if(requireNamespace("arrow",quietly=TRUE)){p<-tempfile();biblio_store(x,p);biblio_load(p)}
#> <biblio_project> 12 works; 7 authors; 32 work-keyword links
if (requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("DBI", quietly = TRUE)) {
  p <- tempfile(fileext = ".duckdb")
  biblio_store(x, p, "duckdb")
  biblio_load(p, "duckdb")
}
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpxGmpuG/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpxGmpuG/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> <biblio_project> 12 works; 7 authors; 32 work-keyword links
if (requireNamespace("arrow", quietly = TRUE)) {
  p <- tempfile()
  biblio_store(x, p)
  nrow(biblio_load(p)$works)
}
#> [1] 12
# }
```
