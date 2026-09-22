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

  Replace existing output; when `FALSE` (default), an existing `path`
  raises an error.

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
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ C:\Users\wep69/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ C:\Users\wep69/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
#> <biblio_project> 12 works; 7 authors; 32 work-keyword links
if (requireNamespace("arrow", quietly = TRUE)) {
  p <- tempfile()
  biblio_store(x, p, "arrow", overwrite = TRUE)
}
# }
```
