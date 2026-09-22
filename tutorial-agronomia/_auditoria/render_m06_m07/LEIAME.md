# Ensaio de render dos Módulos 6 e 7

Esta pasta contém a única prova de que os quatro fragmentos entregues
(`_fragmentos/m06-corpo.qmd`, `m06-gabaritos.qmd`, `m07-corpo.qmd` e
`m07-gabaritos.qmd`) renderizam sem erro.

- `teste.qmd` — documento mínimo que carrega o ambiente comum (`../_setup_corpora.R`)
  e inclui os quatro fragmentos.
- `teste.html` — saída do render, com 10 figuras e 11 tabelas legendadas.
- `teste_files/` — imagens das figuras.
- `verif.R` — conferência automática do HTML: nenhum código R em linha sobrevivente,
  nenhum `NA`/`NULL` na prosa, nenhum número faltando antes de unidade, números-chave
  presentes, rótulos de bloco sem duplicata, seções obrigatórias presentes.

Para reproduzir, a partir da raiz do tutorial:

```
Rscript -e "quarto::quarto_render('_render_m06_m07/teste.qmd', output_format = 'html')"
cd _render_m06_m07 && Rscript verif.R
```
