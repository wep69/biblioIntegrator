## _probe8.R - refazer 3 sondas silenciadas
ck_dir <- "D:/RLibrary"
if (dir.exists(ck_dir)) .libPaths(c(ck_dir, .libPaths()))
suppressPackageStartupMessages(library(biblioIntegrator))
x <- as_biblio_project(example_biblio())
plan <- form_plan(analyses = c("health", "descriptive"), seed = 7)

cat("--- run_plan assinatura ---\n")
print(formals(run_plan))
d <- tempfile(); dir.create(d)
r <- tryCatch(run_plan(x, plan, output_dir = d), error = function(e) paste("ERRO:", conditionMessage(e)))
cat("run_plan(output_dir=):", if (is.character(r)) r[1] else class(r)[1], "\n")
r2 <- tryCatch(run_plan(x, plan), error = function(e) paste("ERRO:", conditionMessage(e)))
cat("run_plan(x, plan):", class(r2)[1], if (is.character(r2) && grepl("ERRO", r2)) r2 else "", "\n")

cat("\n--- semantic_search sem servidor (3 tentativas) ---\n")
llm_configure(provider = "ollama")
for (i in 1:3) {
  r3 <- tryCatch(semantic_search(x, "soil carbon"), error = function(e) paste("ERRO:", conditionMessage(e)))
  cat("t", i, ":", substr(if (is.character(r3)) r3 else class(r3)[1], 1, 120), "\n")
}

cat("\n--- edge_betweenness (3 tentativas) ---\n")
gco <- bibliographic_network(x, "coauthor")
for (i in 1:3) {
  r4 <- tryCatch(network_communities(gco, method = "edge_betweenness"),
                 error = function(e) paste("ERRO:", conditionMessage(e)))
  cat("t", i, ":", substr(if (is.character(r4)) r4 else "OK", 1, 100), "\n")
}
