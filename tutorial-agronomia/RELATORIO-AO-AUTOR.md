# RELATÓRIO AO AUTOR — achados da auditoria do tutorial de Agronomia

**Para:** mantenedores do `biblioIntegrator`
**Origem:** auditoria executada durante a construção do tutorial "Bibliometria
aplicada à Agronomia" (12 módulos, 45 figuras, 106 tabelas, 3 corpora)
**Versão auditada:** `biblioIntegrator` 0.3.0, já com as correções do relatório
anterior (A1–A5)
**Método:** toda afirmação abaixo foi executada; nenhum comportamento é
descrito a partir da documentação. Cada achado traz o sintoma exato, a causa
provável no código e o teste de regressão sugerido.

---

## B1 (ALTA) — Colisão de `work_id` por hash linear: identificadores distintos para obras distintas

| Campo | Conteúdo |
|---|---|
| Sintoma | Em um acervo de 280 obras, `length(unique(x$works$work_id))` é 276: **quatro pares de obras distintas recebem o mesmo identificador**, sem qualquer aviso |
| Evidência | Par verificado: "Carbono do solo e plantas de cobertura em sorgo (estudo 246)" (2016, DOI …00246) e "… em milho (estudo 269)" (2016, DOI …00269) recebem ambos `W00047d60`; o identificador foi recalculado à mão com `biblioIntegrator:::.bi_id("W", paste(title, year, doi))` e devolve o mesmo valor para os dois |
| Causa provável | `.bi_id()` é um hash **linear**: `sum(utf8ToInt(z) * seq_along(utf8ToInt(z))) %% .Machine$integer.max`. Soma ponderada por posição tem colisão estrutural, e não apenas colisão de aniversário: alterações compensadas em posições de pesos consecutivos somam zero. Em títulos construídos por molde (prefixo fixo, sufixo numérico variável — situação comum em exportações reais e em corpora com títulos padronizados), a colisão é frequente |
| Consequência prática | Qualquer `merge()` por `work_id` infla as tabelas: os 853 vínculos de autoria do acervo analítico passam a 871 (18 vínculos duplicados) e 8 registros ficam com atribuição ambígua de autoria. `biblio_health()` não acusa nada, porque títulos e anos diferem |
| Efeito nas métricas | Índice h, g e m e o top-10 por h **não** mudam no acervo testado (9 autores afetados, desvio máximo de 2 obras e 16 citações), mas a soma da coluna `documents` em `biblio_metrics()` (871) diverge do número real de vínculos (853), e essa divergência é invisível para o usuário |
| Correção sugerida | trocar o hash linear por um digest com colisão desprezível (`digest::digest(..., algo = "xxhash64")`) ou por chave composta legível (`W-<doi>`); em qualquer caso, **detectar colisão na construção** e renomear com sufixo, avisando |
| Teste de regressão | construir 1.000 obras com títulos de molde fixo e `stopifnot(length(unique(p$works$work_id)) == 1000)`; e verificar que `nrow(merge(p$authorships, p$works["work_id"])) == nrow(p$authorships)` |
| Onde o tutorial documenta | Módulo 2, seção "o que o diagnóstico não vê" (com a reprodução da chave `doi:` vs `ty:` e a correção por `work_id` declarado na importação); Módulo 3 traz a versão reparada |

## B2 (ALTA) — `biblio_health()` devolve atestado de limpeza para entrada que não é projeto

| Campo | Conteúdo |
|---|---|
| Sintoma | `biblio_health(dB)`, com `dB` sendo o quadro plano, devolve as seis verificações com **zero** — isto é, um acervo "limpo" — em vez de erro |
| Causa provável | a função acessa `x$works`; em `data.frame`, `x$works` é `NULL` e todas as contagens caem em zero, sem validação de classe na entrada |
| Contraste | `audit_biblio(dB)` para com `inherits(x, "biblio_project") is not TRUE`; `deduplicate_biblio(dB)` para com `` `$` operator is invalid for atomic vectors `` |
| Correção sugerida | validar `inherits(x, "biblio_project")` na entrada de `biblio_health()`, como já fazem as funções vizinhas |
| Teste de regressão | `expect_error(biblio_health(example_biblio()), "biblio_project")` |

