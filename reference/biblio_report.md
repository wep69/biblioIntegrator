# Generate an automated bibliometric report

Produces an auditable report with corpus health, descriptive metrics,
annual growth, leading terms, network centrality, backend availability
and provenance.

## Usage

``` r
biblio_report(
  x,
  output_file = "biblio-report.md",
  format = c("markdown", "html", "docx", "pdf"),
  title = "Bibliometric Analysis Report"
)
```

## Arguments

- x:

  A data frame or `biblio_project`.

- output_file:

  Destination file.

- format:

  `"markdown"`, `"html"`, `"docx"`, or `"pdf"`.

- title:

  Report title.

## Value

Normalized report path.

## Examples

``` r
f<-tempfile(fileext=".md"); biblio_report(example_biblio(),f); file.exists(f)
#> [1] "/tmp/RtmpTNcht6/file1ace3629bbd7.md"
#> [1] TRUE
f <- tempfile(fileext = ".md")
x <- as_biblio_project(example_biblio())
biblio_report(x, f, title = "Agronomy map")
#> [1] "/tmp/RtmpTNcht6/file1ace76cdef63.md"
# \donttest{
if (requireNamespace("rmarkdown", quietly = TRUE)) {
  f <- tempfile(fileext = ".html")
  biblio_report(example_biblio(), f, "html")
}
#> [1] "/tmp/RtmpTNcht6/file1ace7e9a4a87.html"
# }
```
