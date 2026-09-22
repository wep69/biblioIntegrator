## _auditoria/_check_inline.R - avalia os chunks inline (prosa) de cada fragmento
ck_dir <- "D:/RLibrary"
if (dir.exists(ck_dir)) .libPaths(c(ck_dir, .libPaths()))
setwd("D:/Walter/R/Pacotes_criados/Tutoriais/biblioIntegrator")
base <- new.env(parent = globalenv())
sys.source("_setup_corpora.R", envir = base)

extrai_inline <- function(arq) {
  txt <- readLines(arq, warn = FALSE, encoding = "UTF-8")
  dentro <- FALSE; cod <- character(); lin <- integer()
  for (i in seq_along(txt)) {
    l <- txt[i]
    if (grepl("^```", l)) { dentro <- !dentro; next }
    if (dentro) next
    m <- gregexpr("`r ([^`]+)`", l, perl = TRUE)[[1]]
    if (m[1] == -1) next
    for (j in seq_along(m)) {
      s <- m[j]; e <- s + attr(m, "match.length")[j] - 1
      cod <- c(cod, substr(l, s + 3, e - 1)); lin <- c(lin, i)
    }
  }
  list(cod = cod, lin = lin)
}

arqs <- sort(list.files("_fragmentos", pattern = "\\.qmd$", full.names = TRUE))
total_erros <- 0
for (a in arqs) {
  purled <- knitr::purl(a, output = tempfile(fileext = ".R"), documentation = 0, quiet = TRUE)
  e <- new.env(parent = base)
  exprs <- parse(text = readLines(purled, warn = FALSE))
  ok_chunks <- TRUE
  for (i in seq_along(exprs)) {
    r <- tryCatch({ eval(exprs[[i]], envir = e); NULL }, error = function(err) conditionMessage(err))
    if (!is.null(r)) { cat(basename(a), ": chunk", i, "falhou:", r, "\n"); ok_chunks <- FALSE; break }
  }
  if (!ok_chunks) next
  il <- extrai_inline(a)
  erros <- character()
  for (k in seq_along(il$cod)) {
    r <- tryCatch({ eval(parse(text = il$cod[k]), envir = e); NULL },
                  error = function(err) conditionMessage(err))
    if (!is.null(r))
      erros <- c(erros, sprintf("linha %d | %s\n         %s",
                                il$lin[k], substr(il$cod[k], 1, 120), substr(r, 1, 150)))
  }
  if (length(erros)) {
    total_erros <- total_erros + length(erros)
    cat(sprintf("\n### %s: %d inline com erro\n%s\n", basename(a), length(erros),
                paste(erros, collapse = "\n")))
  } else {
    cat(sprintf("%-22s inline OK (%d)\n", basename(a), length(il$cod)))
  }
}
cat("\nTOTAL de erros inline:", total_erros, "\n")
