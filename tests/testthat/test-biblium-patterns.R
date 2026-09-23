test_that("citation patterns estimated mode classifies", {
  skip_if_no_biblium()
  x <- as_biblio_project(example_biblio())
  p <- biblium_citation_patterns(x, source = "estimated")
  expect_s3_class(p, "biblio_citation_patterns")
  expect_equal(p$data_source, "estimated")
  expect_equal(p$n_papers, nrow(x$works))
  expect_true(p$n_analyzed >= 1)
  known <- c("Evergreen", "Flash-in-the-pan", "Delayed Recognition",
             "Sleeping Beauty", "Normal", "Uncited", "Too Recent")
  expect_true(all(p$summary$Pattern %in% known))
  expect_equal(sum(p$summary$Count), p$n_analyzed)
})

test_that("citation patterns openalex mode degrades gracefully", {
  skip_if_no_biblium()
  testthat::skip_on_cran()
  x <- as_biblio_project(example_biblio())
  p <- biblium_citation_patterns(x, source = "openalex", max_papers = 2L)
  expect_s3_class(p, "biblio_citation_patterns")
  expect_true(p$n_analyzed >= 0)
})
