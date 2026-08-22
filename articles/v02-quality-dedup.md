# Quality control and deduplication

## Purpose

Quality checks should precede maps and rankings. Deduplication records
what was removed and adds an operation to provenance.

## Workflow

``` r

d <- rbind(example_biblio(), example_biblio()[1, ])
x <- as_biblio_project(d)
biblio_health(x)
#>                  check n
#> 1        missing_title 0
#> 2         missing_year 0
#> 3          missing_doi 0
#> 4        duplicate_doi 1
#> 5 duplicate_title_year 1
#> 6   negative_citations 0
y <- deduplicate_biblio(x)
attr(y, "dedup_log")
#>      work_id                                  title            doi
#> 13 W0001f7e3 Silicon and salinity tolerance in rice 10.1000/agri.1
audit_biblio(y)
#>                    timestamp          operation           details
#> 1 2026-08-22 23:10:58.107868  as_biblio_project source=user; n=13
#> 2   2026-08-22 23:10:58.1122 deduplicate_biblio         removed=1
```

## Interpretation

Results should be interpreted in relation to database coverage, time
window, entity normalization and analytical thresholds. Provenance
should be retained whenever data are merged, deduplicated or enriched.