## B3 (MÉDIA) — `biblio_query()` sem argumento `engine` vaza erro de baixo nível do DuckDB

| Campo | Conteúdo |
|---|---|
| Sintoma | `biblio_query(<diretório Arrow>, "SELECT …")` devolve `{"exception_type":"IO","exception_message":"Cannot open file \"…\": Acesso negado."} ℹ Context: rapi_startup` |
| Causa provável | a assinatura é `biblio_query(path, sql)`, sem `engine`, enquanto `biblio_store()` e `biblio_load()` aceitam `c("arrow","duckdb")`. O caminho Arrow é entregue ao DuckDB, que falha no nível da camada C |
| Correção sugerida | aceitar `engine` (com `"auto"` detectando diretório Parquet × arquivo DuckDB) ou, no mínimo, detectar diretório e parar com mensagem orientadora |
| Teste de regressão | `expect_error(biblio_query(dir_arrow, "SELECT 1"), "engine|DuckDB")` com mensagem legível |

## B4 (MÉDIA) — `deduplicate_biblio(method=)` aceita e ignora o argumento

| Campo | Conteúdo |
|---|---|
| Sintoma | `deduplicate_biblio(x, method = "title")` devolve resultado `identical()` ao padrão; o corpo da função nunca referencia `method` |
| Consequência | o usuário acredita ter escolhido outro critério de deduplicação e obtém o mesmo, com aparência de escolha respeitada |
| Correção sugerida | implementar os métodos anunciados ou restringir a assinatura ao único método existente, documentando a limitação |
| Teste de regressão | `expect_error(deduplicate_biblio(x, method = "inexistente"), "match.arg")` ou teste que distinga de fato os métodos |

## B5 (MÉDIA) — `disruption_index()` devolve número com aparência de resultado em casos-limite

| Campo | Conteúdo |
|---|---|
| Sintoma | focal inexistente → `N_i = N_j = N_k = 0` e `disruption = 0`; `focal_references = character(0)` → `disruption = 1` (máximo) para qualquer focal |
| Consequência | dois extremos do índice são produzidos por entradas degeneradas, não por estrutura de citação; em lote, o erro passa despercebido |
| Correção sugerida | devolver `NA` quando não houver nenhum citante (`N_i + N_j + N_k == 0`) e avisar quando o focal não existir na tabela de arestas; opcionalmente avisar quando `focal_references` for vazio |
| Teste de regressão | `expect_true(is.na(disruption_index("ausente", edges, refs)$disruption))` |

## B6 (MÉDIA) — `term_frequency(stopwords=)` substitui a lista padrão em vez de estendê-la

| Campo | Conteúdo |
|---|---|
| Sintoma | com `stopwords = c("silicon")` em título inglês, o termo "the" **volta** à contagem: a lista passa a ser exatamente a informada |
| Consequência | o resultado fica silenciosamente errado para quem espera acrescentar termos de domínio à lista embutida |
| Correção sugerida | acrescentar por padrão (`union(stopwords_padrao, stopwords)`) e documentar a mudança de comportamento na versão |
| Teste de regressão | título "The effect of silicon in rice": com `stopwords = "silicon"` o termo "the" não deve aparecer |

## B7 (BAIXA) — Diferenças de convenção e de diagnóstico

