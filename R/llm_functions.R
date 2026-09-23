# LLM-Powered Functions for biblioIntegrator
# Semantic search, topic discovery, summarization, gap analysis,
# query expansion, classification, and citation context analysis

# --- Helper: Format works for LLM ---

.llm_format_works <- function(x, max_chars = 8000) {
  w <- x$works
  lines <- character(nrow(w))
  for (i in seq_len(nrow(w))) {
    lines[i] <- sprintf(
      "[%s] %s (%d). %s. %s. Citations: %d.",
      w$work_id[i],
      substr(w$title[i], 1, 120),
      w$year[i],
      w$source[i],
      substr(w$abstract[i], 1, 200),
      w$cited_by_count[i]
    )
  }
  text <- paste(lines, collapse = "\n")
  if (nchar(text) > max_chars) {
    text <- substr(text, 1, max_chars)
  }
  text
}

.llm_format_abstracts <- function(x, work_ids = NULL, max_chars = 12000) {
  w <- x$works
  if (!is.null(work_ids)) {
    w <- w[w$work_id %in% work_ids, ]
  }
  w <- w[!is.na(w$abstract) & nzchar(w$abstract), ]
  if (nrow(w) == 0) return("No abstracts available.")

  lines <- sprintf("[%s] %s\n%s\n", w$work_id, w$title, w$abstract)
  text <- paste(lines, collapse = "\n---\n")
  if (nchar(text) > max_chars) {
    text <- substr(text, 1, max_chars)
  }
  text
}

.llm_parse_json <- function(text) {
  if (requireNamespace("jsonlite", quietly = TRUE)) {
    # Try to extract JSON from markdown code blocks
    json_match <- regmatches(text, regexpr("```json\\n(.+?)\\n```", text,
                                            perl = TRUE))
    if (length(json_match) > 0) {
      text <- sub("```json\\n", "", sub("\\n```", "", json_match))
    }
    # Try to find JSON array or object
    if (!grepl("^\\s*[\\[{]", text)) {
      json_match <- regmatches(text, regexpr("\\[\\{.+\\}\\]", text,
                                              perl = TRUE))
      if (length(json_match) > 0) text <- json_match
    }
    tryCatch(
      jsonlite::fromJSON(text, simplifyVector = FALSE),
      error = function(e) NULL
    )
  } else {
    NULL
  }
}

#' Valida o quadro montado a partir do retorno do modelo
#'
#' Um JSON com as chaves erradas (por exemplo `[{"foo":"bar"}]`) produzia um
#' data.frame com todas as celulas `NA` e NENHUM aviso, o que e o pior caso:
#' o resultado tem a forma esperada e nao tem conteudo. Esta verificacao cobra as
#' colunas obrigatorias e avisa quando a maior parte das celulas fica vazia.
#' @param df Data frame montado a partir do retorno.
#' @param obrigatorias Vetor de colunas que precisam existir.
#' @return O proprio `df`, invisivel.
#' @noRd
.llm_check_return <- function(df, obrigatorias) {
  if (!nrow(df)) return(invisible(df))
  faltando <- setdiff(obrigatorias, names(df))
  if (length(faltando))
    stop("O retorno do modelo nao tem as colunas esperadas: ",
         paste(faltando, collapse = ", "), call. = FALSE)
  vazias <- mean(is.na(unlist(df[obrigatorias])))
  if (vazias > 0.5)
    warning(sprintf(paste("O retorno do modelo tem %.0f%% de celulas vazias nas",
                          "colunas obrigatorias; verifique provedor, modelo e prompt."),
                    100 * vazias), call. = FALSE)
  invisible(df)
}

# --- 1. Semantic Search ---

