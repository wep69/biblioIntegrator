# ============================================================================
# _setup_corpora.R - fundação compartilhada do tutorial de biblioIntegrator
# Uso: source("_setup_corpora.R")  -> cria todos os objetos usados nos módulos
# ============================================================================
ck_dir <- "D:/RLibrary"
if (dir.exists(ck_dir)) .libPaths(c(ck_dir, .libPaths()))
Sys.setenv(BIBLIOINTEGRATOR_PYTHON =
  "H:/uv/AppDataLocalUv/cache/archive-v0/MfuOKTFtveE-Nd3l_RFiM/Scripts/python.exe")
suppressPackageStartupMessages({
  library(biblioIntegrator); library(ggplot2); library(igraph)
})
tema_agri <- theme_bw(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        legend.position = "bottom",
        strip.background = element_rect(fill = "grey92", colour = NA),
        plot.title = element_text(face = "bold", size = 11),
        plot.subtitle = element_text(colour = "grey35", size = 9.5))
theme_set(tema_agri)
pal_agri <- c("#2E5E4E", "#C97B3C", "#4A6FA5", "#8E6C88", "#7A9E7E", "#B5651D")
SEED <- 2026L
py_env <- Sys.getenv("BIBLIOINTEGRATOR_PYTHON", "")
if (nzchar(py_env) && file.exists(py_env)) options(biblioIntegrator.python = py_env)
cache_rds <- function(nome, expr) {
  f <- file.path("_cache", paste0(nome, ".rds"))
  if (file.exists(f)) return(readRDS(f))
  dir.create("_cache", showWarnings = FALSE)
  v <- tryCatch(expr, error = function(e) structure(conditionMessage(e), class = "erro_rede"))
  if (!inherits(v, "erro_rede")) saveRDS(v, f)
  v
}

# ---- Corpus A: didático -----------------------------------------------------
x_did <- as_biblio_project(example_biblio(), source = "acervo didático")

# ---- Corpus B: simulado com verdades plantadas ------------------------------
set.seed(SEED)
nB <- 280L
temas <- list(
  silicio = list(tit = "Silício e tolerância a estresse abiótico",
                 kw = c("silicon","salinity","drought stress","rice","sorghum",
                        "nutrient uptake","abiotic stress","silicon fertilization")),
  carbono = list(tit = "Carbono do solo e plantas de cobertura",
                 kw = c("soil carbon","cover crops","no-till","soil organic matter",
                        "carbon sequestration","soil aggregation","crop rotation","green manure")),
  remoto  = list(tit = "Sensoriamento remoto e fenotipagem de culturas",
                 kw = c("remote sensing","UAV","machine learning","hyperspectral",
                        "yield prediction","vegetation index","phenotyping","deep learning")))
tema_lat <- sample(c("silicio","carbono","remoto"), nB, replace = TRUE, prob = c(.45,.35,.20))
fontes_bonus <- c("Field Crops Research", "Soil Biology & Biochemistry")
fontes <- c(fontes_bonus, "Agronomy Journal", "Plant and Soil", "Precision Agriculture",
            "Pesquisa Agropecuária Brasileira", "Revista Brasileira de Ciência do Solo",
            "Scientia Agricola", "Soil & Tillage Research", "Remote Sensing")
int_lab <- c("Smith J","Chen L","Müller H","Rossi G")
lab_S <- c("Silva AP","Costa JR","Pereira WE","Martins LC")
lab_C <- c("Souza RM","Oliveira TN","Almeida FB")
lab_R <- c("Rocha MV","Lima DH","Barbosa KS","Nunes PR","Castro ES")
lab_de <- list(silicio = lab_S, carbono = lab_C, remoto = lab_R)
cultura <- c("arroz","milho","soja","sorgo","feijão","trigo","pastagem")
termos_ia <- c("machine learning","deep learning","UAV","hyperspectral")
ano <- sample(2010:2025, nB, replace = TRUE,
              prob = c(2,2,3,3,4,4,5,5,6,7,8,9,10,11,12,9))
