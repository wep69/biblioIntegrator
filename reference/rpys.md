# Reference publication year spectroscopy

Reference publication year spectroscopy

## Usage

``` r
rpys(reference_years, window = 2)
```

## Arguments

- reference_years:

  Numeric vector of cited-reference publication years.

- window:

  Running-median half-window.

## Value

Year counts, baseline and deviations.

## Examples

``` r
rpys(c(1990,1990,1991,2000,2000,2000,2001))
#>    year n baseline deviation
#> 1  1990 2      1.0       1.0
#> 2  1991 1      0.5       0.5
#> 3  1992 0      0.0       0.0
#> 4  1993 0      0.0       0.0
#> 5  1994 0      0.0       0.0
#> 6  1995 0      0.0       0.0
#> 7  1996 0      0.0       0.0
#> 8  1997 0      0.0       0.0
#> 9  1998 0      0.0       0.0
#> 10 1999 0      0.0       0.0
#> 11 2000 3      0.5       2.5
#> 12 2001 1      1.0       0.0
rpys(sample(1990:2020,100,replace=TRUE),window=2)
#>    year n baseline deviation
#> 1  1990 4      4.0       0.0
#> 2  1991 4      4.0       0.0
#> 3  1992 3      4.0      -1.0
#> 4  1993 5      4.0       1.0
#> 5  1994 3      4.0      -1.0
#> 6  1995 6      4.0       2.0
#> 7  1996 4      4.0       0.0
#> 8  1997 2      4.0      -2.0
#> 9  1998 4      4.0       0.0
#> 10 1999 4      4.0       0.0
#> 11 2000 3      4.0      -1.0
#> 12 2001 5      4.0       1.0
#> 13 2002 4      3.0       1.0
#> 14 2003 3      4.0      -1.0
#> 15 2004 3      3.0       0.0
#> 16 2005 5      3.0       2.0
#> 17 2006 2      3.0      -1.0
#> 18 2007 4      2.0       2.0
#> 19 2008 1      2.0      -1.0
#> 20 2009 0      1.0      -1.0
#> 21 2010 3      1.0       2.0
#> 22 2011 0      3.0      -3.0
#> 23 2012 3      3.0       0.0
#> 24 2013 5      3.0       2.0
#> 25 2014 2      3.0      -1.0
#> 26 2015 4      3.0       1.0
#> 27 2016 3      3.0       0.0
#> 28 2017 3      3.0       0.0
#> 29 2018 5      3.0       2.0
#> 30 2019 2      2.5      -0.5
#> 31 2020 1      2.0      -1.0
subset(rpys(c(rep(2000,10),1995:2005)), deviation>0)
#>   year  n baseline deviation
#> 6 2000 11        1        10
```
