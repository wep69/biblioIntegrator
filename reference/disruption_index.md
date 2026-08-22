# Disruption index from citation relations

Uses the CD-style definition `(N_i - N_j)/(N_i + N_j + N_k)`, where
`N_i` cites the focal work but not its references, `N_j` cites both, and
`N_k` cites focal references but not the focal work.

## Usage

``` r
disruption_index(focal_id, citation_edges, focal_references)
```

## Arguments

- focal_id:

  Focal work identifier.

- citation_edges:

  Data frame with `citing_id` and `cited_id`.

- focal_references:

  IDs cited by the focal work.

## Value

A one-row data frame.

## Examples

``` r
e <- data.frame(
  citing_id = c("a", "b", "b", "c"),
  cited_id = c("f", "f", "r1", "r1")
)
disruption_index("f", e, "r1")
#>   focal_id N_i N_j N_k disruption
#> 1        f   1   1   1          0
disruption_index("f",e,c("r1","r2"))
#>   focal_id N_i N_j N_k disruption
#> 1        f   1   1   1          0
disruption_index("f",data.frame(citing_id="a",cited_id="f"),character())
#>   focal_id N_i N_j N_k disruption
#> 1        f   1   0   0          1
```
