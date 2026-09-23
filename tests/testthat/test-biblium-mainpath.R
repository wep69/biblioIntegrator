chain_project <- function(n = 5) {
  x <- as_biblio_project(example_biblio())
  ids <- x$works$work_id[seq_len(n)]
  x$references <- data.frame(citing_id = ids[-1], cited_id = ids[-length(ids)],
                             stringsAsFactors = FALSE)
  x
}

test_that("main path refuses an empty citation graph", {
  x <- as_biblio_project(example_biblio())
  expect_error(biblium_main_path(x), "references")
})

test_that("main path recovers a linear citation chain", {
  skip_if_no_biblium()
  x <- chain_project(5)
  ids <- x$works$work_id[1:5]
  for (m in c("SPC", "SPLC", "SPNP")) {
    p <- biblium_main_path(x, method = m)
    expect_s3_class(p, "biblio_main_path")
    expect_equal(p$method, m)
    expect_equal(p$n_edges, 4L)
    expect_setequal(p$global_main_path, ids)
    expect_equal(p$path_length, length(p$global_main_path))
    expect_true(all(p$global_main_path %in% ids))
    expect_true(nrow(p$edge_weights) == 4L && all(p$edge_weights$weight > 0))
    expect_true(all(c(p$global_main_path, p$forward_main_path) %in% ids))
  }
})

test_that("main path documents carry work metadata", {
  skip_if_no_biblium()
  x <- chain_project(4)
  p <- biblium_main_path(x)
  expect_true(p$n_nodes >= 4L && p$n_sources >= 1L && p$n_sinks >= 1L)
  if (!is.null(p$path_documents)) {
    expect_true("node_id" %in% names(p$path_documents))
    expect_true(all(p$path_documents$node_id %in% x$works$work_id))
  }
})
