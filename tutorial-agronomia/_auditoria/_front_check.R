ck_dir <- "D:/RLibrary"
if (dir.exists(ck_dir)) .libPaths(c(ck_dir, .libPaths()))
setwd("D:/Walter/R/Pacotes_criados/Tutoriais/biblioIntegrator/_fragmentos")
s <- knitr::purl("m00-corpo.qmd", output = tempfile(fileext = ".R"), documentation = 0, quiet = TRUE)
env <- new.env(parent = globalenv())
r <- tryCatch({ source(s, local = env, echo = FALSE); "OK" },
              error = function(e) paste("ERRO:", conditionMessage(e)))
cat("front-matter:", r, "\n")
if (r == "OK") {
  cat("objetos no ambiente:", paste(ls(env)[1:14], collapse = ", "), "\n")
  cat("dimensoes: analise =", nrow(env$x_analise$works),
      "| g_per =", paste(dim(env$g_per), collapse = "x"),
      "| g_tema =", paste(dim(env$g_tema), collapse = "x"), "\n")
  cat("tema_B:\n"); print(table(env$tema_B))
  cat("per_B:\n"); print(table(env$per_B))
}
