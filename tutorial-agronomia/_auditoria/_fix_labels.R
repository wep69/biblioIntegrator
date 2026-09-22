## _auditoria/_fix_labels.R - remove labels duplicados (cabecalho + pipe)
setwd("D:/Walter/R/Pacotes_criados/Tutoriais/biblioIntegrator")
arqs <- list.files("_fragmentos", pattern = "\\.qmd$", full.names = TRUE)
total <- 0
for (a in arqs) {
  x <- readLines(a, warn = FALSE, encoding = "UTF-8")
  n <- length(x); remover <- integer()
  for (i in seq_len(n - 1)) {
    m1 <- regmatches(x[i], regexec("^```\\{r ([A-Za-z0-9_.:-]+)\\}$", x[i]))[[1]]
    if (length(m1) == 2) {
      lab <- m1[2]
      m2 <- regmatches(x[i + 1], regexec("^#\\| label: (.+)$", x[i + 1]))[[1]]
      if (length(m2) == 2 && trimws(m2[2]) == lab) remover <- c(remover, i + 1)
    }
  }
  if (length(remover)) {
    writeLines(x[-remover], a, useBytes = TRUE)
    cat(basename(a), ": removidos", length(remover), "labels duplicados\n")
    total <- total + length(remover)
  }
}
cat("total removido:", total, "\n")
# confere duplicatas de label entre todos os fragmentos
labs <- unlist(lapply(arqs, function(a) {
  x <- readLines(a, warn = FALSE, encoding = "UTF-8")
  c(regmatches(x, regexec("^```\\{r ([A-Za-z0-9_.:-]+)\\}$", x)) |> (\(z) vapply(z, function(v) if (length(v) == 2) v[2] else NA_character_, character(1)))()
  )
}))
labs <- labs[!is.na(labs)]
cat("labels de chunk no total:", length(labs), "| repetidos:", sum(duplicated(labs)), "\n")
if (any(duplicated(labs))) print(sort(labs[duplicated(labs)]))
