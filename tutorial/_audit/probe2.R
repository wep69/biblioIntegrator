## _probe2.R - Fase 2b: verificar sequestro de .Random.seed
ck_dir <- "D:/RLibrary"
if (dir.exists(ck_dir)) .libPaths(c(ck_dir, .libPaths()))
suppressPackageStartupMessages(library(biblioIntegrator))

x <- as_biblio_project(example_biblio())
g <- form_groups(x, ifelse(x$works$year < 2022, "early", "late"))

cat("=== 1. Estado sobrevive a chamada com seed? ===\n")
fn_seed <- Filter(function(n) {
  fo <- try(formals(get(n, envir = asNamespace("biblioIntegrator"))), silent = TRUE)
  !inherits(fo, "try-error") && "seed" %in% names(fo)
}, sort(getNamespaceExports("biblioIntegrator")))
cat("Funcoes com arg seed:", paste(fn_seed, collapse = ", "), "\n\n")

for (fn in intersect(fn_seed, c("compare_groups", "network_stability",
                                 "sensitivity_analysis", "validate_biblium"))) {
  set.seed(123); antes <- .Random.seed
  try(invisible(switch(fn,
    compare_groups      = compare_groups(x, g, permutations = 9, seed = 1),
    network_stability   = network_stability(x, B = 3, seed = 1),
    sensitivity_analysis = sensitivity_analysis(x, g, thresholds = 1:2,
                                                permutations = 9, seed = 1),
    validate_biblium    = validate_biblium(x, g, permutations = 9, seed = 1))), silent = TRUE)
  sobreviveu <- !exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE) ||
    identical(antes, .Random.seed)
  cat(sprintf("  %-20s sequestra gerador? %s\n", fn, !sobreviveu))
}

cat("\n=== 2. Duas sementes externas distintas dao resultados distintos? ===\n")
set.seed(7); r1 <- compare_groups(x, g, permutations = 99, seed = NULL)$p_value
set.seed(9); r2 <- compare_groups(x, g, permutations = 99, seed = NULL)$p_value
cat("seed=NULL com set.seed(7) vs (9) distintos?", !isTRUE(all.equal(r1, r2)), "\n")

set.seed(7); a <- { compare_groups(x, g, permutations = 9, seed = 1); runif(3) }
set.seed(9); b <- { compare_groups(x, g, permutations = 9, seed = 1); runif(3) }
cat("apos seed fixa, runif seguinte igual entre set.seed(7)/(9)?", isTRUE(all.equal(a, b)), "\n")