| # | Achado | Detalhe | Sugestão |
|---|---|---|---|
| B7.1 | `term_frequency(field = "abstract")` em acervo sem resumos | devolve quadro de 0 linhas sem aviso, enquanto campo inexistente para com `'arg' should be one of "title", "abstract"` | distinguir "campo vazio" de "campo ausente" com aviso, ou documentar |
| B7.2 | `trend_topics(min_total =)` | não filtra: com `min_total = 50` a saída mantém 199 linhas | aplicar o limiar ou remover o argumento |
| B7.3 | `citation_velocity()` | idade = `pmax(1, ano_corrente − ano + 1)`, e não `ano_corrente − ano`; a convenção não está na assinatura nem no verbete | documentar a fórmula na página de ajuda |
| B7.4 | Ida e volta ao disco | não preserva nomes de linha e reordena atributos, de modo que `identical()` reprova (o `provenance` guarda `timestamp`) | recomendar `expect_equal(ignore_attr = TRUE)` na documentação de teste |
| B7.5 | Ruído do DuckDB | cinco linhas de aviso de inicialização vão para o stderr e `message = FALSE` não as captura (só `sink(type = "message")`) | silenciar na primeira conexão ou documentar o `sink` |
| B7.6 | `biblio_metrics()` | devolve `data.frame` (não lista, como `describe_biblio()`) e a coluna `author` já traz o **nome de exibição**, não o identificador | uniformizar o tipo de retorno e documentar o conteúdo da coluna |
| B7.7 | `fetch_openalex()` | `n = 0` → `HTTP 400 Bad Request`; `query = ""` devolve 25 obras sem aviso; `mailto` inválido é aceito | validar `n` e `query` na entrada |
| B7.8 | OpenAlex sem resumos | o campo `abstract` existe e vem vazio em 40/40 obras (limitação de licença da fonte) | registrar na documentação que `term_frequency(field = "abstract")` será vazio para acervos obtidos por essa rota |

## B8 (ALTA) — `work_id` repetido faz os dois motores construírem tabelas de contingência diferentes

| Campo | Conteúdo |
|---|---|
| Sintoma | com 280 obras e **276 identificadores distintos** (as quatro colisões do achado B1), `compare_groups()` nativo e `biblium_compare_groups()` discordam nos totais: 1.228 pares obra-termo no nativo contra 1.257 no Biblium — 29 excedentes, exatamente as palavras-chave sob os identificadores repetidos |
| Causa provável | o motor nativo resolve o vínculo com `match(work_id, ids)`, atribuindo os termos à **primeira** ocorrência do identificador; a ponte `to_biblium()` entrega a tabela larga e o Biblium **replica** a lista de termos em cada cópia da obra |
| Consequência | `validate_biblium()` acusa 0,770 % de diferença no qui-quadrado e 0,781 % no V de Cramér que **não** vêm dos motores, e sim dos identificadores. Removidas as cópias (276 linhas), as duas estatísticas coincidem na precisão da máquina (diferença 0,0000000) e só o p-valor de permutação segue divergindo (0,004 contra 0,006), como esperado |
| Correção sugerida | garantir unicidade de `work_id` na construção (ver B1); opcionalmente, `to_biblium()` pode avisar quando houver identificador repetido |
| Teste de regressão | com identificadores únicos, a diferença relativa entre motores deve ficar abaixo de 1e-6 para χ² e V |

## B9 (MÉDIA) — `llm_gap_analysis()` monta o prompt sem os nomes das fontes e dos termos

| Campo | Conteúdo |
|---|---|
| Sintoma | o resumo do corpus enviado ao modelo sai como `Top sources: 37, 34, 32, 29, 28` e `Top keywords: 77, 76, 76, 69, 65` — apenas as contagens |
| Causa provável | o prompt é construído com `paste()` sobre objetos `table`, e `paste()` descarta os nomes |
| Consequência | a análise de lacunas passa a operar sobre contagens anônimas, o que degrada a resposta e favorece conclusões sem relação com o vocabulário do acervo |
| Correção sugerida | incluir nome e contagem no resumo do corpus |
| Teste de regressão | inspecionar o prompt gerado e exigir que contenha ao menos um nome de periódico e um termo real do acervo |

