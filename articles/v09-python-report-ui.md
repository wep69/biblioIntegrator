# Biblium, reporting and interactive use

## Purpose

Biblium is optional. Core comparative inference remains available in R.
When Biblium 2.16 is configured, the package can execute the public
BiblioGroup permutation interface and validate results against the
native engine.

## Workflow

``` r

x <- as_biblio_project(example_biblio())
python_backend_status()
#> $available
#> [1] FALSE
#> 
#> $python
#> [1] "/home/runner/.cache/R/reticulate/uv/cache/archive-v0/FmQDvvVmOV6c0PMR/bin/python"
#> 
#> $version
#> [1] NA
#> 
#> $reason
#> [1] "Biblium could not be imported"
plan <- form_plan(analyses = c("health", "descriptive", "network", "text"))
res <- run_plan(plan, x)
names(res)
#> [1] "project"     "health"      "descriptive" "network"     "centrality" 
#> [6] "terms"
f <- tempfile(fileext = ".md")
biblio_report(x, f)
#> [1] "/tmp/RtmpVXgvgJ/file223117545bc9.md"
file.exists(f)
#> [1] TRUE
```

For an explicitly configured Python environment, use
[`enable_python_backend()`](https://wep69.github.io/biblioIntegrator/reference/enable_python_backend.md)
and then
[`validate_biblium()`](https://wep69.github.io/biblioIntegrator/reference/validate_biblium.md)
to compare the native and Biblium engines. The interactive entry point
is
[`biblio_app()`](https://wep69.github.io/biblioIntegrator/reference/biblio_app.md).

## Interpretation

Results should be interpreted in relation to database coverage, time
window, entity normalization and analytical thresholds. Provenance
should be retained whenever data are merged, deduplicated or enriched.