fonte_i <- sample(fontes, nB, replace = TRUE, prob = c(12,11,10,10,9,9,10,10,9,10)/100)
kw_list <- lapply(seq_len(nB), function(i) {
  base <- sample(temas[[tema_lat[i]]]$kw, 4L)
  if (ano[i] >= 2020 && runif(1) < .78) base <- c(base, sample(termos_ia, 1L))
  paste(unique(base), collapse = "; ")
})
authors_list <- lapply(seq_len(nB), function(i) {
  meu <- lab_de[[tema_lat[i]]]
  outros <- unlist(lab_de[setdiff(names(lab_de), tema_lat[i])])
  pool <- if (runif(1) < .88) meu else outros
  br <- sample(pool, min(length(pool), sample(1:3, 1)))
  if (i <= 40L || (tema_lat[i] == "silicio" && runif(1) < .60))
    br <- unique(c("Silva AP", br))
  if (runif(1) < .50) br <- c(br, sample(int_lab, sample(1:2, 1)))
  paste(br, collapse = "; ")
})
cit <- pmax(0L, round(exp(rnorm(nB, 1.9, .9)) - 1)) +
  ifelse(fonte_i %in% fontes_bonus, 12L, 0L)
dB <- data.frame(
  title = sprintf("%s em %s (estudo %03d)",
                  vapply(tema_lat, function(t) temas[[t]]$tit, character(1)),
                  sample(cultura, nB, replace = TRUE), seq_len(nB)),
  year = ano, doi = paste0("10.1016/j.agri.2024.", sprintf("%05d", seq_len(nB))),
  authors = unlist(authors_list), keywords = unlist(kw_list),
  citations = cit, source = fonte_i, stringsAsFactors = FALSE)
dB$doi[5] <- "  HTTPS://DOI.ORG/10.1016/j.agri.2024.00005  "
dB$doi[9] <- "doi:10.1016/j.agri.2024.00009"
dB$year[14] <- NA_integer_
dB$citations[21] <- -3L
dB$title[33] <- "   "
dB$doi[47] <- NA_character_
dB$tema <- tema_lat
dB <- rbind(dB, dB[1, ])
dB <- rbind(dB, transform(dB[2, ], doi = NA_character_))
dB <- rbind(dB, transform(dB[3, ], doi = "https://doi.org/10.1016/j.agri.2024.00003"))
x_bruto <- as_biblio_project(dB, source = "corpus B bruto")
x_limpo <- deduplicate_biblio(x_bruto, method = "doi_title_year")
ids_ok <- x_limpo$works$work_id[!is.na(x_limpo$works$year)]
x_analise <- x_limpo
x_analise$works <- x_limpo$works[x_limpo$works$work_id %in% ids_ok, , drop = FALSE]
x_analise$authorships <- x_limpo$authorships[x_limpo$authorships$work_id %in% ids_ok, , drop = FALSE]
x_analise$keywords <- x_limpo$keywords[x_limpo$keywords$work_id %in% ids_ok, , drop = FALSE]
# grupos prontos para os módulos 6 e 7
# attenção: as_biblio_project preserva apenas os campos canônicos, portanto a
# coluna auxiliar `tema` de dB não sobrevive à harmonização; o tema é derivado
# do título, que é o que um usuário faria com dados reais
tema_de_titulo <- function(t) {
  ifelse(grepl("^Silício", t), "silicio",
         ifelse(grepl("^Carbono", t), "carbono", "remoto"))
}
tema_B <- tema_de_titulo(x_analise$works$title)
per_B  <- ifelse(x_analise$works$year >= 2020, "2020-2025", "2010-2019")
g_per  <- form_groups(x_analise, per_B)
g_tema <- form_groups(x_analise, tema_B)
x_analise$works$periodo <- per_B

# ---- Corpus C: real (OpenAlex) ---------------------------------------------
x_openalex <- cache_rds("openalex_silicio", fetch_openalex("silicon salinity rice", n = 40L))

cat("objetos:", paste(c("x_did","x_bruto","x_limpo","x_analise","x_openalex","dB",
      "per_B","tema_B","g_per","g_tema","pal_agri","tema_agri","SEED","cache_rds"),
      collapse = ", "), "\n")
cat("dimensoes: did=", nrow(x_did$works), " bruto=", nrow(x_bruto$works),
    " limpo=", nrow(x_limpo$works), " analise=", nrow(x_analise$works),
    " openalex=", if (inherits(x_openalex,"biblio_project")) nrow(x_openalex$works) else NA, "\n", sep = "")
cat("biblium:", python_backend_status()$version, "\n")
