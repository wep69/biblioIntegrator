# Deduplicate bibliographic records

Deduplicate bibliographic records

## Usage

``` r
deduplicate_biblio(x, method = c("doi_title_year"))
```

## Arguments

- x:

  A `biblio_project`.

- method:

  Matching hierarchy: DOI then normalized title-year.

## Value

A deduplicated `biblio_project` with a log attribute.

## Examples

``` r
x <- as_biblio_project(rbind(example_biblio(),example_biblio()[1,])); deduplicate_biblio(x)
#> <biblio_project> 12 works; 7 authors; 32 work-keyword links
nrow(deduplicate_biblio(x)$works)
#> [1] 12
attr(deduplicate_biblio(x),"dedup_log")
#>      work_id                                  title            doi
#> 13 W0001f7e3 Silicon and salinity tolerance in rice 10.1000/agri.1
```
