test_that("sdg returns binary flags per work", {
  skip_if_no_biblium()
  x <- as_biblio_project(example_biblio())
  s <- biblium_sdg(x, text = "title")
  expect_s3_class(s, "biblio_sdg")
  expect_equal(nrow(s$flags), nrow(x$works))
  expect_true(any(grepl("^SDG", names(s$flags))))
  hits <- s$flags[, grepl("^SDG", names(s$flags)), drop = FALSE]
  expect_true(all(unlist(hits) %in% c(0, 1)))
})

test_that("classifier separates distinct vocabularies", {
  skip_if_no_biblium()
  set.seed(3)
  d <- data.frame(title = c(paste("quantum photon entanglement", 1:20),
                            paste("maize soil nitrogen", 1:20)),
                  year = 2020, doi = paste0("10/x/", 1:40),
                  authors = "A", keywords = "k", citations = 5, source = "S",
                  stringsAsFactors = FALSE)
  x <- as_biblio_project(d)
  c <- biblium_classify_groups(x, rep(c("phys", "agri"), each = 20))
  expect_s3_class(c, "biblio_group_classification")
  expect_true(all(c("group", "model", "accuracy") %in% names(c$performance)))
  expect_true(max(c$performance$accuracy, na.rm = TRUE) >= 0.8)
})

test_that("classifier refuses tiny groups", {
  x <- as_biblio_project(example_biblio())
  expect_error(biblium_classify_groups(x, c(rep("a", 11), "b")), "two works")
})
