## _m67_render/verif.R - conferencia final dos fragmentos 6 e 7 contra o HTML
h <- readLines("teste.html", warn = FALSE, encoding = "UTF-8")
t <- paste(h, collapse = "\n")
t <- gsub("(?s)<div class=\"sourceCode.*?</div>", "", t, perl = TRUE)
t <- gsub("(?s)<pre.*?</pre>", "", t, perl = TRUE)
texto <- gsub("<[^>]+>", " ", t)
texto <- gsub("&nbsp;", " ", texto, fixed = TRUE)
texto <- gsub("&amp;", "&", texto, fixed = TRUE)
texto <- gsub("\\s+", " ", texto)

falhas <- character(0)
registrar <- function(cond, msg) if (!isTRUE(cond)) falhas <<- c(falhas, msg)

# 1. codigo R em linha que nao foi avaliado
sobras <- regmatches(texto, gregexpr("r [a-z_]+\\$[a-zA-Z_]+", texto))[[1]]
registrar(length(sobras) == 0,
          paste("codigo em linha nao avaliado:", paste(utils::head(sobras, 3), collapse = " | ")))

# 2. valores ausentes ou degenerados na prosa
for (marca in c("\n NA \n", "NaN", "\n NULL \n")) {
  registrar(!grepl(marca, texto, fixed = TRUE), paste("marcador na prosa:", marca))
}

# 3. numero faltando antes de unidade, sinal de campo vazio que passou em silencio
unidades <- c("permutações", "termos", "obras", "autores", "trabalhos", "posições",
              "vértices", "arestas", "comunidades")
for (u in unidades) {
  registrar(!grepl(paste0("  ", u), texto, fixed = TRUE), paste("numero faltando antes de:", u))
}

# 4. numeros-chave do modulo 6
for (e in c("0.21", "0.892", "54.2", "1952.3", "43.3", "25.2", "0.002", "1.07")) {
  registrar(grepl(e, texto, fixed = TRUE), paste("numero ausente no modulo 6:", e))
}
# 5. numeros-chave do modulo 7
for (e in c("91", "120", "0.41", "0.2262", "0.4486", "0,49", "54", "37")) {
  registrar(grepl(e, texto, fixed = TRUE), paste("numero ausente no modulo 7:", e))
}

# 6. rotulos de bloco duplicados
rotulos <- regmatches(t, gregexpr("#\\| label: [a-zA-Z0-9-]+", t))[[1]]
rotulos <- sub("#\\| label: ", "", rotulos)
if (length(rotulos)) {
  registrar(!any(duplicated(rotulos)),
            paste("rotulos duplicados:", paste(unique(rotulos[duplicated(rotulos)]), collapse = ", ")))
}

# 7. figuras e tabelas
n_tab <- length(regmatches(t, gregexpr("<caption>", t, fixed = TRUE))[[1]])
n_fig <- length(regmatches(t, gregexpr("<img", t, fixed = TRUE))[[1]])
cat("tabelas com legenda:", n_tab, "| figuras:", n_fig, "\n")
registrar(n_fig >= 6, paste("figuras insuficientes:", n_fig))
registrar(n_tab >= 4, paste("tabelas insuficientes:", n_tab))

# 8. secoes obrigatorias
for (s in c("O problema agronômico", "Tarefas do Módulo 6", "Tarefas do Módulo 7",
            "Gabarito do Exercício 6.1", "Gabarito do Exercício 6.2",
            "Gabarito do Exercício 7.1", "Gabarito do Exercício 7.2",
            "Código completo e executável", "Leitura da saída",
            "Redação sugerida para o artigo", "Erros comuns a evitar")) {
  registrar(grepl(s, texto, fixed = TRUE), paste("secao ausente:", s))
}

# 9. referencias cruzadas resolvidas
registrar(!grepl("@fig-", texto, fixed = TRUE), "referencia cruzada nao resolvida na prosa")
registrar(!grepl("[?]", texto, fixed = TRUE), "caractere de interrogacao na prosa")

cat("\n--- resultado ---\n")
if (length(falhas)) {
  cat("FALHAS:\n"); cat(paste0("  - ", falhas, collapse = "\n"), "\n")
} else {
  cat("todas as conferencias passaram\n")
}
