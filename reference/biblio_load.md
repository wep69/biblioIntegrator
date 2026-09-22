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
  biblio_store(x, p)
  nrow(biblio_load(p)$works)
}
#> [1] 12
# }
```
