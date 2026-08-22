# Multiple correspondence analysis of group and entity presence

Multiple correspondence analysis of group and entity presence

## Usage

``` r
group_mca(x, groups, entity = c("keyword", "author"), ncp = 2)
```

## Arguments

- x:

  A `biblio_project`.

- groups:

  Group definition.

- entity:

  Entity type.

- ncp:

  Number of dimensions.

## Value

A [`FactoMineR::MCA`](https://rdrr.io/pkg/FactoMineR/man/MCA.html)
result.

## Examples

``` r
# \donttest{
x <- as_biblio_project(example_biblio()); g <- rep(c("a","b"),6)
if (requireNamespace("FactoMineR",quietly=TRUE)) group_mca(x,g,ncp=2)
#> **Results of the Multiple Correspondence Analysis (MCA)**
#> The analysis was performed on 12 individuals, described by 26 variables
#> *The results are available in the following objects:
#> 
#>    name              description                       
#> 1  "$eig"            "eigenvalues"                     
#> 2  "$var"            "results for the variables"       
#> 3  "$var$coord"      "coord. of the categories"        
#> 4  "$var$cos2"       "cos2 for the categories"         
#> 5  "$var$contrib"    "contributions of the categories" 
#> 6  "$var$v.test"     "v-test for the categories"       
#> 7  "$var$eta2"       "coord. of variables"             
#> 8  "$ind"            "results for the individuals"     
#> 9  "$ind$coord"      "coord. for the individuals"      
#> 10 "$ind$cos2"       "cos2 for the individuals"        
#> 11 "$ind$contrib"    "contributions of the individuals"
#> 12 "$call"           "intermediate results"            
#> 13 "$call$marge.col" "weights of columns"              
#> 14 "$call$marge.li"  "weights of rows"                 
if (requireNamespace("FactoMineR",quietly=TRUE)) group_mca(x,cbind(a=1:12<=7,b=1:12>=5),ncp=1)
#> **Results of the Multiple Correspondence Analysis (MCA)**
#> The analysis was performed on 12 individuals, described by 26 variables
#> *The results are available in the following objects:
#> 
#>    name              description                       
#> 1  "$eig"            "eigenvalues"                     
#> 2  "$var"            "results for the variables"       
#> 3  "$var$coord"      "coord. of the categories"        
#> 4  "$var$cos2"       "cos2 for the categories"         
#> 5  "$var$contrib"    "contributions of the categories" 
#> 6  "$var$v.test"     "v-test for the categories"       
#> 7  "$var$eta2"       "coord. of variables"             
#> 8  "$ind"            "results for the individuals"     
#> 9  "$ind$coord"      "coord. for the individuals"      
#> 10 "$ind$cos2"       "cos2 for the individuals"        
#> 11 "$ind$contrib"    "contributions of the individuals"
#> 12 "$call"           "intermediate results"            
#> 13 "$call$marge.col" "weights of columns"              
#> 14 "$call$marge.li"  "weights of rows"                 
if (requireNamespace("FactoMineR",quietly=TRUE)) names(group_mca(x,g,ncp=2))
#> [1] "eig"  "call" "ind"  "var"  "svd" 
# }
```
