## _probe12.R - confirmar causa: falta prefixo doi: no id
ck_dir <- "D:/RLibrary"
if (dir.exists(ck_dir)) .libPaths(c(ck_dir, .libPaths()))

dois_urls <- c(
  "com doi: (formato docs)" = "https://api.opencitations.net/index/v2/references/doi:10.1038/nature12373",
  "sem doi: (formato pacote)" = "https://api.opencitations.net/index/v2/references/10.1038/nature12373"
)
for (rot in names(dois_urls)) {
  h <- tryCatch(httr2::req_perform(httr2::req_timeout(httr2::request(dois_urls[rot]), 25)),
                error = function(e) e)
  if (inherits(h, "error")) cat(rot, ": ERRO:", substr(conditionMessage(h), 1, 80), "\n")
  else cat(rot, ": status =", httr2::resp_status(h), "; corpo (inicio):",
           substr(httr2::resp_body_string(h), 1, 60), "\n")
}
