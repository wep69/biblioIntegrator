test_that("geo refuses unenriched projects", {
  x <- as_biblio_project(example_biblio())
  expect_error(biblium_geo(x), "enrich_countries")
})

test_that("geo counts mock countries without network", {
  skip_if_no_biblium()
  x <- as_biblio_project(example_biblio())
  x$works$country <- rep(c("Brazil", "United States", "Germany"), 4)
  g <- biblium_geo(x)
  expect_s3_class(g, "biblio_geo")
  expect_true(g$n_countries >= 3)
  expect_true(any(grepl("Brazil|Country", names(g$table), ignore.case = TRUE)))
})

test_that("enrichment resolves a real DOI and caches", {
  testthat::skip_on_cran()
  d <- data.frame(title = "test", year = 2013, doi = "10.1038/nature12373",
                  authors = "A", keywords = "k", citations = 1, source = "S",
                  stringsAsFactors = FALSE)
  x <- as_biblio_project(d)
  x <- enrich_countries(x, use_cache = FALSE)
  expect_true(!is.na(x$works$country) && nzchar(x$works$country))
  x2 <- enrich_countries(as_biblio_project(d), use_cache = TRUE)
  expect_equal(x2$works$country, x$works$country)
})
