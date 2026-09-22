## _auditoria/_verifica_native_edges.R - confere o defeito de arestas duplicadas no motor nativo
ck_dir <- "D:/RLibrary"
if (dir.exists(ck_dir)) .libPaths(c(ck_dir, .libPaths()))
setwd("D:/Walter/R/Pacotes_criados/Tutoriais/biblioIntegrator")
source("_setup_corpora.R")

g_nat <- bibliographic_network(x_analise, "coauthor", engine = "native")
g_bib <- bibliographic_network(x_analise, "coauthor", engine = "biblionetwork")
n <- igraph::vcount(g_nat)
cat("vertices:", n, "| maximo teorico de pares:", n * (n - 1) / 2, "\n")
cat("arestas nativo:", igraph::ecount(g_nat), "| arestas biblionetwork:", igraph::ecount(g_bib), "\n")

el <- igraph::as_edgelist(g_nat)
par <- apply(el, 1, function(z) paste(sort(z), collapse = "|"))
cat("pares distintos:", length(unique(par)), "| pares repetidos (nos dois sentidos):",
    sum(duplicated(par)), "\n")

d_nat <- igraph::degree(g_nat); d_bib <- igraph::degree(g_bib)
cat("\ngrau maximo nativo:", max(d_nat), "(impossivel com", n, "vertices: maximo real", n - 1, ")\n")
cat("grau medio nativo:", round(mean(d_nat), 4), "| biblionetwork:", round(mean(d_bib), 4), "\n")
cat("densidade nativo:", round(igraph::edge_density(g_nat), 4),
    "| biblionetwork:", round(igraph::edge_density(g_bib), 4), "\n")

cn <- network_centrality(g_nat); cb <- network_centrality(g_bib)
m <- merge(cn, cb, by = "node", suffixes = c("_nat", "_bib"))
cat("\nforca identica entre motores?", isTRUE(all.equal(m$strength_nat, m$strength_bib)), "\n")
cat("pagerank identico?", isTRUE(all.equal(m$pagerank_nat, m$pagerank_bib)), "\n")
cat("intermediacao identica?", isTRUE(all.equal(m$betweenness_nat, m$betweenness_bib)), "\n")

# network_stability usa o motor nativo internamente?
cat("\n--- corpus de referencias ---\n")
cat("linhas em references:", nrow(x_analise$references), "\n")
r <- tryCatch(bibliographic_network(x_analise, "citation"),
              error = function(e) conditionMessage(e))
cat("rede de citacao:", if (is.character(r)) paste("ERRO:", r) else "OK", "\n")

# compare_groups com um unico grupo
x1 <- as_biblio_project(example_biblio())
g1 <- form_groups(x1, rep("a", nrow(x1$works)))
c1 <- tryCatch(compare_groups(x1, g1, permutations = 99, seed = 1),
               error = function(e) conditionMessage(e))
if (inherits(c1, "biblio_group_comparison"))
  cat("compare_groups com 1 grupo: chi =", c1$chi_square, "| V =", c1$cramers_v, "| p =", c1$p_value, "\n") else cat(c1, "\n")
