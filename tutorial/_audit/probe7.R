## _probe7.R - sondagem final: run_plan, compare_sources, group_mca, LLM, import
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

ck("run_plan (health+descriptive)", {
  f <- tempfile(fileext = ".md")
  plan <- form_plan(analyses = c("health", "descriptive"), seed = 7)
  run_plan(x, plan, output_dir = dirname(f))
})
ck("compare_sources 2 projetos", head(compare_sources(x, as_biblio_project(head(example_biblio(), 6))), 3))
ck("group_mca keyword", head(group_mca(x, g), 3))

cat("\n===== LLM sem configuracao: comportamento real =====\n")
options(biblioIntegrator.llm = NULL)
r <- tryCatch(semantic_search(x, "silicon"), error = function(e) e)
cat("semantic_search sem config: class =", class(r)[1], if (inherits(r, "error")) paste("ERRO:", conditionMessage(r)) else "", "\n")
ck("llm_configure ollama", llm_configure(provider = "ollama"))
ck("llm_get_config", { cfg <- llm_get_config(); cfg$provider; cfg$model })
ck("llm_status verbose", llm_status())
ck("semantic_search sem servidor", tryCatch(semantic_search(x, "soil carbon"),
    error = function(e) paste("ERRO:", conditionMessage(e))))

cat("\n===== biblio_import: CSV criado =====\n")
csvf <- tempfile(fileext = ".csv")
write.csv(head(example_biblio(), 5), csvf, row.names = FALSE)
ck("biblio_import csv", { yi <- biblio_import(csvf); nrow(yi$works) })

cat("\n===== export json/parquet =====\n")
ck("json", { f <- tempfile(fileext = ".json"); export_biblio(x, f, format = "json"); file.exists(f) })
ck("parquet", { f <- tempfile(fileext = ".parquet"); export_biblio(x, f, format = "parquet"); file.exists(f) })

cat("\n===== network_communities metodos =====\n")
gco <- bibliographic_network(x, "coauthor")
for (m in c("louvain", "walktrap", "label_prop", "edge_betweenness")) {
  ck(paste0("communities ", m), network_communities(gco, method = m))
}

cat("\n===== biblio_report formatos =====\n")
ck("report html", { f <- tempfile(fileext = ".html"); biblio_report(x, f, format = "html"); file.exists(f) })

cat("\n===== form_groups matriz e funcao =====\n")
ck("matriz", { mm <- cbind(early = x$works$year <= 2021, late = x$works$year >= 2021); dim(form_groups(x, mm)) })
ck("funcao", head(form_groups(x, function(w) ifelse(w$year < 2022, "a", "b")), 2))

cat("\n===== normalized_citations strata =====\n")
ck("strata=year+source", head(normalized_citations(x, strata = c("year", "source")), 3))

cat("\n===== deduplicate: so titulo+ano (sem doi) =====\n")
d2 <- x$works; d2$doi <- NA
d2 <- rbind(d2, d2[1, ])
xd2 <- as_biblio_project(d2)
ck("dedup sem doi", { y <- deduplicate_biblio(xd2); nrow(y$works) })
