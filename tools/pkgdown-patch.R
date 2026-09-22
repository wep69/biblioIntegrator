# ============================================================================
# tools/pkgdown-patch.R
#
# Remendos para a renderizacao de artigos Quarto (.qmd) no build do site.
#
# Problema 1 - booleanos do YAML
#   pkgdown:::quarto_render() grava o YAML de metadados com yaml::write_yaml(),
#   que emite booleanos no estilo YAML 1.1 ("yes" / "no"). O parser do Quarto
#   (serie 1.6 em diante) segue YAML 1.2, em que "yes" e "no" sao TEXTO, e
#   aborta com:
#
#     Error parsing quarto-defaults....yml:
#     Aeson exception: Error in $: expected Bool, but encountered String
#
# Problema 2 - caminho de saida no Windows
#   O mesmo trecho passa --output-dir com um caminho ABSOLUTO (a pasta temporaria
#   da sessao). No Windows, quando a pasta temporaria esta em outro volume que o
#   projeto, o Quarto junta os dois caminhos e falha com:
#
#     ERROR: A sintaxe do nome do arquivo ... esta incorreta (os error 123):
#     stat '...\vignettes\C:\Users\...\pkgdown-quarto-...'
#
#   A correcao passa um caminho relativo ao diretorio do projeto e, se os
#   volumes diferirem, usa uma pasta dentro do proprio projeto.
#
# Como o pkgdown chama o Quarto em modo silencioso, nos dois casos a unica pista
# visivel e "! System command 'quarto' failed", o que torna o diagnostico opaco.
#
# Uso:  source("tools/pkgdown-patch.R") antes de pkgdown::build_site()
# ============================================================================

#' Metadados do Quarto para um artigo, com booleanos no padrao YAML 1.2
#' @param pkg Objeto pkgdown.
#' @return Vetor de linhas do YAML.
pkgdown_quarto_metadata <- function(pkg) {
  linhas <- strsplit(yaml::as.yaml(pkgdown:::quarto_format(pkg)), "\n",
                     fixed = TRUE)[[1]]
  # o "$" de sub() casa com o fim da string inteira, e nao com o fim de cada
  # linha, por isso a conversao e feita linha a linha
  linhas <- sub("^([[:space:]]*[^:]+): yes[[:space:]]*$", "\\1: true", linhas)
  linhas <- sub("^([[:space:]]*[^:]+): no[[:space:]]*$", "\\1: false", linhas)
  linhas
}

#' Diretorio de saida do Quarto, sempre dentro do projeto
#'
#' O Quarto resolve \code{--output-dir} relativo a RAIZ DO PROJETO (a pasta
#' \code{vignettes}), e nao ao diretorio de trabalho, por isso o caminho de saida
#' precisa ficar dentro do projeto e ser informado de forma relativa.
#' @param pkg Objeto pkgdown.
#' @return Lista com caminho absoluto, caminho relativo e raiz do projeto.
pkgdown_quarto_output_dir <- function(pkg) {
  projeto <- file.path(pkg$src_path, "vignettes")
  out <- file.path(projeto, ".pkgdown-quarto-tmp")
  unlink(out, recursive = TRUE)
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  list(abs = out, rel = ".pkgdown-quarto-tmp", projeto = projeto)
}

#' Instala a versao corrigida de pkgdown:::quarto_render
patch_pkgdown_quarto <- function() {
  novo_quarto_render <- function(pkg, path, quiet = TRUE,
                                 frame = rlang::caller_env()) {
    metadata_path <- withr::local_tempfile(
      fileext = ".yml", pattern = "pkgdown-quarto-metadata-")
    writeLines(pkgdown_quarto_metadata(pkg), metadata_path)

    dirs <- pkgdown_quarto_output_dir(pkg)
    quarto::quarto_render(path, metadata_file = metadata_path,
                          quarto_args = c("--output-dir", dirs$rel),
                          quiet = quiet, as_job = FALSE)

    # o Quarto pode resolver o caminho relativo a raiz do projeto ou a pasta do
    # arquivo renderizado; procura o resultado nos dois casos
    candidatos <- c(dirs$abs,
                    file.path(dirs$projeto, "articles", ".pkgdown-quarto-tmp"))
    for (cand in candidatos) {
      if (length(list.files(cand, recursive = TRUE))) return(cand)
    }
    dirs$abs
  }
  assignInNamespace("quarto_render", novo_quarto_render, ns = "pkgdown")
  invisible(TRUE)
}

patch_pkgdown_quarto()
