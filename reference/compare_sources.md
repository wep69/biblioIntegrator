# Compare coverage across bibliographic sources

Compare coverage across bibliographic sources

## Usage

``` r
compare_sources(...)
```

## Arguments

- ...:

  Data frames or `biblio_project` objects.

## Value

A list with coverage and pairwise overlap.

## Examples

``` r
compare_sources(example_biblio(), head(example_biblio(),8))
#> $coverage
#>          source records unique
#> source1 source1      12     12
#> source2 source2       8      8
#> 
#> $overlap
#>   source1 source2 intersection
#> 1 source1 source2            8
#> 
compare_sources(as_biblio_project(example_biblio()), example_biblio()[5:12,])
#> $coverage
#>          source records unique
#> source1 source1      12     12
#> source2 source2       8      8
#> 
#> $overlap
#>   source1 source2 intersection
#> 1 source1 source2            8
#> 
compare_sources(A=example_biblio(), B=example_biblio()[1:6,])
#> $coverage
#>   source records unique
#> A      A      12     12
#> B      B       6      6
#> 
#> $overlap
#>   source1 source2 intersection
#> 1       A       B            6
#> 
```
