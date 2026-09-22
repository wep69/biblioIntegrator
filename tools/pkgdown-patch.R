# ============================================================================
# tools/pkgdown-patch.R
#
# Remendo para a incompatibilidade entre o pkgdown e o Quarto na renderizacao
# de artigos .qmd:
#
#   pkgdown:::quarto_render() grava o YAML de metadados com yaml::write_yaml(),
#   que emite booleanos no estilo YAML 1.1 ("yes" / "no"). O parser do Quarto
#   (a partir da serie 1.6) segue YAML 1.2, em que "yes" e "no" sao TEXTO, e
#   aborta com:
#
#     Error parsing quarto-defaults....yml:
#     Aeson exception: Error in $: expected Bool, but encountered String
#
#   Sem este remendo, QUALQUER artigo .qmd faz o build do site falhar, e a
#   mensagem do Quarto nao aparece, porque o pkgdown o chama em modo silencioso
#   (a pista visivel e apenas "! System command 'quarto' failed").
#
# O remendo substitui apenas a gravacao do arquivo de metadados, convertendo os
# booleanos para "true" / "false". Nada mais do pkgdown e alterado.
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

#' Instala a versao corrigida de pkgdown:::quarto_render
patch_pkgdown_quarto <- function() {
  novo_quarto_render <- function(pkg, path, quiet = TRUE,
                                 frame = rlang::caller_env()) {
    metadata_path <- withr::local_tempfile(
      fileext = ".yml", pattern = "pkgdown-quarto-metadata-")
    writeLines(pkgdown_quarto_metadata(pkg), metadata_path)

    output_dir <- withr::local_tempdir("pkgdown-quarto-", .local_envir = frame)
    quarto::quarto_render(path, metadata_file = metadata_path,
                          quarto_args = c("--output-dir", output_dir),
                          quiet = quiet, as_job = FALSE)
    output_dir
  }
  assignInNamespace("quarto_render", novo_quarto_render, ns = "pkgdown")
  invisible(TRUE)
}

patch_pkgdown_quarto()