## B10 (MÉDIA) — Retorno malformado do modelo pode virar quadro só de `NA`, sem aviso

| Campo | Conteúdo |
|---|---|
| Sintoma | sete cenários com o backend instrumentado: JSON válido → quadro utilizável; **chaves erradas (`[{"foo":"bar"}]`) → quadro com todas as células `NA` e nenhum aviso**; texto solto e JSON truncado → quadro vazio com o aviso "Could not parse structured response. Returning raw text."; `[]` → `argumento inválido para operador unário`; `{"a": 1}` → `` `$` operator is invalid for atomic vectors `` |
| Consequência | o caso das chaves erradas é o mais perigoso: a forma do resultado é a esperada, o conteúdo é vazio e o usuário não é avisado. Além disso, um registro com `work_id` inexistente foi aceito em silêncio e trazia a **maior** confiança declarada do conjunto (0,95) — filtrar por `confidence` não elimina referência fantasma |
| Correção sugerida | validar o esquema do retorno (colunas obrigatórias e identificadores pertencentes ao acervo) e avisar quando a taxa de células vazias for alta |
| Teste de regressão | alimentar `.llm_chat` com chaves erradas e exigir aviso em vez de silêncio |

## B11 (MÉDIA) — O aviso do Biblium não chega ao R como condição

| Campo | Conteúdo |
|---|---|
| Sintoma | `withCallingHandlers(warning = ...)` captura **zero** avisos: o texto sai pelo `stderr` do Python e exige `reticulate::py_capture_output()` para ser silenciado. Mensagem: "Groups are disjoint: the asymptotic chi-squared test is unbiased; the permutation results below are reported for completeness only." |
| Consequência | quem envolve a chamada em `tryCatch(..., warning = )` não silencia nada, e a mensagem polui relatórios e documentos renderizados |
| Correção sugerida | capturar o `stderr` na ponte e reemitir como `warning()` do R, ou documentar `py_capture_output()` na ajuda |
| Nota | com grupos **sobrepostos** o aviso desaparece, o que é coerente com o teor da mensagem |

## B12 (BAIXA) — Armadilhas de comparação entre motores e de ambiente

| # | Achado | Detalhe |
|---|---|---|
| B12.1 | Ordem das colunas difere | o nativo ordena alfabeticamente e o Biblium por frequência decrescente. Correlacionar resíduos **sem alinhar por nome** dá −0,3448; com alinhamento, 0,9977 — é a diferença entre "os motores discordam" e "os motores concordam" |
| B12.2 | Rótulos de entidade diferem com `entity = "author"` | o nativo devolve identificador (`A00000662`) e o Biblium, nome de exibição (`Silva AP`); a indexação por `[rownames(M1), colnames(M1)]` estoura com erro de subscrição |
| B12.3 | Precedência do interpretador Python | `python` (argumento) → `BIBLIOINTEGRATOR_PYTHON` (ambiente) → `options(biblioIntegrator.python)` → padrão do reticulate; **a variável de ambiente ganha da opção** |
| B12.4 | Interpretador fixado após o primeiro uso | com caminho inexistente, o reticulate cai em silêncio no interpretador padrão e o `reason` vira "Biblium could not be imported"; o interpretador fica fixado na sessão e `_bi_status_cache` pode devolver estado antigo |
| B12.5 | Nomes das variáveis de chave | `llm_configure()` lê `OLLAMA_API_KEY`, `GOOGLE_API_KEY`, `OPENAI_API_KEY`, `ANTHROPIC_API_KEY` e `HF_API_KEY` — **não** `GEMINI_API_KEY` nem `HF_TOKEN` |
| B12.6 | Acervos sem resumo | nenhum dos três corpora tem `abstract` (0 de 280, 0 de 40, 0 de 12): `.llm_format_abstracts()` devolve "No abstracts available." e as funções baseadas em resumo responderiam sobre o nada. Os payloads ainda são truncados (obras em 8.000 e resumos em 12.000 caracteres), o que invalida a conta ingênua de custo por "nº de obras × resumo médio" |
| B12.7 | `form_groups()` com um só nível | vetor constante falha com "contrastes podem ser aplicados apenas a fatores com 2 ou mais níveis", enquanto matriz de uma coluna passa — assimetria entre as duas entradas |
| B12.8 | `llm_citation_context()` | é a única função de LLM que não depende de servidor: sem referências no acervo emite "No references found in corpus." e devolve quadro 0×4, via de falha limpa e útil como exemplo didático |

