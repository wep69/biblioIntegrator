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

---

## Cobertura e método

- As receitas do tutorial foram exercitadas em 45 chamadas distintas, cobrindo as
  59 funções exportadas; nenhuma delas falhou por erro de assinatura.
- Todos os números dos 12 módulos e dos 22 gabaritos são calculados no momento da
  renderização: uma planilha de verificação percorreu 800 expressões inline do
  documento sem encontrar número de resultado digitado à mão.
- Dois achados candidatos foram **refutados** antes de virar texto e não constam
  aqui: (i) `validate_plan()` recusa módulos inválidos com mensagem clara;
  (ii) `fetch_opencitations()` normaliza corretamente as três formas de
  identificador (DOI nu, `doi:` e URL).
- O achado B1 foi verificado de forma independente pelo autor do relatório,
  recalculando o hash à mão para o par em conflito.

## Arquivos de verificação

- `_auditoria/_check_fragmentos.R` — executa cada fragmento e isola o erro por módulo
- `_auditoria/_check_inline.R` — avalia as expressões inline da prosa
- `_auditoria/_anti_leak.R` — procura números de resultado digitados no texto
- `_auditoria/_verifica_colisao.R` — reproduz e documenta a colisão de `work_id`
- `_auditoria/_receitas.R` — executa as receitas de chamada de todos os módulos
