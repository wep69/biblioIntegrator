## _probe1.R - Fase 1: inventario completo da API
ck_dir <- "D:/RLibrary"
if (dir.exists(ck_dir)) .libPaths(c(ck_dir, .libPaths()))
suppressPackageStartupMessages(library(biblioIntegrator))

ns  <- asNamespace("biblioIntegrator")
exp <- sort(getNamespaceExports("biblioIntegrator"))

cat("versao:", as.character(packageVersion("biblioIntegrator")), "\n")
cat("exportadas:", length(exp), "\n\n")

for (f in exp) {
  fo <- try(formals(get(f, envir = ns)), silent = TRUE)
  cat("\n===", f, "===\n")
  if (!inherits(fo, "try-error")) {
    for (n in names(fo)) {
      v <- paste(deparse(fo[[n]]), collapse = " ")
      cat(sprintf("  %-22s = %s\n", n,
          if (!nzchar(trimws(v))) "<obrigatorio>" else substr(v, 1, 70)))
    }
  } else cat("  (nao-funcao)\n")
}

cat("\n\n=== metodos S3 ===\n")
print(sort(ls(ns)))
