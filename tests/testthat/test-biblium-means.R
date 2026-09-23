test_that("compare_means guards group input", {
  x <- as_biblio_project(example_biblio())
  expect_error(
    biblium_compare_means(x, groups = cbind(a = rep(0:1, 6), b = rep(1:0, 6))),
    "single categorical"
  )
  expect_error(biblium_compare_means(x, groups = rep("only", 12)), "two groups")
  expect_error(biblium_compare_means(x, groups = c("a", "b")), "one entry per work")
})

test_that("compare_means two groups returns full inference", {
  skip_if_no_biblium()
  x <- as_biblio_project(example_biblio())
  m <- biblium_compare_means(x, groups = ifelse(x$works$year < 2022, "early", "late"))
  expect_s3_class(m, "biblio_means_comparison")
  expect_equal(m$engine, "biblium")
  expect_equal(m$n_groups, 2L)
  expect_true(nzchar(m$recommended_test))
  expect_true(nzchar(m$interpretation))
  expect_equal(nrow(m$descriptives), 3L)
  expect_true(all(c("mean", "median") %in% names(m$descriptives)))
  expect_true(all(c("test_name", "statistic", "p_value") %in% names(m$tests)))
  expect_true(all(m$tests$p_value >= 0 & m$tests$p_value <= 1))
  expect_true(nzchar(m$tests$effect_size_name[1]) || nzchar(m$tests$effect_size_name[2]))
  expect_null(m$posthoc)
})

test_that("compare_means three groups adds post-hoc", {
  skip_if_no_biblium()
  set.seed(11)
  d <- data.frame(title = paste0("w", 1:45), year = 2020,
                  doi = paste0("10/x/", 1:45), authors = "A", keywords = "k",
                  citations = c(rnorm(15, 50, 3), rnorm(15, 30, 3), rnorm(15, 10, 3)),
                  source = "S", stringsAsFactors = FALSE)
  x <- as_biblio_project(d)
  m <- biblium_compare_means(x, groups = rep(c("hi", "mid", "lo"), each = 15))
  expect_equal(m$n_groups, 3L)
  expect_true(!is.null(m$posthoc) && nrow(m$posthoc) >= 1)
  expect_true(nzchar(m$post_hoc_method))
})

test_that("compare_means agrees with R t.test on clear-cut data", {
  skip_if_no_biblium()
  set.seed(7)
  d <- data.frame(title = paste0("w", 1:40), year = rep(2020:2021, each = 20),
                  doi = paste0("10/x/", 1:40), authors = "A", keywords = "k",
                  citations = c(rnorm(20, 50, 3), rnorm(20, 20, 3)), source = "S",
                  stringsAsFactors = FALSE)
  x <- as_biblio_project(d)
  m <- biblium_compare_means(x, groups = rep(c("hi", "lo"), each = 20))
  tt <- t.test(citations ~ rep(c("hi", "lo"), each = 20), data = d)
  expect_true(any((m$tests$p_value < 0.05) == (tt$p.value < 0.05)))
})
