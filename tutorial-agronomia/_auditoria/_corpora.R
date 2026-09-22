## _corpora.R - corpora compartilhados do tutorial (teste isolado, v2)
ck_dir <- "D:/RLibrary"
if (dir.exists(ck_dir)) .libPaths(c(ck_dir, .libPaths()))
suppressPackageStartupMessages(library(biblioIntegrator))
SEED <- 2026L

# =====================================================================
# CORPUS B: "Agricultura tropical" simulado (2010-2025), com verdade plantada
#  V1 tres temas latentes: silicio/estresse 45%, carbono do solo 35%,
#     sensoriamento remoto/UAV 20%
#  V2 duas fontes com bonus de +12 citacoes por obra
#  V3 metade das obras com coautoria internacional
#  V4 termos de IA/UAV entram a partir de 2020 (concentracao no periodo recente)
#  V5 autor central "Silva AP" em 40 obras (hub da rede)
#  V6 tres duplicatas plantadas + defeitos de metadados
# =====================================================================
set.seed(SEED)
nB <- 280L
temas <- list(
  silicio = list(tit = "Silício e tolerância a estresse abiótico",
                 kw = c("silicon","salinity","drought stress","rice","sorghum",
                        "nutrient uptake","abiotic stress","silicon fertilization")),
  carbono = list(tit = "Carbono do solo e plantas de cobertura",
                 kw = c("soil carbon","cover crops","no-till","soil organic matter",
                        "carbon sequestration","soil aggregation","crop rotation",
                        "green manure")),
  remoto  = list(tit = "Sensoriamento remoto e fenotipagem de culturas",
                 kw = c("remote sensing","UAV","machine learning","hyperspectral",
                        "yield prediction","vegetation index","phenotyping",
                        "deep learning")))
tema_lat <- sample(c("silicio","carbono","remoto"), nB, replace = TRUE,
                   prob = c(.45, .35, .20))
fontes_bonus <- c("Field Crops Research", "Soil Biology & Biochemistry")
fontes <- c(fontes_bonus, "Agronomy Journal", "Plant and Soil",
            "Precision Agriculture", "Pesquisa Agropecuária Brasileira",
            "Revista Brasileira de Ciência do Solo", "Scientia Agricola",
            "Soil & Tillage Research", "Remote Sensing")
paises_int  <- c("Smith J","Chen L","Müller H","Rossi G")
# V7: tres laboratorios plantados (estrutura de comunidades da rede)
lab_S <- c("Silva AP","Costa JR","Pereira WE","Martins LC")
lab_C <- c("Souza RM","Oliveira TN","Almeida FB")
lab_R <- c("Rocha MV","Lima DH","Barbosa KS","Nunes PR","Castro ES")
lab_de <- list(silicio = lab_S, carbono = lab_C, remoto = lab_R)
cultura     <- c("arroz","milho","soja","sorgo","feijão","trigo","pastagem")
termos_ia   <- c("machine learning","deep learning","UAV","hyperspectral")

ano     <- sample(2010:2025, nB, replace = TRUE,
                  prob = c(2,2,3,3,4,4,5,5,6,7,8,9,10,11,12,9))
# V2: fonte sorteada UMA vez e reutilizada na coluna e no bonus de citacao
fonte_i <- sample(fontes, nB, replace = TRUE,
                  prob = c(12,11,10,10,9,9,10,10,9,10)/100)
# V4: termos de IA/UAV a partir de 2020
kw_list <- lapply(seq_len(nB), function(i) {
  base <- sample(temas[[tema_lat[i]]]$kw, 4L)
  if (ano[i] >= 2020 && runif(1) < .78) base <- c(base, sample(termos_ia, 1L))
  paste(unique(base), collapse = "; ")
})
# V5 (hub) e V3 (coautoria internacional) e V7 (laboratorios)
authors_list <- lapply(seq_len(nB), function(i) {
  meu_lab <- lab_de[[tema_lat[i]]]
  outros  <- unlist(lab_de[setdiff(names(lab_de), tema_lat[i])])
  # 88% dentro do proprio laboratorio, 12% colaboracao cruzada
  pool <- if (runif(1) < .88) meu_lab else outros
  br <- sample(pool, min(length(pool), sample(1:3, 1)))
  if (i <= 40L || (tema_lat[i] == "silicio" && runif(1) < .60))
    br <- unique(c("Silva AP", br))
  if (runif(1) < .50) br <- c(br, sample(paises_int, sample(1:2, 1)))
  paste(br, collapse = "; ")
})
# citacoes: base + bonus da fonte V2
cit <- pmax(0L, round(exp(rnorm(nB, 1.9, .9)) - 1)) +
  ifelse(fonte_i %in% fontes_bonus, 12L, 0L)

dB <- data.frame(
  title = sprintf("%s em %s (estudo %03d)",
                  vapply(tema_lat, function(t) temas[[t]]$tit, character(1)),
                  sample(cultura, nB, replace = TRUE), seq_len(nB)),
  year = ano, doi = paste0("10.1016/j.agri.2024.", sprintf("%05d", seq_len(nB))),
  authors = unlist(authors_list), keywords = unlist(kw_list),
  citations = cit, source = fonte_i, stringsAsFactors = FALSE)