## B13 (ALTA) — O motor nativo duplica pares de coautores: arestas em excesso e grau impossível

| Campo | Conteúdo |
|---|---|
| Sintoma | `bibliographic_network(x, "coauthor", engine = "native")` devolve **120 arestas** para 16 autores — exatamente n(n−1)/2, o máximo teórico —, mas só **91 pares distintos**: 29 pares aparecem nos dois sentidos. Com o mesmo acervo, `engine = "biblionetwork"` devolve 91 |
| Verificação independente | recalculado pelo autor deste relatório: 16 vértices, 120 pares possíveis, 120 arestas no nativo, 91 no biblionetwork, 91 pares distintos e **29 repetidos** |
| Causa provável | `.bi_edges_native()` agrega com `weight ~ from + to` sem ordenar o par, de modo que (A,B) e (B,A) contam como arestas separadas em rede não direcionada |
| Consequências medidas | grau máximo **20**, impossível com 16 vértices (máximo real 15); grau médio 15 contra 11,375; densidade 1,0 contra 0,7583; intermediação de Silva AP 0,4952 contra 0,4095; peso máximo de par 61 contra 64 |
| O que **não** muda | força e PageRank de cada autor são idênticos entre os motores (conferido nó a nó) — só as medidas baseadas em contagem de arestas divergem |
| Alcance silencioso | `engine = "auto"` usa `biblionetwork` para coautoria e **mascara** o defeito; ele aparece quando o motor nativo é pedido explicitamente — e é o motor que `network_stability()` usa internamente (ver B14) |
| Correção sugerida | ordenar o par antes de agregar (`pmin`/`pmax` sobre os identificadores) e/ou forçar `igraph::as_undirected(..., mode = "collapse")` na construção |
| Teste de regressão | em rede não direcionada, `expect_equal(ecount(g), length(unique(apply(as_edgelist(g), 1, function(z) paste(sort(z), collapse = "|")))))` |

## B14 (ALTA) — `network_stability()` ranqueia por grau do motor nativo, e não pela centralidade publicada

| Campo | Conteúdo |
|---|---|
| Sintoma | o ranking devolvido por `network_stability()` aponta Smith J em primeiro lugar (posto médio 1,65) quando a centralidade da rede publicada aponta Silva AP (grau 15, intermediação 0,4095, que na estabilidade aparece com posto 3,95) |
| Causa provável | a função reconstrói cada réplica com `engine = "native"` (herdando o defeito B13) e ordena por **grau**, não pela medida escolhida pelo usuário |
| Evidência | correlação de Spearman entre posto médio da estabilidade e grau do motor nativo = **−0,9904** |
| Consequência | a análise de robustez mede a estabilidade de outra rede, não a da rede relatada no artigo; o autor conclui que o nó mais central é instável quando o problema é a medida usada |
| Correção sugerida | expor o motor e a medida de centralidade em `network_stability()` e usar o mesmo motor da rede publicada |
| Teste de regressão | com o motor corrigido, o primeiro colocado da estabilidade deve coincidir com o primeiro colocado de `network_centrality()` |

## B15 (MÉDIA) — Casos-limite de comparação e de rede que devolvem número em vez de recusa

