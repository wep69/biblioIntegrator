# Create an analysis plan

Create an analysis plan

## Usage

``` r
form_plan(
  source = NULL,
  analyses = c("health", "descriptive", "temporal", "network", "text"),
  network = "coauthor",
  group = NULL,
  report = c("markdown", "html", "docx", "pdf"),
  seed = 123
)
```

## Arguments

- source:

  Data source label or file path.

- analyses:

  Character vector of requested analysis blocks.

- network:

  Network type.

- group:

  Optional group definition.

- report:

  Output report format.

- seed:

  Reproducibility seed.

## Value

A `biblio_plan` list.

## Examples

``` r
form_plan()
#> $source
#> NULL
#> 
#> $analyses
#> [1] "health"      "descriptive" "temporal"    "network"     "text"       
#> 
#> $network
#> [1] "coauthor"
#> 
#> $group
#> NULL
#> 
#> $report
#> [1] "markdown"
#> 
#> $seed
#> [1] 123
#> 
#> attr(,"class")
#> [1] "biblio_plan"
form_plan(analyses=c("health","descriptive","network"),network="coauthor")
#> $source
#> NULL
#> 
#> $analyses
#> [1] "health"      "descriptive" "network"    
#> 
#> $network
#> [1] "coauthor"
#> 
#> $group
#> NULL
#> 
#> $report
#> [1] "markdown"
#> 
#> $seed
#> [1] 123
#> 
#> attr(,"class")
#> [1] "biblio_plan"
form_plan(source="scopus.csv",report="docx",seed=42)
#> $source
#> [1] "scopus.csv"
#> 
#> $analyses
#> [1] "health"      "descriptive" "temporal"    "network"     "text"       
#> 
#> $network
#> [1] "coauthor"
#> 
#> $group
#> NULL
#> 
#> $report
#> [1] "docx"
#> 
#> $seed
#> [1] 42
#> 
#> attr(,"class")
#> [1] "biblio_plan"
```
