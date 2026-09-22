ck_dir <- "D:/RLibrary"
if (dir.exists(ck_dir)) .libPaths(c(ck_dir, .libPaths()))
Sys.setenv(BIBLIOINTEGRATOR_PYTHON = "H:/uv/AppDataLocalUv/cache/archive-v0/MfuOKTFtveE-Nd3l_RFiM/Scripts/python.exe")
suppressPackageStartupMessages(library(biblioIntegrator))

pbs <- python_backend_status()
cat("python:", pbs$available, "| versao:", pbs$version, "\n")

x <- as_biblio_project(example_biblio())
g <- ifelse(x$works$year < 2022, "early", "late")

# 1) comparação nativa
cmpN <- compare_groups(x, g, entity = "keyword", permutations = 199, seed = 7)
cat("NATIVO  -> chi:", round(cmpN$chi_square, 3), " p:", cmpN$p_value, " V:", round(cmpN$cramers_v, 4), "\n")

# 2) comparação Biblium (Python) - a rota que o tutorial vai demonstrar
cmpB <- tryCatch(biblium_compare_groups(x, g, entity = "keyword", permutations = 199, seed = 7),
                 error = function(e) conditionMessage(e))
if (inherits(cmpB, "biblio_group_comparison")) {
  cat("BIBLIUM -> chi:", round(cmpB$chi_square, 3), " p:", cmpB$p_value, " V:", round(cmpB$cramers_v, 4), "\n")
} else {
  cat("BIBLIUM FALHOU:", cmpB, "\n")
}

# 3) validate_biblium (validação cruzada dos dois motores)
vb <- tryCatch(validate_biblium(x, g, entity = "keyword", permutations = 199, seed = 7),
               error = function(e) conditionMessage(e))
if (is.list(vb) && !is.null(vb$comparison)) { cat("\n--- validate_biblium ---\n"); print(vb$comparison) }
else cat("validate_biblium FALHOU:", vb, "\n")

# 4) to_biblium (exportação para o formato canônico do Python)
bu <- to_biblium(x); cat("\nto_biblium: ", nrow(bu), "linhas |", paste(names(bu), collapse = ", "), "\n")
