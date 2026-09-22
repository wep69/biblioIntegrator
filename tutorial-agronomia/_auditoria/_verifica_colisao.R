## _auditoria/_verifica_colisao.R - confere o achado de colisao de work_id
ck_dir <- "D:/RLibrary"
if (dir.exists(ck_dir)) .libPaths(c(ck_dir, .libPaths()))
setwd("D:/Walter/R/Pacotes_criados/Tutoriais/biblioIntegrator")
source("_setup_corpora.R")

w <- x_analise$works
cat("obras:", nrow(w), "| work_id distintos:", length(unique(w$work_id)), "\n")
dup_ids <- names(which(table(w$work_id) > 1))
cat("identificadores repetidos:", length(dup_ids), "\n\n")
for (id in dup_ids) {
  sub <- w[w$work_id == id, c("work_id", "title", "year", "doi")]
  cat("--- ", id, " (", nrow(sub), " obras distintas) ---\n", sep = "")
  print(sub, row.names = FALSE)
  cat("\n")
}

# quantos vinculos ficariam ambiguos se a juncao for por work_id
n_aut_real <- nrow(x_analise$authorships)
n_aut_join <- nrow(merge(x_analise$authorships, w[, "work_id", drop = FALSE], by = "work_id"))
cat("vinculos de autoria: reais =", n_aut_real, "| apos merge por work_id =", n_aut_join,
    "| inflacao =", n_aut_join - n_aut_real, "\n")

# a colisao e do hash? testa a funcao interna do pacote
bi_id <- biblioIntegrator:::.bi_id
t1 <- w$title[w$work_id == dup_ids[1]]
y1 <- w$year[w$work_id == dup_ids[1]]
d1 <- w$doi[w$work_id == dup_ids[1]]
cat("\nhash recalculado para o primeiro par:\n")
print(bi_id("W", paste(t1, y1, d1)))
cat("ids armazenados:", w$work_id[w$work_id == dup_ids[1]], "\n")
