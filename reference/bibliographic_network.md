# Build a bibliographic network

Build a bibliographic network

## Usage

``` r
bibliographic_network(
  x,
  type = c("coauthor", "keyword", "citation"),
  engine = c("auto", "native", "biblionetwork"),
  min_weight = 1,
  counting = c("full_counting", "fractional_counting", "fractional_counting_refined")
)
```

## Arguments

- x:

  A `biblio_project`.

- type:

  `"coauthor"`, `"keyword"`, or `"citation"`.

- engine:

  `"native"`, `"biblionetwork"`, or `"auto"`.

- min_weight:

  Minimum edge weight retained.

- counting:

  Counting scheme for biblionetwork coauthorship.

## Value

An igraph object with an `engine` attribute.

## Examples

``` r
x <- as_biblio_project(example_biblio()); bibliographic_network(x,"coauthor")
#> IGRAPH 0ef369d UNW- 7 10 -- 
#> + attr: name (v/c), weight (e/n)
#> + edges from 0ef369d (vertex names):
#>  [1] A000008c4--A00000621 A00000905--A000008ad A000008c4--A00000f4d
#>  [4] A00000f4d--A00000f73 A00000f4d--A0000043f A000008c4--A0000043f
#>  [7] A00000f73--A000008ad A00000f4d--A00000621 A00000905--A0000043f
#> [10] A00000f73--A00000621
bibliographic_network(x,"keyword",min_weight=1)
#> IGRAPH 41e0117 UNW- 24 28 -- 
#> + attr: name (v/c), weight (e/n)
#> + edges from 41e0117 (vertex names):
#>  [1] cover crops    --aggregation    cover crops    --soil carbon   
#>  [3] silicon        --drought        maize          --efficiency    
#>  [5] nitrogen       --efficiency     maize          --drought       
#>  [7] maize          --nitrogen       silicon        --maize         
#>  [9] climate-smart  --management     soil           --management    
#> [11] silicon        --meta-analysis  nitrogen       --remote sensing
#> [13] nitrogen       --soybean        soybean        --phenotyping   
#> [15] uav            --phenotyping    salinity       --rice          
#> + ... omitted several edges
if (requireNamespace("biblionetwork", quietly = TRUE)) {
  bibliographic_network(x, "coauthor", engine = "biblionetwork")
}
#> IGRAPH fb4a862 UNW- 7 10 -- 
#> + attr: name (v/c), weight (e/n)
#> + edges from fb4a862 (vertex names):
#>  [1] A000008c4--A00000621 A00000905--A000008ad A000008c4--A00000f4d
#>  [4] A00000f4d--A00000f73 A00000f4d--A0000043f A000008c4--A0000043f
#>  [7] A00000f73--A000008ad A00000f4d--A00000621 A00000905--A0000043f
#> [10] A00000f73--A00000621
```
