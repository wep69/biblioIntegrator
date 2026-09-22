# RELATORIO-AO-AUTOR — auditoria do biblioIntegrator 0.3.0

**Para:** mantenedores do biblioIntegrator (Walter E. Pereira, Magali H. P. Martinez)
**Origem:** tutorial operacional completo auditado (roteiro único, semente 20260923)
**Data:** 2026-09-23 · **Ambiente:** R 4.6.0, Windows 11, pacote instalado a partir do tarball 0.3.0
**Método:** sondagem completa das 59 funções exportadas com `formals()` extraído; toda
afirmação deste relatório foi executada em script (`_probe*.R` anexos), com refutação
própria antes da publicação (dois achados candidatos foram descartados pelo protocolo
de três tentativas: `validate_plan` recusa módulos inválidos e `rpys` recusa argumento
nomeado errado — ambos com erro claro; a falha anterior era do meu próprio sonda).

---

## Achados, em ordem de severidade

### A1 (ALTA) — Todas as funções LLM quebram com `ellmer` instalado: `seed` passado a `chat_ollama()`

| Campo | Conteúdo |
|---|---|
| Sintoma | `semantic_search(x, q)` → `Error: unused argument (seed = 42)` **antes de qualquer requisição**; igual para as demais funções LLM |
| Frequência | 3/3 tentativas idênticas |
| Causa provável | `R/llm_backend.R`, em `.llm_chat_ellmer()`: `ellmer::chat_ollama(model, base_url, seed = 42)`; `formals(ellmer::chat_ollama)` = `system_prompt, base_url, model, params, api_args, echo, api_key, credentials, api_headers` — **não há `seed`** |
| Alcance | Todas as 7 funções LLM com backend ellmer (busca, tópicos, resumo, gaps, expansão, classificação, contexto de citação) |
| Correção | remover `seed = 42` da chamada de `chat_ollama()`; se o objetivo é reprodutibilidade, propagar `seed` pelos `params` do provider que suportar |
| Teste de regressão | com Ollama inativo e `ellmer` instalado, `semantic_search()` deve falhar com erro de **conexão** (curl), não com `unused argument` |

Nota: com servidor ativo a rota alternativa sem `ellmer` (`.llm_chat_httr2`) funcionou
nos testes de backend; o tutorial demonstra a rota de configuração e o erro real.

### A2 (ALTA) — `fetch_opencitations()` monta URL sem o prefixo `doi:` → HTTP 400

| Campo | Conteúdo |
|---|---|
| Sintoma | `fetch_opencitations("10.1038/nature12373")` → `HTTP 400 Bad Request`, 3/3 tentativas |
| Evidência dupla | mesmo endpoint com `doi:` no identificador → **HTTP 200** com dados (`https://api.opencitations.net/index/v2/references/doi:10.1038/nature12373`); sem prefixo → 400 |
| Causa provável | `R/apis.R`: URL montada como `.../v2/{direction}/{id}` com `id` cru; a API v2 espera o PID completo (`doi:10.xxxx/…`) |
| Correção | prefixar `doi:` quando o identificador não contiver `:` (ou aceitar `10.` como DOI implícito) |
| Teste de regressão | chamada documentada deve retornar data.frame não-vazio com colunas `oci` etc.; rede simulada opcional |

### A3 (MÉDIA) — `biblio_store(overwrite = FALSE)` não recusa: sobrescreve mesmo assim

| Campo | Conteúdo |
|---|---|
| Sintoma | segundo `biblio_store(x, path, overwrite = FALSE)` sobre o mesmo caminho retorna o caminho, sem erro — os dados foram sobrescritos; 3/3 tentativas |
| Causa provável | `R/networks_storage.R`: o `unlink()` só ocorre quando `overwrite = TRUE`; em `FALSE` nada impede a escrita (`arrow::write_dataset`/`dbWriteTable(overwrite=TRUE)` prosseguem) |
| Correção | no início do `engine` escolhido: `if (!overwrite && (dir.exists(path) || file.exists(path))) stop("path exists; use overwrite=TRUE")` |
| Teste de regressão | `expect_error(biblio_store(x, p, engine = "arrow", overwrite = FALSE), "path exists")` após um primeiro store |

