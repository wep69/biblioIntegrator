# Testes de regressao dos achados B do tutorial auditado
# (tutorial/RELATORIO-AO-AUTOR.md, achados B1-B15)

test_that("B1: work_id e unico mesmo em titulos com molde fixo", {
  set.seed(1)
  d <- data.frame(
    title = sprintf("Estudo de silicio em soja (estudo %03d)", 1:280),
    year = sample(2015:2025, 280, TRUE),
    doi = paste0("10.1/x.", 1:280),
    authors = sprintf("Silva A; Costa B; autor %03d", 1:280),
    keywords = "silicio; salinidade", citations = 1:280, source = "J",
    stringsAsFactors = FALSE)
  p <- suppressWarnings(as_biblio_project(d))
  expect_equal(length(unique(p$works$work_id)), nrow(p$works))
  # a juncao por work_id nao pode inflar os vinculos de autoria
  expect_equal(nrow(merge(p$authorships, p$works["work_id"])), nrow(p$authorships))
})

test_that("B2: biblio_health recusa entrada que nao e biblio_project", {
  expect_error(biblio_health(example_biblio()), "biblio_project")
  expect_silent(biblio_health(as_biblio_project(example_biblio())))
})

test_that("B3: biblio_query recusa diretorio Arrow com mensagem orientadora", {
  skip_if_not_installed("arrow")
  skip_if_not_installed("duckdb")
  skip_if_not_installed("DBI")
  p <- tempfile()
  on.exit(unlink(p, recursive = TRUE), add = TRUE)
  biblio_store(as_biblio_project(example_biblio()), p, "arrow")
  expect_error(biblio_query(p, "SELECT 1"), "DuckDB file")
})

test_that("B4: deduplicate_biblio recusa metodo nao implementado", {
  x <- as_biblio_project(example_biblio())
  expect_error(deduplicate_biblio(x, method = "title"), "doi_title_year")
  expect_s3_class(deduplicate_biblio(x), "biblio_project")
})

test_that("B5: disruption_index devolve NA quando ninguem cita o focal", {
  e <- data.frame(citing_id = c("a", "b"), cited_id = c("r1", "r2"))
  expect_warning(r <- disruption_index("ausente", e, "r1"), "Nenhum citante")
  expect_true(is.na(r$disruption))
  expect_equal(r$N_i, NA_integer_)
  # caso normal continua calculando
  ok <- disruption_index("f", data.frame(citing_id = c("a", "b"), cited_id = c("f", "f")), "r1")
  expect_equal(ok$N_i, 2L)
})

test_that("B6: stopwords do usuario sao acrescentadas a lista padrao", {
  d <- data.frame(title = "The effect of silicon in rice under salinity",
                  year = 2020, doi = "10.1/a", authors = "A B",
                  keywords = "silicon", citations = 1, source = "J",
                  stringsAsFactors = FALSE)
  tf <- term_frequency(as_biblio_project(d), stopwords = "silicon")
  expect_false("the" %in% tf$term)
  expect_false("silicon" %in% tf$term)
})

test_that("B7: validacao de entrada e aviso de campo vazio", {
  expect_error(fetch_openalex("x", n = 0), "positive")
  expect_error(fetch_openalex(""), "non-empty")
  expect_warning(term_frequency(as_biblio_project(example_biblio()), field = "abstract"),
                 "vazio")
})

test_that("B10: retorno de modelo com celulas vazias avisa", {
  ruim <- data.frame(work_id = NA_character_, score = NA_real_,
                     stringsAsFactors = FALSE)
  expect_warning(biblioIntegrator:::.llm_check_return(ruim, c("work_id", "score")),
                 "vazias")
  expect_error(biblioIntegrator:::.llm_check_return(data.frame(a = 1), "work_id"),
               "colunas esperadas")
})

test_that("B13: o motor nativo nao duplica pares de coautores", {
  set.seed(2)
  d <- data.frame(
    title = sprintf("Estudo %03d", 1:60), year = 2020,
    doi = paste0("10.1/y.", 1:60),
    authors = sprintf("Silva A; Costa B; Pereira C; autor %03d", 1:60),
    keywords = "silicio", citations = 1, source = "J", stringsAsFactors = FALSE)
  g <- bibliographic_network(as_biblio_project(d), "coauthor", engine = "native")
  el <- igraph::as_edgelist(g)
  pares <- apply(el, 1, function(z) paste(sort(z), collapse = "|"))
  expect_false(any(duplicated(pares)))
  expect_lte(max(igraph::degree(g)), igraph::vcount(g) - 1)
  if (requireNamespace("biblionetwork", quietly = TRUE)) {
    gb <- bibliographic_network(as_biblio_project(d), "coauthor", engine = "biblionetwork")
    expect_equal(igraph::ecount(g), igraph::ecount(gb))
  }
})

test_that("B14: network_stability registra motor e medida usados", {
  x <- as_biblio_project(example_biblio())
  st <- network_stability(x, B = 3, seed = 1, measure = "strength", engine = "native")
  expect_true(all(c("engine", "measure") %in% names(st)))
  expect_equal(unique(st$engine), "native")
  expect_equal(unique(st$measure), "strength")
})

test_that("B15: casos-limite devolvem recusa ou NA em vez de numero", {
  x <- as_biblio_project(example_biblio())
  g <- ifelse(x$works$year < 2022, "a", "b")

  sa <- sensitivity_analysis(x, g, thresholds = 1:2, permutations = 19, seed = 1)
  expect_true(all(c("chi_square", "permutations") %in% names(sa)))

  cs <- compare_sources(example_biblio())
  expect_equal(nrow(cs$coverage), 1L)
  expect_equal(nrow(cs$overlap), 0L)

  cg <- compare_groups(x, g, permutations = 0)
  expect_equal(cg$p_method, "asymptotic (Pearson chi-square)")

  gc_ <- bibliographic_network(x, "citation")
  expect_equal(igraph::vcount(gc_), 0L)

  expect_equal(colnames(form_groups(x, g)), c("a", "b"))
  expect_error(form_groups(x, rep("a", nrow(x$works))), "dois niveis")
  expect_error(form_groups(x, c(rep("a", nrow(x$works) - 1), NA)), "ausentes")
})
