## _dryrun.R - Fase 6: ensaio seco do tutorial
ck_dir <- "D:/RLibrary"
if (dir.exists(ck_dir)) .libPaths(c(ck_dir, .libPaths()))
qmd <- "D:/Walter/R/Pacotes_criados/biblioIntegrator/tutorial/tutorial-completo.qmd"
script <- knitr::purl(qmd, output = tempfile(fileext = ".R"), documentation = 0)
cat("script extraído:", script, "\n")
r <- tryCatch(source(script, echo = FALSE, max.deparse.length = 200),
              error = function(e) conditionMessage(e))
if (is.character(r) && grepl("^ERRO|Error", r[1])) {
  cat("ERRO NO ENSAIO SECO:\n", r, "\n")
  quit(status = 1)
} else {
  cat("ensaio seco concluído sem erro.\n")
}
