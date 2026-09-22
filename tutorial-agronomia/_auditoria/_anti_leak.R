## _auditoria/_anti_leak.R - procura números de resultado digitados na prosa
setwd("D:/Walter/R/Pacotes_criados/Tutoriais/biblioIntegrator")
arq <- "biblioIntegrator-agronomia.qmd"
txt <- readLines(arq, warn = FALSE, encoding = "UTF-8")
dentro <- FALSE
sus <- list()
for (i in seq_along(txt)) {
  l <- txt[i]
  if (grepl("^```", l)) { dentro <- !dentro; next }
  if (dentro) next
  limpo <- gsub("`r [^`]*`", "«r»", l)          # remove inline r
  limpo <- gsub("\\[[^]]*\\]\\([^)]*\\)", "", limpo)  # remove links
  limpo <- gsub("https?://\\S+", "", limpo)
  limpo <- gsub("10\\.[0-9]{4,}/\\S+", "", limpo)     # remove DOIs
  limpo <- gsub("[0-9]{4}(-[0-9]{4})?", "", limpo)    # remove anos
  limpo <- gsub("arXiv:[0-9.]+", "", limpo)
  # decimais com vírgula ou ponto, 1-4 casas, tipicos de resultado
  m <- gregexpr("[0-9]+[,.][0-9]{1,4}", limpo)[[1]]
  if (m[1] != -1) {
    vals <- regmatches(limpo, gregexpr("[0-9]+[,.][0-9]{1,4}", limpo))[[1]]
    sus[[length(sus) + 1L]] <- data.frame(linha = i, valores = paste(vals, collapse = " | "),
                                          texto = substr(trimws(l), 1, 150),
                                          stringsAsFactors = FALSE)
  }
}
if (length(sus)) {
  d <- do.call(rbind, sus)
  cat("linhas de prosa com decimais:", nrow(d), "\n\n")
  print(d, right = FALSE, row.names = FALSE)
} else cat("nenhum decimal suspeito na prosa\n")
cat("\n--- marcadores nao resolvidos ---\n")
mrk <- grep("%s|%d|\\{\\{|`r [^`]*$", txt, value = TRUE)
cat(length(mrk), "linhas\n"); if (length(mrk)) print(substr(mrk, 1, 120))
cat("\n--- NA/NaN/NULL visiveis na prosa ---\n")
na <- grep("\\bNA\\b|\\bNaN\\b|\\bNULL\\b|\\bInf\\b", txt, value = TRUE)
cat(length(na), "linhas\n")
if (length(na)) print(substr(na, 1, 130))
