test_that("topics guards tiny corpora", {
  d <- data.frame(title = c("a b", "c d"), year = 2020, doi = c("10/x/1", "10/x/2"),
                  authors = "A", keywords = "k", citations = 1, source = "S",
                  stringsAsFactors = FALSE)
  x <- as_biblio_project(d)
  expect_error(biblium_topics(x, n_topics = 2), "four non-empty")
})

test_that("LDA returns topics with terms and coherence", {
  skip_if_no_biblium()
  x <- as_biblio_project(example_biblio())
  t <- biblium_topics(x, n_topics = 2L)
  expect_s3_class(t, "biblio_topics")
  expect_equal(t$model, "LDA")
  expect_true(all(c("topic", "terms", "coherence") %in% names(t$summary)))
  expect_equal(nrow(t$summary), 2L)
  expect_true(all(nzchar(t$summary$terms)))
})
