# ============================================================================
# _montar.R - monta o tutorial final a partir dos fragmentos
#   biblioIntegrator-agronomia.qmd  (documento único)
#   gabaritos/gNN-X.qmd             (um arquivo por exercício)
#   exercicios-aluno.R              (esqueleto sem respostas)
# Uso: Rscript.exe _montar.R
# ============================================================================
setwd("D:/Walter/R/Pacotes_criados/Tutoriais/biblioIntegrator")
frag <- function(f) readLines(file.path("_fragmentos", f), warn = FALSE, encoding = "UTF-8")
mods <- sprintf("m%02d", 1:12)

yaml <- c(
  "---",
  'title: "Bibliometria aplicada à Agronomia com o pacote biblioIntegrator"',
  'subtitle: "Tutorial progressivo para doutorandos: da importação de bases à análise semântica com Python e LLM"',
  'author: "Walter E. Pereira"',
  "date: today",
  "date-format: long",
  "lang: pt",
  "format:",
  "  html:",
  "    self-contained: true",
  "    embed-resources: true",
  "    toc: true",
  "    toc-depth: 3",
  '    toc-title: "Neste tutorial"',
  "    number-sections: true",
  "    code-tools: true",
  "    code-copy: true",
  "    df-print: paged",
  "  typst:",
  "    toc: true",
  "    number-sections: true",
  "    papersize: a4",
  "    margin:",
  "      x: 2cm",
  "      y: 2cm",
  "    fontsize: 10pt",
  "execute:",
  "  warning: false",
  "  message: false",
  "  cache: false",
  "editor: visual",
  "---", "")

# corpo = m00 sem o YAML + módulos 1..12
m00 <- frag("m00-corpo.qmd")
fim_yaml <- which(m00 == "---")
corpo <- c(m00[-seq_len(fim_yaml[2])], "")
for (m in mods) {
  f <- paste0(m, "-corpo.qmd")
  if (!file.exists(file.path("_fragmentos", f))) {
    warning("fragmento ausente: ", f); next
  }
  corpo <- c(corpo, frag(f), "")
}

# seção de gabaritos, na ordem dos módulos
gab <- c("# Gabaritos comentados", "",
  "Os gabaritos trazem o código completo, a leitura da saída com os números medidos",
  "nesta renderização, uma redação sugerida para a seção de Resultados e a lista dos",
  "erros mais comuns. Resolva a tarefa antes de abrir o gabarito.", "")
for (m in mods) {
  f <- paste0(m, "-gabaritos.qmd")
  if (!file.exists(file.path("_fragmentos", f))) next
  gab <- c(gab, frag(f), "")
}

refs <- c("# Referências", "",
  "Aria, M.; Cuccurullo, C. (2017). bibliometrix: An R-tool for comprehensive science",
  "mapping analysis. *Journal of Informetrics*, 11(4), 959-975.",
  "doi:10.1016/j.joi.2017.08.007",
  "",
  "Goutsmedt, A.; Claveau, F.; Truc, A. (2021). biblionetwork: A package for creating",
  "different types of bibliometric networks. <https://github.com/agoutsmedt/biblionetwork>",
  "",
  "Umek, L. (2026). Biblium: a Python library for comparative bibliometric analysis.",
  "*Scientometrics*, 131(5), 3359-3377. doi:10.1007/s11192-026-05636-8",
  "",
  "Priem, J.; Piwowar, H.; Orr, R. (2022). OpenAlex: a fully-open index of scholarly",
  "works, authors, venues, institutions, and concepts. arXiv:2205.01833",
  "",
  "Peroni, S.; Shotton, D. (2020). OpenCitations, an infrastructure organization for open",
  "scholarship. *Quantitative Science Studies*, 1(1), 428-444. doi:10.1162/qss_a_00023",
  "")

writeLines(c(yaml, corpo, gab, refs), "biblioIntegrator-agronomia.qmd", useBytes = TRUE)
cat("documento montado:", length(c(yaml, corpo, gab, refs)), "linhas\n")