| # | Achado | Detalhe |
|---|---|---|
| B15.1 | Rede de citação com `references` vazia | `bibliographic_network(x, "citation")` para com `arguments imply differing number of rows: 0, 1`, mensagem que não menciona citação nem ausência de referências |
| B15.2 | `sensitivity_analysis()` | não devolve a coluna `permutations` prevista na especificação (só `threshold, entities, cramers_v, p_value`) e omite o χ², de modo que não se vê que o χ² é constante entre limiares; com `entity = "author"` os p-valores oscilam (0,500 / 0,515 / 0,415) |
| B15.3 | `compare_sources()` com uma única base | falha com `n < m` (origem no `combn`) em vez de devolver a cobertura trivial; sem nomes nos argumentos as colunas saem como `source1`/`source2` |
| B15.4 | `compare_groups(permutations = 0)` | não devolve `NA`: cai no ramo assintótico (`pchisq`) e devolve p = 0,000249, dando aparência de inferência exata |
| B15.5 | Um único grupo | `compare_groups()` devolve χ² = 0, V = 0 e p = 1 em silêncio; `group_mca()` ainda devolve duas dimensões (24,1 % e 14,9 %) sem aviso |
| B15.6 | `entity = "keyword"` com vetor de rótulos | os nomes de coluna saem como `factor(groups)2010-2019`; passar `cbind(...)` com nomes resolve |
| B15.7 | `igraph` 2.3.3 | `as.undirected()` está descontinuado; usar `as_undirected()` |

---

## Cobertura e método

- As receitas do tutorial foram exercitadas em 45 chamadas distintas, cobrindo as
  59 funções exportadas; nenhuma delas falhou por erro de assinatura.
- **1.223 expressões de chunk** e **1.049 expressões inline** foram executadas
  pelos verificadores, sem um único erro.
- Todos os números dos 12 módulos e dos 24 gabaritos são calculados no momento da
  renderização: nenhuma expressão de resultado foi digitada à mão no texto (o
  verificador aponta apenas duas menções legítimas a limiares e parâmetros).
- O documento final tem 52 figuras e 117 tabelas, cada uma com legenda e parágrafo
  de leitura; 134 rótulos de chunk, nenhum repetido.
- Dois achados candidatos foram **refutados** antes de virar texto e não constam
  aqui: (i) `validate_plan()` recusa módulos inválidos com mensagem clara;
  (ii) `fetch_opencitations()` normaliza corretamente as três formas de
  identificador (DOI nu, `doi:` e URL).
- O achado B1 foi verificado de forma independente pelo autor deste relatório,
  recalculando o hash à mão para o par em conflito; o achado B8 foi confirmado
  pela coincidência das estatísticas dos dois motores depois de removidas as
  obras com identificador repetido.

## Arquivos de verificação

- `_auditoria/_check_fragmentos.R` — executa cada fragmento e isola o erro por módulo
- `_auditoria/_check_inline.R` — avalia as expressões inline da prosa
- `_auditoria/_anti_leak.R` — procura números de resultado digitados no texto
- `_auditoria/_verifica_colisao.R` — reproduz e documenta a colisão de `work_id`
- `_auditoria/_verifica_native_edges.R` — reproduz as arestas duplicadas do motor nativo
- `_auditoria/_receitas.R` — executa as receitas de chamada de todos os módulos
- `_auditoria/_replica_pkgdown_quarto.R` — replica a chamada do pkgdown ao Quarto

---

## Achados da cadeia de publicação (pkgdown + Quarto)

Estes não são defeitos do `biblioIntegrator`, mas bloqueiam a publicação do site
e foram resolvidos com o remendo `tools/pkgdown-patch.R`. Ficam registrados
porque qualquer mantenedor que publique um artigo `.qmd` vai encontrá-los.

### C1 (ALTA) — pkgdown grava booleanos `yes`/`no` e o Quarto recusa

