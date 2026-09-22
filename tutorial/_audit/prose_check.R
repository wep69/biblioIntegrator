## _prose_check.R - Fase 9: verificar todos os chunks inline da prosa
ck_dir <- "D:/RLibrary"
if (dir.exists(ck_dir)) .libPaths(c(ck_dir, .libPaths()))
suppressPackageStartupMessages(library(biblioIntegrator))

qmd <- "D:/Walter/R/Pacotes_criados/biblioIntegrator/tutorial/tutorial-completo.qmd"
txt <- readLines(qmd, warn = FALSE)
nlinhas <- length(txt)

# 1) purl e EXECUTAR mantendo o ambiente
script <- knitr::purl(qmd, output = tempfile(fileext = ".R"), documentation = 0)
env <- new.env(parent = globalenv())
source(script, local = env, echo = FALSE)

# 2) extrair inline chunks: `r ...` (fora de blocos de código fenced)
in_fence <- FALSE; fnc <- character(); alvo <- integer()
for (i in seq_len(nlinhas)) {
  l <- txt[i]
  if (grepl("^```", l)) { in_fence <- !in_fence; next }
  if (in_fence) next
  m <- gregexpr("`r ([^`]+)`", l, perl = TRUE)[[1]]
  if (m[1] != -1) {
    for (j in seq_along(m)) {
      s <- m[j]; e <- s + attr(m, "match.length")[j] - 1
      code <- substr(l, s + 3, e - 1)
      fnc <- c(fnc, code); alvo <- c(alvo, i)
    }
  }
}
cat("chunks inline encontrados:", length(fnc), "\n")

# 3) avaliar cada um no ambiente de execução
erros <- list(); n_ok <- 0
for (k in seq_along(fnc)) {
  res <- tryCatch(withCallingHandlers(
    eval(parse(text = fnc[k]), envir = env),
    warning = function(w) invokeRestart("muffleWarning")),
    error = function(e) paste("ERRO:", conditionMessage(e)))
  if (length(res) == 1L && is.character(res) && grepl("^ERRO", res)) {
    erros[[length(erros) + 1L]] <- data.frame(
      linha = alvo[k], codigo = substr(fnc[k], 1, 90),
      erro = substr(res, 1, 160), stringsAsFactors = FALSE)
  } else n_ok <- n_ok + 1
}
cat("avaliados ok:", n_ok, "; com erro:", length(erros), "\n")
if (length(erros)) {
  out <- do.call(rbind, erros)
  print(out, right = FALSE)
  write.csv(out, "D:/Walter/R/Pacotes_criados/biblioIntegrator/tutorial/erros-prosa.csv", row.names = FALSE)
  quit(status = 1)
}
cat("prosa íntegra: todos os chunks inline avaliam sem erro.\n")
