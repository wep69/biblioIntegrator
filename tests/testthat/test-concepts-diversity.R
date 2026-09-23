test_that("ngrams count adjacent tokens", {
  x <- as_biblio_project(example_biblio())
  u <- concept_ngrams(x, n = 1L)
  tf <- term_frequency(x)
  expect_equal(sum(u$n), sum(tf$n))
  b <- concept_ngrams(x, n = 2L)
  expect_true(all(grepl(" ", b$ngram)))
  expect_true(all(diff(b$n) <= 0))
  expect_error(concept_ngrams(x, n = 0L), ">= 1")
})

test_that("cooccurrence is symmetric with doc-frequency diagonal", {
  x <- as_biblio_project(example_biblio())
  C <- concept_cooccurrence(x, top_n = 10L)
  expect_equal(dim(C), c(10L, 10L))
  expect_equal(unname(C), unname(t(C)))
  tf <- term_frequency(x)
  dg <- unname(diag(C))
  expect_true(all(dg >= 1))
  expect_true(all(dg <= tf$n[match(rownames(C), tf$term)]))
})

test_that("reference diversity matches Biblium Rao-Stirling", {
  x <- as_biblio_project(example_biblio())
  d <- reference_diversity(x, by = "source")
  expect_true(d$shannon > 0 && d$simpson >= 0 && d$simpson <= 1)
  expect_true(d$gini >= 0 && d$gini <= 1)
  expect_equal(d$rao_stirling, d$simpson)
  skip_if_no_biblium()
  s <- table(x$works$source)
  ans <- biblioIntegrator:::.bi_bridge_call("rao_stirling",
    list(as.integer(s), names(s)))
  expect_equal(d$rao_stirling, ans$rao_stirling, tolerance = 1e-8)
})
