## _auditoria/_check_fragmentos.R - isola erros de código por fragmento
ck_dir <- "D:/RLibrary"
if (dir.exists(ck_dir)) .libPaths(c(ck_dir, .libPaths()))
setwd("D:/Walter/R/Pacotes_criados/Tutoriais/biblioIntegrator")

# ambiente base com os corpora e o setup
base <- new.env(parent = globalenv())
sys.source("_setup_corpora.R", envir = base)
cat("setup OK\n\n")

arqs <- sort(list.files("_fragmentos", pattern = "\\.qmd$", full.names = TRUE))
resumo <- list()
for (a in arqs) {
  purled <- tryCatch(knitr::purl(a, output = tempfile(fileext = ".R"),
                                 documentation = 0, quiet = TRUE),
                     error = function(e) NULL)
  if (is.null(purled)) { cat(basename(a), ": falha no purl\n"); next }
  cod <- readLines(purled, warn = FALSE)
  exprs <- tryCatch(parse(text = cod), error = function(e) e)
  if (inherits(exprs, "error")) {
    cat(basename(a), ": ERRO DE SINTAXE ->", conditionMessage(exprs), "\n")
    resumo[[basename(a)]] <- "sintaxe"
    next
  }
  e <- new.env(parent = base)
  erro <- NULL
  for (i in seq_along(exprs)) {
    r <- tryCatch({ eval(exprs[[i]], envir = e); NULL },
                  error = function(err) conditionMessage(err))
    if (!is.null(r)) {
      cab <- substr(gsub("\\s+", " ", paste(deparse(exprs[[i]])[1:2], collapse = " ")), 1, 110)
      erro <- sprintf("expr %d: %s\n      >>> %s", i, r, cab)
      break
    }
  }
  if (is.null(erro)) {
    cat(sprintf("%-22s OK (%d expressões)\n", basename(a), length(exprs)))
  } else {
    cat(sprintf("%-22s ERRO\n%s\n", basename(a), erro))
    resumo[[basename(a)]] <- erro
  }
}
cat("\n===== resumo =====\n")
if (length(resumo)) {
  for (n in names(resumo)) cat(n, "->", substr(resumo[[n]], 1, 90), "\n")
} else cat("nenhum erro\n")
