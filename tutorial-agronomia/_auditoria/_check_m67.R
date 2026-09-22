## _auditoria/_check_m67.R - valida os fragmentos 6 e 7 na versao mais recente
ck_dir <- "D:/RLibrary"
if (dir.exists(ck_dir)) .libPaths(c(ck_dir, .libPaths()))
setwd("D:/Walter/R/Pacotes_criados/Tutoriais/biblioIntegrator")
base <- new.env(parent = globalenv())
sys.source("_setup_corpora.R", envir = base)

for (a in c("_fragmentos/m06-corpo.qmd", "_fragmentos/m06-gabaritos.qmd",
            "_fragmentos/m07-corpo.qmd", "_fragmentos/m07-gabaritos.qmd")) {
  purled <- knitr::purl(a, output = tempfile(fileext = ".R"), documentation = 0, quiet = TRUE)
  exprs <- parse(text = readLines(purled, warn = FALSE))
  e <- new.env(parent = base); erro <- NULL
  for (i in seq_along(exprs)) {
    r <- tryCatch({ eval(exprs[[i]], envir = e); NULL }, error = function(err) conditionMessage(err))
    if (!is.null(r)) {
      cab <- substr(gsub("\\s+", " ", paste(deparse(exprs[[i]])[1:2], collapse = " ")), 1, 100)
      erro <- sprintf("expr %d: %s\n   >>> %s", i, r, cab); break
    }
  }
  # inline
  txt <- readLines(a, warn = FALSE, encoding = "UTF-8")
  dentro <- FALSE; cod <- character(); lin <- integer()
  for (i in seq_along(txt)) {
    l <- txt[i]; if (grepl("^```", l)) { dentro <- !dentro; next }; if (dentro) next
    m <- gregexpr("`r ([^`]+)`", l, perl = TRUE)[[1]]; if (m[1] == -1) next
    for (j in seq_along(m)) { s <- m[j]; en <- s + attr(m, "match.length")[j] - 1
      cod <- c(cod, substr(l, s + 3, en - 1)); lin <- c(lin, i) }
  }
  erros_in <- character()
  for (k in seq_along(cod)) {
    r <- tryCatch({ eval(parse(text = cod[k]), envir = e); NULL }, error = function(err) conditionMessage(err))
    if (!is.null(r)) erros_in <- c(erros_in, sprintf("linha %d | %s -> %s", lin[k], substr(cod[k],1,70), r))
  }
  cat(sprintf("%-30s chunks: %s | inline: %d, erros: %d\n", basename(a),
              if (is.null(erro)) "OK" else "ERRO", length(cod), length(erros_in)))
  if (!is.null(erro)) cat("   ", erro, "\n")
  if (length(erros_in)) print(erros_in)
}
