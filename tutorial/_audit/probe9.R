## _probe9.R - run_plan correto + causa provavel do erro LLM
ck_dir <- "D:/RLibrary"
if (dir.exists(ck_dir)) .libPaths(c(ck_dir, .libPaths()))
suppressPackageStartupMessages(library(biblioIntegrator))
x <- as_biblio_project(example_biblio())

cat("--- assinaturas reais ---\n")
print(formals(run_plan)); cat("\n")
print(formals(compare_sources)); cat("\n")

plan <- form_plan(analyses = c("health", "descriptive"), seed = 7)
d <- tempfile(); dir.create(d)
r <- tryCatch(run_plan(plan, data = x), error = function(e) paste("ERRO:", conditionMessage(e)))
cat("run_plan(plan, data=x):", class(r)[1], if (is.character(r) && grepl("ERRO", r)) r else "OK\n")
cat("arquivos gerados no cwd/temp dir?\n")
print(list.files(tempdir(), pattern = "biblio", all.files = TRUE)[1:5])

cat("\n--- causa provavel do erro LLM: chat_ollama aceita seed? ---\n")
if (requireNamespace("ellmer", quietly = TRUE)) {
  cat("formals(chat_ollama):", paste(names(formals(ellmer::chat_ollama)), collapse = ", "), "\n")
}
cat("\n--- fetch_opencitations (3 tentativas, rede) ---\n")
for (i in 1:3) {
  r <- tryCatch(fetch_opencitations("10.1038/nature12373"), error = function(e) paste("ERRO:", conditionMessage(e)))
  cat("t", i, ":", substr(if (is.character(r)) r else "OK", 1, 80), "\n")
}
