test_that("to_biblium carries the canonical columns incl. Source", {
  x <- as_biblio_project(example_biblio())
  b <- to_biblium(x)
  expect_true(all(c("Title", "Year", "Authors", "Author Keywords", "Source") %in% names(b)))
  expect_equal(nrow(b), nrow(x$works))
  expect_equal(b$Source, as.character(x$works$source))
})

test_that("diversity level=group requires groups", {
  x <- as_biblio_project(example_biblio())
  expect_error(biblium_diversity(x, level = "group"), "groups")
})

test_that("diversity stops cleanly without backend", {
  x <- as_biblio_project(example_biblio())
  testthat::skip_if(isTRUE(tryCatch(biblium_backend_status()$available, error = function(e) FALSE)),
                    "backend available; nothing to stop on")
  expect_error(biblium_diversity(x), "unavailable")
})

test_that("biblium_diversity overall returns indices", {
  skip_if_no_biblium()
  x <- as_biblio_project(example_biblio())
  d <- biblium_diversity(x, entity = "author")
  expect_s3_class(d, "biblio_diversity")
  expect_equal(d$engine, "biblium")
  expect_true(all(c("Shannon Index", "Simpson Diversity", "Gini Index") %in% names(d$indices)))
  expect_true(is.character(d$summary) && nzchar(d$summary))
})

test_that("biblium_diversity temporal returns yearly series", {
  skip_if_no_biblium()
  x <- as_biblio_project(example_biblio())
  d <- biblium_diversity(x, entity = "keyword", level = "temporal", min_items_per_year = 1L)
  expect_true("Year" %in% names(d$indices))
  expect_true(nrow(d$indices) >= 1)
  expect_true(!is.null(d$trend))
})

test_that("biblium_diversity group splits by membership", {
  skip_if_no_biblium()
  x <- as_biblio_project(example_biblio())
  g <- ifelse(x$works$year < 2022, "early", "late")
  d <- biblium_diversity(x, level = "group", groups = g)
  expect_true("Group" %in% names(d$indices))
  expect_equal(sort(unique(d$indices$Group)), c("early", "late"))
})

test_that("refactored biblium_compare_groups keeps contract", {
  skip_if_no_biblium()
  x <- as_biblio_project(example_biblio())
  g <- rep(c("early", "late"), 6)
  expect_warning(
    b <- biblium_compare_groups(x, g, permutations = 99, seed = 1),
    "disjoint"
  )
  expect_s3_class(b, "biblio_group_comparison")
  expect_equal(b$engine, "biblium")
  expect_true(is.numeric(b$chi_square) && is.numeric(b$cramers_v))
})
