## _probe10.R - fetch_opencitations: refutacao (endpoint correto?)
ck_dir <- "D:/RLibrary"
if (dir.exists(ck_dir)) .libPaths(c(ck_dir, .libPaths()))
suppressPackageStartupMessages(library(biblioIntegrator))

cat("1) como documentado (doi nu):\n")
r <- tryCatch(nrow(fetch_opencitations("10.1038/nature12373")), error = function(e) conditionMessage(e))
cat("   :", substr(paste(r, collapse = " "), 1, 90), "\n")

cat("2) com prefixo doi:\n")
r2 <- tryCatch(nrow(fetch_opencitations("doi:10.1038/nature12373")), error = function(e) conditionMessage(e))
cat("   :", substr(paste(r2, collapse = " "), 1, 90), "\n")

cat("3) URL da API direta (o que o pacote usa?):\n")
src <- deparse(biblioIntegrator:::fetch_opencitations)
cat(paste(src[grep("opencitations|api", src, ignore.case = TRUE)], collapse = "\n"), "\n")

cat("4) curl direto no endpoint v2 citations:\n")
resp <- tryCatch({
  u <- "https://api.opencitations.net/index/v2/doi/10.1038/nature12373/citations"
  h <- httr2::req_perform(httr2::req_timeout(httr2::request(u), 15))
  cat("status:", httr2::resp_status(h), "; bytes:", length(httr2::resp_body_string(h)), "\n")
}, error = function(e) conditionMessage(e))
