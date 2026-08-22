# biblioIntegrator

**biblioIntegrator** provides a reproducible R-first workflow for
importing, harmonizing, auditing, comparing, mapping and interpreting
bibliographic data.

Core methods work entirely in R. Optional engines extend scale and
interoperability.

## Installation

Install the released version from GitHub:

``` r

# Quick install (no vignettes)
pak::pak("wep69/biblioIntegrator")

# Full install with vignettes
remotes::install_github("wep69/biblioIntegrator", build_vignettes = TRUE)
```

## Quick start

``` r

library(biblioIntegrator)

# Load the built-in example corpus
x <- example_biblio()

# Health check
biblio_health(x)

# Descriptive summary
describe_biblio(x)

# Bibliometric metrics
biblio_metrics(x)

# Build a co-authorship network
net <- bibliographic_network(x, type = "coauthor")
network_centrality(net)
network_communities(net)
```

## Optional backends

| Backend | Purpose | Install |
|----|----|----|
| **biblionetwork** | Large-scale network construction | `install.packages("biblionetwork")` |
| **Arrow** | Columnar storage | `install.packages("arrow")` |
| **DuckDB** | SQL queries on bibliographic data | `install.packages("duckdb")` |
| **Biblium** (Python) | Advanced group comparison | [`biblioIntegrator::install_biblium_backend()`](https://wep69.github.io/biblioIntegrator/reference/install_biblium_backend.md) |

All optional backends are detected at run time and are never required
for core use.

## Documentation

Full documentation is available at
<https://wep69.github.io/biblioIntegrator/>.

## Citation

If you use biblioIntegrator in your research, please cite:

``` r

citation("biblioIntegrator")
```

## License

MIT
