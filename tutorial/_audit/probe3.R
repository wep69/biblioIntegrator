## _probe3.R - Fase 2: sondagem de comportamentos com dados discrepantes
ck_dir <- "D:/RLibrary"
if (dir.exists(ck_dir)) .libPaths(c(ck_dir, .libPaths()))
suppressPackageStartupMessages(library(biblioIntegrator))

ck <- function(rotulo, expr) {
  cat("\n##### ", rotulo, "\n", sep = "")
  r <- tryCatch(withCallingHandlers(expr,
        warning = function(w) { cat("  AVISO:", conditionMessage(w), "\n"); invokeRestart("muffleWarning") }),
        error = function(e) paste("ERRO:", conditionMessage(e)))
  if (!inherits(r, "character") || !grepl("^ERRO", paste(r, collapse = ""))) print(r)
  invisible(r)
}

x <- as_biblio_project(example_biblio())
str(x, max.level = 1)

cat("\n\n========== CENARIO B: dados discrepantes ==========\n")
set.seed(100)
d <- example_biblio()
d$doi[1] <- "  HTTPS://DOI.ORG/10.1000/AGRI.1  "   # maiuscula + prefixo + espacos
d$doi[2] <- "doi:10.1000/agri.2"                    # prefixo doi:
d$doi[3] <- NA                                      # ausente
d$year[4] <- NA_integer_                            # ano ausente
d$citations[5] <- -3                                # citacao negativa
d$title[6] <- "  "                                  # titulo vazio
dup <- d[1, ]; dup$doi <- "10.9999/duplicata.x"; d <- rbind(d, dup)
dup2 <- d[2, ]; d <- rbind(d, dup2)                 # duplicata titulo+ano
xb <- as_biblio_project(d, source = "cenario-B")

cat("\n--- biblio_health no cenário sujo ---\n")
h <- biblio_health(xb); print(h)

cat("\n--- deduplicate: doi_title_year ---\n")
y <- deduplicate_biblio(xb, method = "doi_title_year")
cat("antes:", nrow(xb$works), "depois:", nrow(y$works), "\n")
cat("provenance tail:\n"); print(tail(y$provenance, 3))

cat("\n--- audit_biblio ---\n")
a <- audit_biblio(xb); print(a)

cat("\n\n========== CENARIO C: desbalanceamento ==========\n")
set.seed(200)
n1 <- 120; n2 <- 12
dc <- data.frame(
  title = c(paste0("Soil carbon study ", 1:n1),
            paste0("Rare topic ", 1:n2)),
  year  = sample(2015:2025, n1 + n2, replace = TRUE),
  doi   = paste0("10.1000/c.", seq_len(n1 + n2)),
  authors = "Silva A; Pereira W",
  keywords = c(sample(c("soil carbon; sequestration; climate", rep("soil carbon; agriculture", n1 - 1)), n1, replace = TRUE),
               rep("rare special term; niche", n2)),
  citations = sample(0:40, n1 + n2, replace = TRUE),
  source = "Test Journal", stringsAsFactors = FALSE)
xc <- as_biblio_project(dc)
gc_ <- form_groups(xc, ifelse(grepl("Soil carbon", xc$works$title), "domin", "raro"))

cat("\n--- compare_groups desbalanceado ---\n")
cmp <- compare_groups(xc, gc_, entity = "keyword", permutations = 199, seed = 42)
print(cmp)
resid <- association_residuals(cmp)
cat("residuals nrow:", nrow(resid), "\n"); print(head(resid, 4))

cat("\n--- sensitivity_analysis ---\n")
s <- sensitivity_analysis(xc, gc_, thresholds = 1:2, permutations = 49, seed = 42)
print(s)

cat("\n\n========== CENARIO D: efeito relacional ==========\n")
# termo "zeta_unique" presente só no grupo A, nunca no B
nA <- 30; nB <- 30
dd <- data.frame(
  title = c(paste0("Group A study ", 1:nA), paste0("Group B study ", 1:nB)),
  year = rep(c(2020, 2024), c(nA, nB)),
  doi = paste0("10.1000/d.", 1:(nA + nB)),
  authors = "Silva A",
  keywords = c(paste0("zeta_unique; common", sample(1:5, nA, replace = TRUE)),
               paste0("common", sample(1:5, nB, replace = TRUE))),
  citations = 10, source = "J", stringsAsFactors = FALSE)
xd <- as_biblio_project(dd)
gd <- form_groups(xd, rep(c("A", "B"), c(nA, nB)))
cmpd <- compare_groups(xd, gd, permutations = 199, seed = 42)
print(cmpd)

cat("\n\n========== CENARIO E: bordas ==========\n")
xe <- as_biblio_project(head(example_biblio(), 2))
ck("corpus minimo: health", biblio_health(xe))
ck("corpus minimo: metrics", biblio_metrics(xe))
ge <- form_groups(xe, c("A", "B"))
ck("corpus minimo: compare 99 perm", compare_groups(xe, ge, permutations = 19, seed = 1))
ck("temporal_growth", temporal_growth(xe))
g2 <- bibliographic_network(xe, "coauthor"); print(g2)
ck("network_stability B=5", network_stability(xe, type = "coauthor", B = 5, seed = 1))

cat("\n--- disruption_index: assinatura direta ---\n")
ck("disruption com edges inventados", disruption_index("W1",
   data.frame(citing = c("W2","W3"), cited = "W1"),
   data.frame(citing = c("W2","W3"), cited = c("W0","W1"))))

cat("\n\n========== FASE 2: form_plan/run_plan ==========\n")
p <- form_plan(analyses = c("health", "descriptive"))
print(p)
ck("validate_plan", validate_plan(p))
ck("plan invalido", validate_plan(form_plan(analyses = c("modulo_inexistente"))))

cat("\n\n========== bibliometrix / biblium / exports ==========\n")
ck("to_bibliometrix", nrow(to_bibliometrix(x)))
ck("to_biblium colnames", names(to_biblium(x)))
ck("export_biblio csv", { f <- tempfile(fileext = ".csv"); export_biblio(x, f, format = "csv"); file.exists(f) })
