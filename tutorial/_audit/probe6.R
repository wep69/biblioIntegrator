## _probe6.R - disruption_index com colunas corretas (3 tentativas)
ck_dir <- "D:/RLibrary"
if (dir.exists(ck_dir)) .libPaths(c(ck_dir, .libPaths()))
suppressPackageStartupMessages(library(biblioIntegrator))

cat("Tentativa 1: colunas corretas, refs do focal citadas por metade dos citantes\n")
edges <- data.frame(citing_id = c("W2","W2","W3","W1","W1"),
                    cited_id  = c("W1","W9","W1","W9","W8"))
refs  <- c("W9","W8")
print(disruption_index("W1", edges, refs))

cat("\nTentativa 2: todos os citantes citam a referencia do focal (N_i=0)\n")
edges2 <- data.frame(citing_id = c("W2","W2","W3","W3","W1","W1"),
                     cited_id  = c("W1","W9","W1","W9","W9","W8"))
print(disruption_index("W1", edges2, refs))

cat("\nTentativa 3: nenhum citante cita referencia do focal (N_j=0)\n")
edges3 <- data.frame(citing_id = c("W2","W3","W1","W1"),
                     cited_id  = c("W1","W1","W9","W8"))
print(disruption_index("W1", edges3, refs))

cat("\nColunas erradas (3 tentativas): sao aceitas silenciosamente?\n")
for (i in 1:3) {
  bad <- data.frame(citing = c("W2","W3"), cited = "W1")
  r <- tryCatch(disruption_index("W1", bad, refs), error = function(e) e,
                warning = function(w) w)
  cat("t", i, ": N_k =", if (inherits(r,"data.frame")) r$N_k[1] else "?",
      "; disruption =", if (inherits(r,"data.frame")) r$disruption else "?",
      "; class =", class(r)[1], "\n")
}
