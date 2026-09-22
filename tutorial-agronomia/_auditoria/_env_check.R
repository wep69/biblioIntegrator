ck_dir <- "D:/RLibrary"
if (dir.exists(ck_dir)) .libPaths(c(ck_dir, .libPaths()))
cat("R:", R.version.string, "\n")
# instalar o tarball CORRIGIDO (pós-RELATORIO)
tb <- "D:/Walter/R/Pacotes_criados/biblioIntegrator/biblioIntegrator_0.3.0.tar.gz"
install.packages(tb, repos = NULL, type = "source", quiet = TRUE)
library(biblioIntegrator)
cat("biblioIntegrator:", as.character(packageVersion("biblioIntegrator")), "\n")
cat("ggplot2:", requireNamespace("ggplot2", quietly = TRUE), "\n")
cat("reticulate:", requireNamespace("reticulate", quietly = TRUE), "\n")
cat("arrow:", requireNamespace("arrow", quietly = TRUE),
    "| duckdb:", requireNamespace("duckdb", quietly = TRUE), "\n")
cat("igraph:", requireNamespace("igraph", quietly = TRUE), "\n")
cat("correcoes ativas? ",
    "store-guard:", isTRUE(tryCatch({biblio_store(as_biblio_project(example_biblio()), p <- tempfile(), "arrow"); FALSE}, error = function(e) grepl("path exists", conditionMessage(e)))),
    "\n")
bs <- backend_status(); print(bs)
pbs <- python_backend_status(); cat("Biblium:", pbs$version, "| disponivel:", pbs$available, "\n")
cat("Ollama ativo?", tryCatch({httr2::resp_status(httr2::req_perform(httr2::req_timeout(httr2::request("http://localhost:11434/api/tags"), 3))) == 200}, error = function(e) FALSE), "\n")
