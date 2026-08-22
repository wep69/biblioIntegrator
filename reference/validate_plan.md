# Validate an analysis plan

Validate an analysis plan

## Usage

``` r
validate_plan(plan)
```

## Arguments

- plan:

  A `biblio_plan`.

## Value

Plan invisibly; errors on invalid settings.

## Examples

``` r
validate_plan(form_plan())
validate_plan(form_plan(network="keyword"))
inherits(validate_plan(form_plan(report="html")),"biblio_plan")
#> [1] TRUE
```
