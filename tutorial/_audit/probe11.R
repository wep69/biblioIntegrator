## _probe11.R - endpoint correto vs montado pelo pacote
ck_dir <- "D:/RLibrary"
if (dir.exists(ck_dir)) .libPaths(c(ck_dir, .libPaths()))

cat("URL montada pelo pacote:\n")
u_pacote <- "https://api.opencitations.net/index/v2/citations/10.1038/nature12373"
cat(u_pacote, "\n")
cat("URL correta da API v2 (docs):\n")
u_ok <- "https://api.opencitations.net/index/v2/doi/10.1038/nature12373/citations"
cat(u_ok, "\n\n")

for (rot in c("pacote", "correta")) {
  u <- switch(rot, pacote = u_pacote, correta = u_ok)
  h <- tryCatch(httr2::req_perform(httr2::req_timeout(httr2::request(u), 20)),
                error = function(e) e)
  if (inherits(h, "error")) {
    cat(rot, ": ERRO de rede/timeout:", substr(conditionMessage(h), 1, 90), "\n")
  } else {
    cat(rot, ": status =", httr2::resp_status(h), "\n")
  }
}