| Campo | Conteúdo |
|---|---|
| Sintoma | O build do site aborta na renderização do artigo com a única pista visível `! System command 'quarto' failed`, porque o pkgdown chama o Quarto em modo silencioso |
| Evidência | Reproduzindo a chamada do pkgdown com `quiet = FALSE`: `Error parsing quarto-defaults....yml: Aeson exception: Error in $: expected Bool, but encountered String` |
| Causa | `pkgdown:::quarto_render()` escreve o YAML de metadados com `yaml::write_yaml()`, que emite booleanos no estilo YAML 1.1 (`yes`/`no`); o parser do Quarto segue YAML 1.2, em que esses valores são texto |
| Correção aplicada | o remendo substitui apenas a gravação do arquivo, convertendo `yes`/`no` em `true`/`false`, linha a linha (o `$` do `sub()` casa com o fim da string inteira, e não de cada linha) |
| Efeito colateral | sem o remendo, **nenhum** artigo `.qmd` pode ser publicado |

### C2 (MÉDIA) — `--output-dir` do Quarto é resolvido contra a raiz do projeto

| Campo | Conteúdo |
|---|---|
| Sintoma | `No built file found for ...`, ou, no Windows, `os error 123: stat '...vignettes\C:\Users\...'` |
| Causa | o pkgdown informa a pasta temporária da sessão (caminho absoluto) e o Quarto a resolve relativa à raiz do projeto, juntando os dois caminhos |
| Correção aplicada | o remendo usa `<projeto>/.pkgdown-quarto-tmp` com caminho relativo e, após a renderização, procura o HTML nos dois locais possíveis, devolvendo ao pkgdown o diretório efetivamente usado |

### C3 (MÉDIA) — `vignettes/_quarto.yaml` precisa declarar a subpasta `articles/`

| Campo | Conteúdo |
|---|---|
| Sintoma | o projeto Quarto não encontra alvo e o `quarto render` falha |
| Causa | quando o arquivo não existe, o pkgdown cria um temporário com `project.render: '*.qmd'`, glob que não alcança `vignettes/articles/` |
| Correção aplicada | o repositório passa a versionar `vignettes/_quarto.yaml` com `- '*.qmd'` e `- 'articles/*.qmd'` |

### C4 (MÉDIA) — `reticulate` e o virtualenv: instalação e sessão precisam coincidir

| Campo | Conteúdo |
|---|---|
| Sintoma | `biblium importavel: FALSE` no CI, mesmo após `Successfully installed biblium-2.16.0` |
| Causa | o reticulate cria e usa o virtualenv `~/.virtualenvs/r-reticulate` e é nele que o `py_install()` instala; exportar `RETICULATE_PYTHON` para o Python base faz a sessão R rodar no base e não enxergar o pacote instalado no virtualenv |
| Correção aplicada | o workflow instala com `reticulate::py_install()` e aponta `BIBLIOINTEGRATOR_PYTHON` para o Python do virtualenv, sem definir `RETICULATE_PYTHON` |
| Pendência declarada | no runner do GitHub Actions o `reticulate::py_module_available("biblium")` continuou devolvendo `FALSE` mesmo com o virtualenv alinhado; por isso o site foi publicado com o build local (mesmo pipeline, `pkgdown::build_site()` com o remendo) e o workflow do pkgdown permanece como está — a publicação automática depende de resolver a detecção do backend Python no runner |

### C5 (BAIXA) — `pryr::mem_used()` na vinheta v08

| Campo | Conteúdo |
|---|---|
| Sintoma | o build do site aborta ao processar a vinheta v08 com `unable to load shared object '.../pryr.dll'` |
| Causa | `pryr` não estava declarado em `Imports` nem em `Suggests` (dependência não declarada) e a DLL instalada nesta máquina fora compilada sob outra versão do R; o `downlit`, que gera os links do site, carrega os pacotes citados no texto e aborta |
| Correção aplicada | a medição de memória da vinheta passa a usar `gc()`, que é base R |
| Recomendação | manter a regra de não citar pacotes que não estejam declarados no `DESCRIPTION` |