#' Semantic search in bibliographic corpus
#'
#' Uses an LLM to find works relevant to a natural language query,
#' going beyond keyword matching to understand meaning and context.
#'
#' @param x A \code{biblio_project}.
#' @param query Character. Natural language search query.
#' @param n Integer. Maximum number of results. Default: 10.
#' @param provider Character. LLM provider override.
#' @param model Character. Model override.
#' @param api_key Character. API key override.
#'
#' @return A data frame with columns: work_id, title, score, reason.
#'
#' @details
#' This function sends the corpus metadata (titles, abstracts, keywords)
#' to an LLM along with the search query, and asks the LLM to rank
#' works by semantic relevance.
#'
#' Requires an LLM provider to be configured with \code{\link{llm_configure}}.
#'
#' @export
#' @examples
#' \dontrun{
#' llm_configure(provider = "ollama")
#' x <- as_biblio_project(example_biblio())
#' results <- semantic_search(x, "sustainable agriculture")
#' head(results)
#' }
semantic_search <- function(x, query, n = 10, provider = NULL,
                            model = NULL, api_key = NULL) {
  if (!inherits(x, "biblio_project")) {
    stop("`x` must be a biblio_project.", call. = FALSE)
  }
  if (!is.null(api_key)) {
    llm_configure(provider = provider %||% "ollama", api_key = api_key)
  }

  works_text <- .llm_format_works(x)
  prompt <- .prompt_semantic_search(query, works_text, n)

  messages <- list(
    list(role = "system", content = .prompt_system_bibliometric()),
    list(role = "user", content = prompt)
  )

  response <- .llm_chat(messages, provider = provider, model = model,
                         json_mode = TRUE)

  parsed <- .llm_parse_json(response)
  if (is.null(parsed) || !is.list(parsed)) {
    message("Could not parse structured response. Returning raw text.")
    return(data.frame(work_id = character(0), title = character(0),
                      score = numeric(0), reason = character(0),
                      stringsAsFactors = FALSE))
  }

  result <- do.call(rbind, lapply(parsed, function(p) {
    data.frame(
      work_id = as.character(p$work_id %||% NA),
      title   = as.character(p$title %||% NA),
      score   = as.numeric(p$score %||% NA),
      reason  = as.character(p$reason %||% NA),
      stringsAsFactors = FALSE
    )
  }))

  .llm_check_return(result, c("work_id", "score"))
  result[order(-result$score), ]
}

# --- 2. Topic Discovery ---

#' Discover research topics using LLM
#'
#' Uses an LLM to identify distinct research themes in the corpus
#' without requiring a predefined number of topics.
#'
#' @param x A \code{biblio_project}.
#' @param n_topics Integer or NULL. Suggested number of topics. NULL = auto.
#' @param provider Character. LLM provider override.
#' @param model Character. Model override.
#'
#' @return A list with: topics (data frame), raw_response.
#'
#' @export
#' @examples
#' \dontrun{
#' llm_configure(provider = "ollama")
#' x <- as_biblio_project(example_biblio())
#' topics <- llm_topic_discovery(x, n_topics = 3)
#' print(topics$topics)
#' }
llm_topic_discovery <- function(x, n_topics = NULL, provider = NULL,
                                model = NULL) {
  if (!inherits(x, "biblio_project")) {
    stop("`x` must be a biblio_project.", call. = FALSE)
  }

  abstracts_text <- .llm_format_abstracts(x)
  prompt <- .prompt_topic_discovery(abstracts_text, n_topics)

  messages <- list(
    list(role = "system", content = .prompt_system_bibliometric()),
    list(role = "user", content = prompt)
  )

  response <- .llm_chat(messages, provider = provider, model = model,
                         json_mode = TRUE)

  parsed <- .llm_parse_json(response)
  if (is.null(parsed) || !is.list(parsed)) {
    return(list(topics = NULL, raw_response = response))
  }

  topics_df <- do.call(rbind, lapply(parsed$topics, function(t) {
    data.frame(
      name        = as.character(t$name %||% NA),
      description = as.character(t$description %||% NA),
      keywords    = paste(t$keywords %||% character(0), collapse = ", "),
      size        = as.integer(t$size %||% 0),
      work_ids    = paste(t$work_ids %||% character(0), collapse = ", "),
      stringsAsFactors = FALSE
    )
  }))

  list(topics = topics_df, raw_response = response)
}

