# Scalable storage and backends

## Purpose

Arrow and DuckDB are optional storage engines. They keep the core
package lightweight while enabling larger-than-memory workflows and SQL
queries.

## Workflow

``` r

backend_status()
#>                     backend available
#> biblionetwork biblionetwork      TRUE
#> arrow                 arrow      TRUE
#> duckdb               duckdb      TRUE
#> DBI                     DBI      TRUE
#> bibliometrix   bibliometrix      TRUE
#> openalexR         openalexR      TRUE
x <- as_biblio_project(example_biblio())
if (requireNamespace("arrow", quietly = TRUE)) {
  p <- tempfile()
  biblio_store(x, p, "arrow")
  nrow(biblio_load(p, "arrow")$works)
}
#> [1] 12
if (requireNamespace("duckdb", quietly = TRUE) && requireNamespace("DBI", quietly = TRUE)) {
  p <- tempfile(fileext = ".duckdb")
  biblio_store(x, p, "duckdb")
  biblio_query(p, "SELECT year, COUNT(*) AS n FROM works GROUP BY year ORDER BY year")
}
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/Rtmpx34jOJ/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/Rtmpx34jOJ/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
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
```

## Interpretation

Results should be interpreted in relation to database coverage, time
window, entity normalization and analytical thresholds. Provenance
should be retained whenever data are merged, deduplicated or enriched.