# ---- extrai um arquivo por exercício (pasta gabaritos/) --------------------
dir.create("gabaritos", showWarnings = FALSE)
todos <- unlist(lapply(mods, function(m) {
  f <- paste0(m, "-gabaritos.qmd")
  if (file.exists(file.path("_fragmentos", f))) frag(f) else NULL
}))
ini <- grep("^## Gabarito do Exerc", todos)
if (length(ini)) {
  fim <- c(ini[-1] - 1L, length(todos))
  for (i in seq_along(ini)) {
    bloco <- todos[ini[i]:fim[i]]
    tit <- sub("^## Gabarito do Exercício ", "", bloco[1])
    num <- gsub("[^0-9]", "-", sub(" .*$", "", tit))
    num <- sub("-+$", "", num)
    nome <- file.path("gabaritos", paste0("g", num, ".qmd"))
    writeLines(bloco, nome, useBytes = TRUE)
  }
  cat("gabaritos extraídos:", length(ini), "\n")
}

# ---- gera o arquivo do aluno (tarefas sem resposta) ------------------------
cab <- c(
"# ============================================================================",
"# Bibliometria aplicada à Agronomia com o pacote biblioIntegrator",
"# Arquivo do aluno: preparação dos dados e esqueletos das tarefas, SEM respostas",
"#",
"# Requisitos: R >= 4.2.0 e o pacote biblioIntegrator instalado",
"# Sugestões usadas: ggplot2, igraph, arrow, duckdb, reticulate",
"# A semente 2026 é fixa para que todos obtenham os mesmos dados",
"#",
"# Roteiro de uso:",
"#   1. rode este arquivo até o fim, em blocos, para criar os corpora",
"#   2. resolva cada TAREFA escrevendo o código no lugar do TODO",
"#   3. confira no gabarito comentado do tutorial",
"# ============================================================================",
"",
"# ---- preparação do ambiente ------------------------------------------------",
"library(biblioIntegrator)",
"library(ggplot2)",
"library(igraph)",
"tema_agri <- theme_bw(base_size = 11) +",
"  theme(panel.grid.minor = element_blank(), legend.position = 'bottom')",
"theme_set(tema_agri)",
"pal_agri <- c('#2E5E4E', '#C97B3C', '#4A6FA5', '#8E6C88', '#7A9E7E', '#B5651D')",
"SEED <- 2026L",
"# Python/Biblium (opcional): aponte para um interpretador com o biblium instalado",
"# Sys.setenv(BIBLIOINTEGRATOR_PYTHON = 'caminho/para/python')",
"")

setup_aluno <- readLines("_setup_corpora.R", warn = FALSE, encoding = "UTF-8")
# remove o cabeçalho do helper e o bloco de mensagens finais
i1 <- grep("^# ---- Corpus A", setup_aluno)
setup_aluno <- setup_aluno[i1:length(setup_aluno)]
setup_aluno <- setup_aluno[!grepl("^cat\\(", setup_aluno)]
setup_aluno <- setup_aluno[!grepl("^\\)$", setup_aluno)]

tarefas <- c("", "# ============================================================================",
             "# TAREFAS", "# ============================================================================", "")
for (m in mods) {
  f <- file.path("_fragmentos", paste0(m, "-corpo.qmd"))
  if (!file.exists(f)) next
  b <- readLines(f, warn = FALSE, encoding = "UTF-8")
  tit <- b[grep("^# Módulo", b)][1]
  tt <- grep("^\\*\\*Tarefa [0-9]+\\.[0-9]+", b, value = TRUE)
  if (!length(tt)) next
  tarefas <- c(tarefas,
               "# ----------------------------------------------------------------------------",
               paste0("# ", sub("^# ", "", tit)),
               "# ----------------------------------------------------------------------------", "")
  for (t in tt) {
    linha <- gsub("\\*\\*", "", t)
    tarefas <- c(tarefas, strwrap(linha, width = 76, prefix = "# "), "", "# TODO", "")
  }
}
writeLines(c(cab, setup_aluno, tarefas), "exercicios-aluno.R", useBytes = TRUE)
cat("arquivo do aluno gerado:", length(c(cab, setup_aluno, tarefas)), "linhas\n")