# --- 3. Summarize ---

#' Summarize corpus using LLM
#'
#' Generates an intelligent summary of the bibliographic corpus,
#' synthesizing across works rather than listing them.
#'
#' @param x A \code{biblio_project}.
#' @param work_ids Character vector. Specific work IDs to summarize.
#'   NULL = all works with abstracts.
#' @param style Character. Summary style: "executive", "methods",
#'   "gaps", or "comprehensive".
#' @param provider Character. LLM provider override.
#' @param model Character. Model override.
#'
#' @return Character. The generated summary text.
#'
#' @export
#' @examples
#' \dontrun{
#' llm_configure(provider = "ollama")
#' x <- as_biblio_project(example_biblio())
#' summary <- llm_summarize(x, style = "executive")
#' cat(summary)
#' }
llm_summarize <- function(x, work_ids = NULL, style = "executive",
                          provider = NULL, model = NULL) {
  if (!inherits(x, "biblio_project")) {
    stop("`x` must be a biblio_project.", call. = FALSE)
  }

  style <- match.arg(style, c("executive", "methods", "gaps", "comprehensive"))

  abstracts_text <- .llm_format_abstracts(x, work_ids)
  prompt <- .prompt_summarize(abstracts_text, style)

  messages <- list(
    list(role = "system", content = .prompt_system_bibliometric()),
    list(role = "user", content = prompt)
  )

  .llm_chat(messages, provider = provider, model = model)
}

# --- 4. Gap Analysis ---

#' Identify research gaps using LLM
#'
#' Analyzes the corpus to identify understudied areas, methodological
#' gaps, or geographic biases.
#'
#' @param x A \code{biblio_project}.
#' @param focus Character. Analysis focus: "thematic", "methodological",
#'   "geographic", or "temporal".
#' @param provider Character. LLM provider override.
#' @param model Character. Model override.
#'
#' @return A data frame with columns: gap, evidence, impact, suggestion.
#'
#' @export
#' @examples
#' \dontrun{
#' llm_configure(provider = "ollama")
#' x <- as_biblio_project(example_biblio())
#' gaps <- llm_gap_analysis(x, focus = "thematic")
#' print(gaps)
#' }
llm_gap_analysis <- function(x, focus = "thematic", provider = NULL,
                             model = NULL) {
  if (!inherits(x, "biblio_project")) {
    stop("`x` must be a biblio_project.", call. = FALSE)
  }

  focus <- match.arg(focus, c("thematic", "methodological",
                               "geographic", "temporal"))

  # o resumo precisa dos NOMES: paste() sobre um objeto table descarta os rotulos,
  # e o prompt chegava ao modelo como uma lista de contagens anonimas
  w <- x$works
  resumo_tab <- function(tab, n = 5L) {
    if (!length(tab)) return("(sem dados)")
    t5 <- utils::head(tab, n)
    paste(sprintf("%s (%d)", names(t5), as.integer(t5)), collapse = ", ")
  }
  corpus_summary <- sprintf(
    "Corpus: %d works, %d-%d, %d unique sources, %d keywords.\nTop sources: %s\nTop keywords: %s",
    nrow(w),
    min(w$year, na.rm = TRUE), max(w$year, na.rm = TRUE),
    length(unique(w$source)),
    length(unique(x$keywords$keyword)),
    resumo_tab(sort(table(w$source), decreasing = TRUE), 5L),
    resumo_tab(sort(table(x$keywords$keyword), decreasing = TRUE), 10L)
  )

  prompt <- .prompt_gap_analysis(corpus_summary, focus)

  messages <- list(
    list(role = "system", content = .prompt_system_bibliometric()),
    list(role = "user", content = prompt)
  )

  response <- .llm_chat(messages, provider = provider, model = model,
                         json_mode = TRUE)

  parsed <- .llm_parse_json(response)
  if (is.null(parsed) || !is.list(parsed)) {
    message("Could not parse structured response. Returning raw text.")
    return(data.frame(gap = character(0), evidence = character(0),
                      impact = character(0), suggestion = character(0),
                      stringsAsFactors = FALSE))
  }

  gaps_df <- do.call(rbind, lapply(parsed$gaps, function(g) {
    data.frame(
      gap       = as.character(g$gap %||% NA),
      evidence  = as.character(g$evidence %||% NA),
      impact    = as.character(g$impact %||% NA),
      suggestion = as.character(g$suggestion %||% NA),
      stringsAsFactors = FALSE
    )
  }))
  .llm_check_return(gaps_df, c("gap", "evidence", "suggestion"))
  gaps_df
}

