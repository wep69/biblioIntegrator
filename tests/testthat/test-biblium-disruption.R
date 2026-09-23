test_that("validate_disruption agrees to machine precision", {
  skip_if_no_biblium()
  x <- as_biblio_project(example_biblio())
  ids <- x$works$work_id[1:5]
  x$references <- data.frame(citing_id = ids[-1], cited_id = ids[-length(ids)],
                             stringsAsFactors = FALSE)
  v <- validate_disruption(x, focal_ids = ids[1:4])
  expect_true(all(c("focal_id", "native", "biblium", "difference") %in% names(v$comparison)))
  hit <- stats::complete.cases(v$comparison$difference)
  expect_true(any(hit))
  expect_equal(max(abs(v$comparison$difference[hit])), 0, tolerance = 1e-8)
  expect_equal(v$native$N_i + v$native$N_j + v$native$N_k,
               v$biblium$N_i + v$biblium$N_j + v$biblium$N_k)
})

test_that("validate_disruption refuses missing references", {
  x <- as_biblio_project(example_biblio())
  expect_error(validate_disruption(x), "references")
})

test_that("focal itself is excluded from N_k", {
  e <- data.frame(citing_id = c("a", "f"), cited_id = c("f", "r1"))
  d <- suppressWarnings(disruption_index("f", e, "r1"))
  expect_equal(d$N_k, 0L)
})
