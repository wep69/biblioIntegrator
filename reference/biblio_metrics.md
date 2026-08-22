# Author-level bibliometric metrics

Author-level bibliometric metrics

## Usage

``` r
biblio_metrics(x)
```

## Arguments

- x:

  A `biblio_project`.

## Value

Author publication, citation, h-index, g-index and m-index metrics.

## Examples

``` r
biblio_metrics(as_biblio_project(example_biblio()))
#>              author documents citations h_index g_index   m_index
#> A0000043f     Rao F         3        61       3       3 0.7500000
#> A00000621    Lima D         3        62       3       3 0.6000000
#> A000008ad   Silva A         4       137       4       4 0.4444444
#> A000008c4   Costa C         3        65       3       3 0.5000000
#> A00000905   Gomez E         3       103       3       3 0.5000000
#> A00000f4d Martins B         4        97       4       4 0.6666667
#> A00000f73 Pereira W         4        93       4       4 0.5000000
head(biblio_metrics(as_biblio_project(example_biblio())),3)
#>            author documents citations h_index g_index   m_index
#> A0000043f   Rao F         3        61       3       3 0.7500000
#> A00000621  Lima D         3        62       3       3 0.6000000
#> A000008ad Silva A         4       137       4       4 0.4444444
subset(biblio_metrics(as_biblio_project(example_biblio())), documents>=2)
#>              author documents citations h_index g_index   m_index
#> A0000043f     Rao F         3        61       3       3 0.7500000
#> A00000621    Lima D         3        62       3       3 0.6000000
#> A000008ad   Silva A         4       137       4       4 0.4444444
#> A000008c4   Costa C         3        65       3       3 0.5000000
#> A00000905   Gomez E         3       103       3       3 0.5000000
#> A00000f4d Martins B         4        97       4       4 0.6666667
#> A00000f73 Pereira W         4        93       4       4 0.5000000
```
