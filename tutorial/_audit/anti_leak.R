## _anti_leak.R - verificação de números chumbados na prosa (fora de fences e r-chunks)
qmd <- "D:/Walter/R/Pacotes_criados/biblioIntegrator/tutorial/tutorial-completo.qmd"
txt <- readLines(qmd, warn = FALSE)
in_fence <- FALSE
suspeitos <- data.frame()
for (i in seq_len(length(txt))) {
  l <- txt[i]
  if (grepl("^```", l)) { in_fence <- !in_fence; next }
  if (in_fence || grepl("^-\\s|^\\|", l)) next
  # remover chunks inline para não acusar código interpolado
  clean <- gsub("`r [^`]+`", "«r»", l)
  # não acusar: referências DOI, anos 19xx/20xx, seeds e design (palavras-chave de design)
  if (grepl("\\b0\\.[0-9]{2,}\\b", clean) ||
      grepl("«r»", clean) == FALSE && grepl("\\b\\d+\\.(\\d+)%", clean)) {
    if (grepl("\\b0\\.[0-9]{2,}\\b", clean)) {
      suspeitos <- rbind(suspeitos, data.frame(linha = i, texto = substr(clean, 1, 110),
                                               stringsAsFactors = FALSE))
    }
  }
}
cat("linhas suspeitas de número de resultado chumbado:", nrow(suspeitos), "\n")
if (nrow(suspeitos)) print(suspeitos, right = FALSE)
cat("\n--- marcadores não resolvidos ---\n")
mrk <- txt[grepl("%s|\\[\\[|%s", txt)]
cat(length(mrk), "linhas com marcadores\n")
cat("\n--- 'NA' visível na prosa ---\n")
na_linhas <- txt[!grepl("^```", txt) & grepl("\\bNA\\b", txt)]
cat(length(na_linhas), "linhas com NA na prosa\n")
print(substr(na_linhas, 1, 80))
