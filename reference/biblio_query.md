# Query a DuckDB bibliometric store

Query a DuckDB bibliometric store

## Usage

``` r
biblio_query(path, sql)
```

## Arguments

- path:

  DuckDB database file.

- sql:

  SQL query.

## Value

A data frame.

## Examples

``` r
# \donttest{
if (requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("DBI", quietly = TRUE)) {
  x <- as_biblio_project(example_biblio())
  p <- tempfile(fileext = ".duckdb")
  biblio_store(x, p, "duckdb")
  biblio_query(p, "SELECT year, COUNT(*) AS n FROM works GROUP BY year")
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
#>   year n
#> 1 2017 1
#> 2 2018 1
#> 3 2019 1
#> 4 2020 2
#> 5 2021 1
#> 6 2022 2
#> 7 2023 1
#> 8 2024 2
#> 9 2025 1
if (requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("DBI", quietly = TRUE)) {
  x <- as_biblio_project(example_biblio())
  p <- tempfile(fileext = ".duckdb")
  biblio_store(x, p, "duckdb")
  biblio_query(p, "SELECT * FROM works LIMIT 2")
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
#>     work_id                                  title year            doi
#> 1 W0001f7e3 Silicon and salinity tolerance in rice 2018 10.1000/agri.1
#> 2 W000160f5          Soil carbon under cover crops 2019 10.1000/agri.2
#>         source cited_by_count abstract
#> 1  Field Crops             42         
#> 2 Soil Science             35         
if (requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("DBI", quietly = TRUE)) {
  x <- as_biblio_project(example_biblio())
  p <- tempfile(fileext = ".duckdb")
  biblio_store(x, p, "duckdb")
  nrow(biblio_query(p, "SELECT * FROM keywords"))
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
#> [1] 32
# }
```
