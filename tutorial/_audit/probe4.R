## _probe4.R - Fase 2: sondagem restante
ck_dir <- "D:/RLibrary"
if (dir.exists(ck_dir)) .libPaths(c(ck_dir, .libPaths()))
suppressPackageStartupMessages(library(biblioIntegrator))

ck <- function(rotulo, expr) {
  cat("\n##### ", rotulo, "\n", sep = "")
  r <- tryCatch(withCallingHandlers(expr,
        warning = function(w) { cat("  AVISO:", conditionMessage(w), "\n"); invokeRestart("muffleWarning") }),
        error = function(e) paste("ERRO:", conditionMessage(e)))
  if (!is.character(r) || !grepl("^ERRO", r[1])) print(r)
  invisible(r)
}

x <- as_biblio_project(example_biblio())
g <- form_groups(x, ifelse(x$works$year < 2022, "early", "late"))

cat("\n===== validate_plan: regra das tres tentativas =====\n")
ck("modulo inexistente (t1)", validate_plan(form_plan(analyses = c("modulo_inexistente"))))
ck("modulo_inexistente misto (t2)", validate_plan(form_plan(analyses = c("health", "inexistente"))))
ck("t3: retorno invisivel?", { r <- validate_plan(form_plan(analyses = c("inexistente"))); invisible(r) })

cat("\n===== temporal =====\n")
tg <- temporal_growth(x); print(tg)
ck("citation_velocity", citation_velocity(x))
ck("citation_trajectory", head(citation_trajectory(x)))
rp <- c(2005, 2010, 2012, 2015, 2018, 2018, 2020)
ck("rpys", rpys(rpys = rpys)) # probe errado de proposito? nao - corrigir abaixo
cat("\n")
ck("rpys correto", rpys(reference_years = rp))
ck("normalized_citations year", head(normalized_citations(x), 3))

cat("\n===== texto =====\n")
ck("term_frequency title", head(term_frequency(x, field = "title"), 5))
ck("term_frequency abstract (vazio)", term_frequency(x, field = "abstract"))
ck("tfidf_terms group=year", head(tfidf_terms(x, group = "year"), 4))
ck("trend_topics", head(trend_topics(x), 4))

cat("\n===== comparativa: group_ca, group_mca, compare_sources =====\n")
cmp <- compare_groups(x, g, permutations = 49, seed = 1)
ck("group_ca", group_ca(cmp))
ck("group_mca", group_mca(x, g))
ck("compare_sources", compare_sources(x, x))
ck("compare_groups biblium engine (sem python)", compare_groups(x, g, engine = "biblium", permutations = 9))

cat("\n===== redes =====\n")
gco <- bibliographic_network(x, "coauthor")
ck("centrality", head(network_centrality(gco), 3))
ck("communities louvain", network_communities(gco, method = "louvain"))
ck("communities walktrap", network_communities(gco, method = "walktrap"))
ck("communities label_prop", network_communities(gco, method = "label_prop"))
gkw <- bibliographic_network(x, "keyword")
ck("keyword net min_weight=2", bibliographic_network(x, "keyword", min_weight = 2))
ck("biblionetwork engine", attr(bibliographic_network(x, "coauthor", engine = "biblionetwork"), "engine"))
ck("vosviewer export", { f <- tempfile(fileext = ".txt"); export_vosviewer(gco, f); file.exists(f) })

cat("\n===== storage =====\n")
ck("arrow store/load", {
  t1 <- tempfile(); dir.create(t1)
  biblio_store(x, t1, engine = "arrow")
  xa <- biblio_load(t1, engine = "arrow"); nrow(xa$works)
})
ck("duckdb store/query/load", {
  db <- tempfile(fileext = ".duckdb")
  biblio_store(x, db, engine = "duckdb")
  biblio_query(db, "SELECT year, COUNT(*) n FROM works GROUP BY year")
  xd <- biblio_load(db, engine = "duckdb"); nrow(xd$works)
})
ck("overwrite=FALSE erro", {
  t2 <- tempfile(); biblio_store(x, t2, engine = "arrow")
  biblio_store(x, t2, engine = "arrow", overwrite = FALSE)
})

cat("\n===== relatorio =====\n")
ck("report markdown", { f <- tempfile(fileext = ".md"); biblio_report(x, f); file.exists(f) })

cat("\n===== fetch_openalex (rede) =====\n")
ck("fetch_openalex live", nrow(fetch_openalex("soil carbon", n = 3)))

cat("\n===== OLLAMA ativo? =====\n")
ok <- tryCatch({
  resp <- httr2::request("http://localhost:11434/api/tags") |> httr2::req_timeout(3) |> httr2::req_perform()
  if (httr2::resp_status(resp) == 200) { cat("OLLAMA: ATIVO\n"); print(names(httr2::resp_body_json(resp)$models[[1]])) } else cat("OLLAMA: status", httr2::resp_status(resp), "\n")
  TRUE
}, error = function(e) { cat("OLLAMA: indisponivel -", conditionMessage(e), "\n"); FALSE })
