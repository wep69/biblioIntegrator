## _probe5.R - Refutacao de achados (regra das tres tentativas)
ck_dir <- "D:/RLibrary"
if (dir.exists(ck_dir)) .libPaths(c(ck_dir, .libPaths()))
suppressPackageStartupMessages(library(biblioIntegrator))
ck <- function(rotulo, expr) {
  cat("\n##### ", rotulo, "\n", sep = "")
  r <- tryCatch(expr, error = function(e) paste("ERRO:", conditionMessage(e)))
  print(r); invisible(r)
}
x <- as_biblio_project(example_biblio())
g <- form_groups(x, ifelse(x$works$year < 2022, "early", "late"))

cat("===== A1: validate_plan aceita modulo invalido? (3 tentativas) =====\n")
for (i in 1:3) {
  r <- tryCatch(validate_plan(form_plan(analyses = c("inexistente_A", "inexistente_B")[i] )), error = function(e) e)
  cat("t", i, ": class =", class(r)[1], "; error msg =",
      if (inherits(r, "error")) conditionMessage(r) else "<sem erro>\n", "\n")
}
cat("O que form_plan produz?\n"); str(form_plan(analyses = c("inexistente")))

cat("\n===== A2: compare_groups engine=biblium sem python (3 tentativas) =====\n")
for (i in 1:3) {
  r <- tryCatch(compare_groups(x, g, engine = "biblium", permutations = 9, seed = 1),
                error = function(e) e, warning = function(w) w)
  cat("t", i, ": class =", class(r)[1], ";",
      if (inherits(r, "error")) conditionMessage(r) else if (inherits(r, "warning")) conditionMessage(r) else "OK\n", "\n")
}

cat("\n===== A3: biblio_store overwrite=FALSE recusa? (3 tentativas) =====\n")
for (i in 1:3) {
  t <- tempfile()
  biblio_store(x, t, engine = "arrow")
  r <- tryCatch(biblio_store(x, t, engine = "arrow", overwrite = FALSE), error = function(e) e)
  cat("t", i, ":",
      if (inherits(r, "error")) paste("ERRO:", conditionMessage(r)) else paste("sem erro, retornou:", r), "\n")
}

cat("\n===== A4: rpys com argumento nomeado errado =====\n")
rp <- c(2005, 2010, 2012)
r <- tryCatch(rpys(rpys = rp), error = function(e) e)
cat("class:", class(r)[1], if (inherits(r, "error")) paste("ERRO:", conditionMessage(r)) else "", "\n")

cat("\n===== A5: disruption_index semantica correta =====\n")
# focal W1 citado por W2 e W3; W2 e W3 tambem citam W0 (referencia do focal? nao)
# Convencao provavel: citation_edges = todas arestas citante->citado;
# focal_references = referencias DO FOCAL (citadas pelo focal)
edges <- data.frame(citing = c("W2","W2","W3","W3","W1","W1"),
                    cited  = c("W1","W0","W1","W0","W9","W8"))
refs  <- data.frame(citing = "W1", cited = c("W9","W8"))
r <- disruption_index("W1", edges, refs)
print(r)
# variacao: citante W2 cita W9 (referencia do focal), W3 nao cita
edges2 <- data.frame(citing = c("W2","W2","W3","W1","W1"),
                     cited  = c("W1","W9","W1","W9","W8"))
r2 <- disruption_index("W1", edges2, refs)
print(r2)

cat("\n===== A6: fetch_openalex de novo (rede) =====\n")
r <- tryCatch(fetch_openalex("soil fertility", n = 3), error = function(e) e)
cat("class:", class(r)[1], ";\n")
if (!inherits(r, "error")) print(head(r, 2))