# --- 5. Query Expansion ---

#' Expand search query using LLM
#'
#' Uses an LLM to expand a search query with synonyms, related terms,
#' and Boolean operators optimized for a specific database.
#'
#' @param query Character. Original search query.
#' @param database Character. Target database: "scopus", "wos",
#'   "openalex", "pubmed", or "generic".
#' @param provider Character. LLM provider override.
#' @param model Character. Model override.
#'
#' @return A list with: expanded_query, added_terms, explanation.
#'
#' @export
#' @examples
#' \dontrun{
#' llm_configure(provider = "ollama")
#' result <- llm_query_expand("soil carbon sequestration",
#'                            database = "openalex")
#' cat(result$expanded_query)
#' }
llm_query_expand <- function(query, database = "openalex",
                             provider = NULL, model = NULL) {
  database <- match.arg(database, c("scopus", "wos", "openalex",
                                     "pubmed", "generic"))

  prompt <- .prompt_query_expand(query, database)

  messages <- list(
    list(role = "system", content = .prompt_system_bibliometric()),
    list(role = "user", content = prompt)
  )

  response <- .llm_chat(messages, provider = provider, model = model,
                         json_mode = TRUE)

  parsed <- .llm_parse_json(response)
  if (is.null(parsed) || !is.list(parsed)) {
    return(list(expanded_query = response, added_terms = character(0),
                explanation = "Could not parse structured response."))
  }

  list(
    expanded_query = as.character(parsed$expanded_query %||% query),
    added_terms    = as.character(parsed$added_terms %||% character(0)),
    explanation    = as.character(parsed$explanation %||% "")
  )
}

# --- 6. Classification ---