# V6: defeitos de metadados plantados
dB$doi[5]        <- "  HTTPS://DOI.ORG/10.1016/j.agri.2024.00005  "
dB$doi[9]        <- "doi:10.1016/j.agri.2024.00009"
dB$year[14]      <- NA_integer_
dB$citations[21] <- -3L
dB$title[33]     <- "   "
dB$doi[47]       <- NA_character_

# V6: tres duplicatas plantadas, cada uma testando um estagio da deduplicacao
dB <- rbind(dB, dB[1, ])                                  # (a) copia exata (DOI igual)
dB <- rbind(dB, transform(dB[2, ], doi = NA_character_))  # (b) sem DOI (titulo+ano)
dB <- rbind(dB, transform(dB[3, ],
        doi = "https://doi.org/10.1016/j.agri.2024.00003")) # (c) DOI em URL

x_bruto <- as_biblio_project(dB, source = "corpus B bruto")
x_limpo <- deduplicate_biblio(x_bruto, method = "doi_title_year")
# recorte analitico: obra sem ano nao pode entrar em agrupamento por periodo
ids_ok <- x_limpo$works$work_id[!is.na(x_limpo$works$year)]
d_ok   <- dB[!is.na(dB$year), ]
x_analise <- as_biblio_project(d_ok, source = "corpus B analitico (sem ano ausente)")

cat("=== CORPUS B ===\n")
cat("bruto:", nrow(x_bruto$works), "| limpo:", nrow(x_limpo$works),
    "| analitico:", nrow(x_analise$works), "\n")
cat("\n--- V6: diagnostico do bruto ---\n"); print(biblio_health(x_bruto))
cat("duplicatas removidas:", nrow(x_bruto$works) - nrow(x_limpo$works), "\n")

cat("\n--- V2: impacto medio por fonte (analitico) ---\n")
ag <- aggregate(cited_by_count ~ source, x_analise$works,
                FUN = function(z) c(n = length(z), m = mean(z)))
s2 <- data.frame(source = ag$source, n = ag$cited_by_count[, 1],
                 cit_media = round(ag$cited_by_count[, 2], 1))
print(head(s2[order(-s2$cit_media), ], 5), row.names = FALSE)

cat("\n--- V4: termos de IA/UAV por periodo ---\n")
k <- merge(x_analise$keywords, x_analise$works[, c("work_id", "year")], by = "work_id")
k$periodo <- ifelse(k$year >= 2020, "2020-2025", "2010-2019")
k$ia <- k$keyword %in% termos_ia
print(round(prop.table(table(k$periodo, k$ia), 1), 3))

cat("\n--- V1: temas latentes (keywords dominantes por tema) ---\n")
print(head(sort(table(x_analise$keywords$keyword), decreasing = TRUE), 12))

cat("\n--- V5: hub da rede de coautoria (com nomes) ---\n")
gco <- bibliographic_network(x_analise, "coauthor")
cat("vertices:", igraph::vcount(gco), "| arestas:", igraph::ecount(gco), "\n")
cent <- network_centrality(gco)
nom <- x_analise$authors
cent$nome <- nom$display_name[match(cent$node, nom$author_id)]
print(head(cent[order(-cent$degree), c("nome","degree","strength","betweenness")], 3), row.names = FALSE)

cat("\n--- V7: comunidades plantadas (laboratorios) ---\n")
com <- network_communities(gco, method = "louvain")
com$nome <- nom$display_name[match(com$node, nom$author_id)]
print(sort(table(com$community), decreasing = TRUE))
cat("modularidade:", round(igraph::modularity(igraph::cluster_louvain(
  igraph::as_undirected(gco, mode = "collapse"))), 3), "\n")

cat("\n--- V6: duplicata sobrevivente (verificacao da causa) ---\n")
tt <- table(tolower(trimws(x_limpo$works$title)))
cat("titulos repetidos apos deduplicacao:", sum(tt > 1), "\n")
if (any(tt > 1)) {
  rep_t <- names(tt)[tt > 1]
  sub <- x_limpo$works[tolower(trimws(x_limpo$works$title)) %in% rep_t,
                       c("work_id","title","year","doi")]
  print(sub, row.names = FALSE)
  cat("explicacao: chave = DOI quando existe; titulo+ano apenas quando o DOI falta\n")
  cat("=> o registro SEM doi nao casa com o gemeo que TEM doi\n")
  cat("registros removidos no log:\n")
  print(attr(x_limpo, "dedup_log")[, c("title","doi")], row.names = FALSE)
}

cat("\n--- comparacao por periodo (analitico) ---\n")
per <- ifelse(x_analise$works$year >= 2020, "2020-2025", "2010-2019")
gB  <- form_groups(x_analise, per)
cmp <- compare_groups(x_analise, gB, entity = "keyword", permutations = 499, seed = SEED)
cat("chi:", round(cmp$chi_square, 2), " p:", cmp$p_value, " V:", round(cmp$cramers_v, 3), "\n")
res <- association_residuals(cmp)
print(head(res[order(-abs(res$residual)), ], 5), row.names = FALSE)

