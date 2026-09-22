## _gen.R - Fase 4: gerador de dados com verdade plantada (cache RDS)
ck_dir <- "D:/RLibrary"
if (dir.exists(ck_dir)) .libPaths(c(ck_dir, .libPaths()))
suppressPackageStartupMessages(library(biblioIntegrator))

SEED <- 20260923
dir.create("D:/Walter/R/Pacotes_criados/biblioIntegrator/tutorial/_cache",
           recursive = TRUE, showWarnings = FALSE)
OUT <- "D:/Walter/R/Pacotes_criados/biblioIntegrator/tutorial"

# ---- CENARIO A: corpus narrativo (~150 obras agronomicas, 2015-2025) ----
set.seed(20260923)
nA <- 150
temas <- list(
  k1 = c("silicon", "salinity", "rice", "drought", "silicon nutrition", "rice yield"),
  k2 = c("soil carbon", "cover crops", "sequestration", "soil organic matter",
         "soil aggregation", "no-till"),
  k3 = c("remote sensing", "UAV", "phenotyping", "hyperspectral",
         "yield prediction", "machine learning"))
tema_latente <- sample(1:3, nA, replace = TRUE, prob = c(.45, .35, .20))
fontes <- c("Field Crops Research", "Soil Science Society", "Agronomy Journal",
            "Remote Sensing Applications", "Plant Soil", "Precision Agriculture")
paises <- c("Brasil", "EUA", "China", "India", "Australia", "Alemanha", "Mexico")
bloco_autores <- c("Silva A; Pereira W; Costa C", "Martins B; Lima D",
                   "Pereira W; Gomez E", "Rao F; Silva A; Costa C",
                   "Nakamura T; Silva A", "Garcia M; Costa C",
                   "Smith J; Rao F", "Chen L; Nakamura T")

dA <- data.frame(
  title = sprintf("Título simulado %03d: %s em cultivos tropicais",
                  seq_len(nA), c("Silicon e estresse salino", "Carbono do solo",
                                 "Sensoriamento remoto")[tema_latente]),
  year = sample(2015:2025, nA, replace = TRUE, prob = c(3,4,5,6,8,9,10,12,13,14,14)/108),
  doi = paste0("10.1000/a.", seq_len(nA)),
  authors = sample(bloco_autores, nA, replace = TRUE),
  keywords = sapply(tema_latente, function(k)
    paste(sample(unlist(temas[k]), 3, replace = FALSE), collapse = "; ")),
  citations = pmax(0, round(exp(rnorm(nA, 2.2, 1.0)) - 1)),
  source = sample(fontes, nA, replace = TRUE, prob = c(.22,.18,.16,.14,.16,.14)),
  stringsAsFactors = FALSE)

# Verdade plantada A: artigo central citado por vários do tema silicon
hub <- 1
dA$citations[hub] <- 120
# Verdade plantada A: periódico "Field Crops Research" concentra impacto
dA$citations[dA$source == "Field Crops Research"] <-
  dA$citations[dA$source == "Field Crops Research"] + 10

# ---- CENARIO B: dados discrepantes (duplicatas plantadas) ----
dB <- dA[sample(nrow(dA), 30), ]
dB$doi[5] <- paste0("  HTTPS://DOI.ORG/", toupper(dB$doi[5]), "  ")
dB$doi[6] <- paste0("doi:", dB$doi[6])
dB$doi[7] <- NA
dB$year[8] <- NA_integer_
dB$citations[9] <- -2
dB$title[10] <- "   "
dB <- rbind(dB, dB[1, ])                       # duplicata de linha (DOI igual)
dB$doi[31] <- "10.9999/dup.novo"
dup2 <- dB[2, ]; dB <- rbind(dB, dup2)         # duplicata titulo+ano
dB$doi[32] <- NA                               # agora sem DOI -> duplicata por titulo+ano

# ---- CENARIO C: desbalanceamento (90/10) ----
n1 <- 130; n2 <- 14
dC <- data.frame(
  title = c(paste0("Soil carbon dynamics study ", 1:n1),
            paste0("Rare cover-crop economics study ", 1:n2)),
  year = sample(2015:2025, n1 + n2, replace = TRUE),
  doi = paste0("10.1000/c.", seq_len(n1 + n2)),
  authors = sample(bloco_autores, n1 + n2, replace = TRUE),
  keywords = c(rep("soil carbon; cover crops; sequestration", n1),
               rep("rare keyword; niche term", n2)),
  citations = sample(0:50, n1 + n2, replace = TRUE),
  source = "Simulated Journal", stringsAsFactors = FALSE)

# ---- CENARIO D: efeito relacional plantado (termo discriminante) ----
nD <- 40
dD <- data.frame(
  title = paste0("Group study ", 1:(2*nD)),
  year = rep(c(2020, 2024), c(nD, nD)),
  doi = paste0("10.1000/d.", 1:(2*nD)),
  authors = "Silva A",
  keywords = c(paste0("zeta_unique; common", sample(1:4, nD, replace = TRUE)),
               paste0("common", sample(1:4, nD, replace = TRUE))),
  citations = 10,
  source = "J", stringsAsFactors = FALSE)

# ---- E: bordas ----
dE <- head(example_biblio(), 2)

# ---- Salvar ----
saveRDS(list(A = dA, B = dB), file = file.path(OUT, "_cache", "cenarioA_B.rds"))
cat("Cenario A:", nrow(dA), "obras; temas:\n"); print(table(tema_latente))
cat("Cenario B:", nrow(dB), "obras (duplicatas plantadas: 2)\n")
cat("Semente mestre:", SEED, "\n")