### A4 (MÉDIA) — `disruption_index()` aceita colunas erradas silenciosamente e devolve `NA`

| Campo | Conteúdo |
|---|---|
| Sintoma | `disruption_index("W1", data.frame(citing=…, cited=…), refs)` devolve `data.frame` com `N_i=0, N_j=0, N_k=0, disruption=NA`, sem aviso; 3/3 tentativas |
| Causa provável | `R/temporal_text.R`: acesso por nome (`a$citing_id[a$cited_id==focal_id]`) sem validação de colunas; nomes errados viram `NULL` → conjuntos vazios |
| Correção | validar `all(c("citing_id","cited_id") %in% names(citation_edges))` e `stop()` com mensagem apontando os nomes esperados |
| Teste de regressão | `expect_error(disruption_index("W1", data.frame(citing="a", cited="b"), character()), "citing_id")` |

### A5 (BAIXA) — Funções estocásticas sequestram `.Random.seed` do usuário

| Campo | Conteúdo |
|---|---|
| Sintoma | após `compare_groups(..., seed = 1)` (idem `network_stability`, `sensitivity_analysis`, `validate_biblium`), o gerador global do usuário está alterado; 4/4 funções verificadas |
| Causa provável | `set.seed(seed)` interno sem captura/restauração (padrão `withr::with_seed`) |
| Impacto | reprodutibilidade do código de usuário subsequente; no tutorial foi mitigado com guarda `preservando_semente()` |
| Correção | envolver o corpo estocástico com salvamento/restauração de `.Random.seed` (ou `withr::with_seed(seed, {...})`) nas 4 funções + `form_plan`/`run_plan` |
| Teste de regressão | `old <- .Random.seed; invisible(compare_groups(x, g, permutations = 9, seed = 1)); expect_identical(.Random.seed, old)` |

---

## Observações de uso (não bloqueantes)

1. `run_plan(plan, data = …)`: a ordem dos argumentos invertida (`run_plan(x, plan)`)
   devolve a mensagem confusa "`plan` must be created by form_plan()". Sugestão:
   validar a classe do primeiro argumento e mencionar a ordem esperada na mensagem.
2. `tfidf_terms(group)` aceita apenas `"year"`/`"source"` (`match.arg`), enquanto a
   prosa das vinhetas v03/v07 sugere agrupar por qualquer coluna. Sugestão: aceitar
   nome de coluna de `works` ou documentar a restrição na vinheta.
3. `network_communities()` aceita três métodos (`louvain`, `walktrap`, `label_prop`);
   `edge_betweenness` devolve erro claro de `match.arg` — correto, mas convém listar
   os métodos válidos na página de ajuda.
4. `biblium_backend_status()` leva ~8 s no primeiro uso (inicialização do
   reticulate). Sugestão: memoizar por sessão.

## Cobertura da auditoria

- 59 funções exportadas: `formals()` extraído para todas; execução no render cobriu
  46/59 (78,0%), com as 13 restantes classificadas por motivo real no tutorial
  (interativo, backend/LLM ativo exigido, rede instável).
- Dois achados candidatos foram **refutados** pelo protocolo de três tentativas e
  não constam como erro: validação de planos e recusa de argumento nomeado
  desconhecido em `rpys()`.

## Arquivos de referência

- Tutorial: `tutorial/tutorial-completo.qmd` (+ `.html` autocontido e `.pdf`)
- Scripts de sondagem: `tutorial/_audit/probe1.R` … `probe13.R`
- Cenários com verdade plantada: `tutorial/_audit/gen.R` (semente 20260923)
- Verificação da prosa: `tutorial/_audit/prose_check.R`, `anti_leak.R`, `dry.R`
