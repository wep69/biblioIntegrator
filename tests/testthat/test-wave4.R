test_that("pubmed import maps E-utilities fields", {
  testthat::skip_on_cran()
  x <- biblio_import_pubmed("aspirin[Title]", retmax = 3L)
  expect_s3_class(x, "biblio_project")
  expect_true(nrow(x$works) >= 1 && nrow(x$works) <= 3)
  expect_true(all(nzchar(x$works$title)))
  expect_error(biblio_import_pubmed("aspirin", retmax = 0L), "retmax")
})

test_that("fuzzy dedup catches near-duplicates", {
  d <- example_biblio()
  twin <- d[2, ]; twin$title <- gsub("Soil", "Soill", twin$title); twin$doi <- "10/x/fake"
  d <- rbind(d, twin)
  xe <- deduplicate_biblio(as_biblio_project(d))
  expect_equal(nrow(xe$works), 13L)
  xf <- deduplicate_biblio(as_biblio_project(d), "fuzzy")
  expect_equal(nrow(xf$works), 12L)
  expect_true(any(attr(xf, "dedup_log")$match == "fuzzy"))
  expect_error(deduplicate_biblio(as_biblio_project(d), method = "title"), "doi_title_year")
})

test_that("plots return their data invisibly", {
  x <- as_biblio_project(example_biblio())
  pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  a <- biblio_plot_annual(x); expect_equal(sum(a$n), 12L)
  t <- biblio_plot_terms(x); expect_true(nrow(t) >= 1)
  s <- biblio_plot_sources(x); expect_true(sum(s$n) == 12L)
  h <- biblio_plot_citations(x); expect_true(sum(h$counts) == 12L)
})

test_that("config gets and sets the registry", {
  c0 <- biblio_config()
  expect_true(all(c("python", "email", "cache") %in% names(c0)))
  expect_true(isTRUE(c0$cache))
  biblio_config(biblioIntegrator.cache = FALSE)
  expect_false(biblio_config()$cache)
  biblio_config(biblioIntegrator.cache = TRUE)
  expect_error(biblio_config(foo = 1), "Unknown options")
  expect_error(biblio_config(1), "named")
})
