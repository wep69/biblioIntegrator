# Export harmonized bibliographic tables

Export harmonized bibliographic tables

## Usage

``` r
export_biblio(x, path, format = c("csv", "json", "parquet"))
```

## Arguments

- x:

  A `biblio_project`.

- path:

  Output directory.

- format:

  `"csv"`, `"json"`, or `"parquet"`.

## Value

Output directory invisibly.

## Examples

``` r
p<-tempfile();export_biblio(as_biblio_project(example_biblio()),p);list.files(p)
#> [1] "authors.csv"     "authorships.csv" "keywords.csv"    "provenance.csv" 
#> [5] "references.csv"  "works.csv"      
p<-tempfile();export_biblio(as_biblio_project(head(example_biblio())),p,"json");list.files(p)
#> [1] "authors.json"     "authorships.json" "keywords.json"    "provenance.json" 
#> [5] "references.json"  "works.json"      
# \donttest{
if (requireNamespace("arrow", quietly = TRUE)) {
  p <- tempfile()
  x <- as_biblio_project(example_biblio())
  export_biblio(x, p, "parquet")
  list.files(p)
}
#> [1] "authors.parquet"     "authorships.parquet" "keywords.parquet"   
#> [4] "provenance.parquet"  "references.parquet"  "works.parquet"      
# }
```
