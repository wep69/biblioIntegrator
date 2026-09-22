ck_dir <- "D:/RLibrary"
if (dir.exists(ck_dir)) .libPaths(c(ck_dir, .libPaths()))
suppressPackageStartupMessages(library(biblioIntegrator))
s <- readLines("_setup_corpora.R")
s <- s[!grepl("^per_B|^tema_B|^g_per|^g_tema|x_analise\\$works\\$periodo", s)]
writeLines(s, "_tmp_setup.R")
source("_tmp_setup.R")

cat("nrow works:", nrow(x_analise$works), "\n")
cat("length year:", length(x_analise$works$year), "\n")
per <- ifelse(x_analise$works$year >= 2020, "recente", "inicial")
cat("class(per):", class(per), "| length:", length(per), "| NAs:", sum(is.na(per)), "\n")
print(table(per))
r <- tryCatch(form_groups(x_analise, per), error = function(e) conditionMessage(e))
if (is.character(r)) cat("ERRO form_groups:", r, "\n") else cat("form_groups OK:", paste(dim(r), collapse = "x"), "\n")
r2 <- tryCatch(form_groups(x_analise, x_analise$works$tema), error = function(e) conditionMessage(e))
if (is.character(r2)) cat("ERRO form_groups tema:", r2, "\n") else cat("form_groups tema OK:", paste(dim(r2), collapse = "x"), "\n")
