# Store a bibliometric project using Arrow or DuckDB

Store a bibliometric project using Arrow or DuckDB

## Usage

``` r
biblio_store(x, path, engine = c("arrow", "duckdb"), overwrite = FALSE)
```

## Arguments

- x:

  A `biblio_project`.

- path:

  Directory (Arrow) or database file (DuckDB).

- engine:

  Storage engine.

- overwrite:

  Replace existing output.

## Value

Normalized output path, invisibly.

## Examples

``` r
# \donttest{
x <- as_biblio_project(example_biblio())
if (requireNamespace("arrow", quietly = TRUE)) {
  p <- tempfile()
  biblio_store(x, p, "arrow")
  biblio_load(p, "arrow")
}
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
  biblio_store(x, p, "arrow", overwrite = TRUE)
}
# }
```