#' Classify works into thematic categories using LLM
#'
#' Assigns each work in the corpus to one or more user-defined
#' (or LLM-suggested) categories.
#'
#' @param x A \code{biblio_project}.
#' @param categories Character vector. Categories to use. If NULL,
#'   the LLM will suggest categories.
#' @param provider Character. LLM provider override.
#' @param model Character. Model override.
#'
#' @return A data frame with columns: work_id, title, primary,
#'   secondary, confidence, reason.
#'
#' @export
#' @examples
#' \dontrun{
#' llm_configure(provider = "ollama")
#' x <- as_biblio_project(example_biblio())
#' classified <- llm_classify(x, categories = c("Agronomy", "Ecology",
#'                                               "Economics"))
#' print(classified)
#' }
llm_classify <- function(x, categories = NULL, provider = NULL,
                         model = NULL) {
  if (!inherits(x, "biblio_project")) {
    stop("`x` must be a biblio_project.", call. = FALSE)
  }

  works_text <- .llm_format_works(x)

  if (is.null(categories)) {
    # Ask LLM to suggest categories first
    suggest_prompt <- paste0(
      "Based on these works, suggest 5-8 thematic categories.\n\n",
      works_text, "\n\n",
      "Return JSON: {\"categories\": [\"Cat1\", \"Cat2\", ...]}"
    )
    messages <- list(
      list(role = "system", content = .prompt_system_bibliometric()),
      list(role = "user", content = suggest_prompt)
    )
    cat_response <- .llm_chat(messages, provider = provider, model = model,
                               json_mode = TRUE)
    cat_parsed <- .llm_parse_json(cat_response)
    categories <- cat_parsed$categories %||%
      c("General", "Methods", "Theory", "Application", "Review")
  }

  prompt <- .prompt_classify(works_text, categories)

  messages <- list(
    list(role = "system", content = .prompt_system_bibliometric()),
    list(role = "user", content = prompt)
  )

  response <- .llm_chat(messages, provider = provider, model = model,
                         json_mode = TRUE)

  parsed <- .llm_parse_json(response)
  if (is.null(parsed) || !is.list(parsed)) {
    message("Could not parse structured response. Returning raw text.")
    return(data.frame(work_id = character(0), title = character(0),
                      primary = character(0), secondary = character(0),
                      confidence = numeric(0), reason = character(0),
                      stringsAsFactors = FALSE))
  }

  do.call(rbind, lapply(parsed, function(p) {
    data.frame(
      work_id   = as.character(p$work_id %||% NA),
      title     = as.character(p$title %||% NA),
      primary   = as.character(p$primary %||% NA),
      secondary = paste(p$secondary %||% character(0), collapse = ", "),
      confidence = as.numeric(p$confidence %||% NA),
      reason    = as.character(p$reason %||% NA),
      stringsAsFactors = FALSE
    )
  }))
}

# --- 7. Citation Context ---

#' Analyze citation context using LLM
#'
#' Classifies the context in which works are cited (support, contrast,
#' method, background, extension).
#'
#' @param x A \code{biblio_project}.
#' @param text Character. Text containing citations to analyze.
#'   If NULL, uses abstracts from the corpus.
#' @param provider Character. LLM provider override.
#' @param model Character. Model override.
#'
#' @return A data frame with columns: cited_id, context_type,
#'   snippet, explanation.
#'
#' @export
#' @examples
#' \dontrun{
#' llm_configure(provider = "ollama")
#' x <- as_biblio_project(example_biblio())
#' contexts <- llm_citation_context(x)
#' print(contexts)
#' }
llm_citation_context <- function(x, text = NULL, provider = NULL,
                                 model = NULL) {
  if (!inherits(x, "biblio_project")) {
    stop("`x` must be a biblio_project.", call. = FALSE)
  }

  if (is.null(text)) {
    # Use abstracts as proxy text
    text <- .llm_format_abstracts(x, max_chars = 6000)
  }

  # Build list of cited works
  refs <- x$references
  if (nrow(refs) == 0) {
    message("No references found in corpus.")
    return(data.frame(cited_id = character(0), context_type = character(0),
                      snippet = character(0), explanation = character(0),
                      stringsAsFactors = FALSE))
  }

  cited_works <- paste(sprintf("- %s: %s", refs$cited_id,
                                refs$cited_title %||% "unknown"),
                       collapse = "\n")

  prompt <- .prompt_citation_context(text, cited_works)

  messages <- list(
    list(role = "system", content = .prompt_system_bibliometric()),
    list(role = "user", content = prompt)
  )

  response <- .llm_chat(messages, provider = provider, model = model,
                         json_mode = TRUE)

  parsed <- .llm_parse_json(response)
  if (is.null(parsed) || !is.list(parsed)) {
    message("Could not parse structured response. Returning raw text.")
    return(data.frame(cited_id = character(0), context_type = character(0),
                      snippet = character(0), explanation = character(0),
                      stringsAsFactors = FALSE))
  }

  do.call(rbind, lapply(parsed, function(p) {
    data.frame(
      cited_id     = as.character(p$cited_id %||% NA),
      context_type = as.character(p$context_type %||% NA),
      snippet      = as.character(p$snippet %||% NA),
      explanation  = as.character(p$explanation %||% NA),
      stringsAsFactors = FALSE
    )
  }))
}
