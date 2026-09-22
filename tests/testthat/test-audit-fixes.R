# Testes de regressao dos achados do tutorial auditado
# (tutorial/RELATORIO-AO-AUTOR.md, achados A1-A5)

test_that("A1: LLM backend nao passa seed invalido a chat_ollama", {
  old <- options(biblioIntegrator.llm = NULL)
  on.exit(options(old), add = TRUE)
  llm_configure(provider = "ollama", base_url = "http://127.0.0.1:1")
  x <- as_biblio_project(example_biblio())
  e <- tryCatch(semantic_search(x, "soil carbon"), error = function(e) e)
  expect_true(inherits(e, "error"))
  expect_false(grepl("unused argument", conditionMessage(e)))
})

test_that("A2: identificadores OpenCitations sao normalizados para PID doi:", {
  pid <- biblioIntegrator:::.oc_pid
  expect_equal(pid("10.1038/nature12373"), "doi:10.1038/nature12373")
  expect_equal(pid("doi:10.1038/nature12373"), "doi:10.1038/nature12373")
  expect_equal(pid("pmid:12345"), "pmid:12345")
  expect_equal(pid("https://doi.org/10.1000/xyz"), "doi:10.1000/xyz")
  expect_error(pid(""), "empty")
})

test_that("A3: biblio_store recusa caminho existente sem overwrite = TRUE", {
  x <- as_biblio_project(example_biblio())
  skip_if_not_installed("arrow")
  p <- tempfile(); on.exit(unlink(p, recursive = TRUE), add = TRUE)
  biblio_store(x, p, "arrow")
  expect_error(biblio_store(x, p, "arrow", overwrite = FALSE), "path exists")
  expect_type(biblio_store(x, p, "arrow", overwrite = TRUE), "character")
  skip_if_not_installed("duckdb")
  skip_if_not_installed("DBI")
  p2 <- tempfile(fileext = ".duckdb"); on.exit(unlink(p2), add = TRUE)
  biblio_store(x, p2, "duckdb")
  expect_error(biblio_store(x, p2, "duckdb", overwrite = FALSE), "path exists")
  expect_type(biblio_store(x, p2, "duckdb", overwrite = TRUE), "character")
})

test_that("A4: disruption_index valida colunas citing_id/cited_id", {
  expect_error(disruption_index("W1", data.frame(citing = "a", cited = "b"), character()),
               "citing_id")
  d <- disruption_index("f", data.frame(citing_id = "a", cited_id = "f"), character())
  expect_equal(as.numeric(d$N_i), 1)
  expect_equal(as.numeric(d$disruption), 1)
})

test_that("A5: funcoes estocasticas preservam o .Random.seed do usuario", {
  x <- as_biblio_project(example_biblio())
  g <- ifelse(x$works$year < 2022, "a", "b")
  calls <- list(
    function() compare_groups(x, g, permutations = 9, seed = 1),
    function() network_stability(x, B = 3, seed = 1),
    function() sensitivity_analysis(x, g, thresholds = 1:2, permutations = 9, seed = 1),
    function() run_plan(form_plan(analyses = "health"), example_biblio())
  )
  for (fn in calls) {
    set.seed(111); before <- .Random.seed
    invisible(fn())
    expect_identical(.Random.seed, before)
  }
})
