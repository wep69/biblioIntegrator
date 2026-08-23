# LLM Prompt Templates for biblioIntegrator
# Structured prompts for each LLM-powered function

#' @keywords internal
.prompt_system_bibliometric <- function() {
  "You are an expert bibliometric analyst assistant. You analyze academic
literature data and provide structured, evidence-based insights. Always
respond in the requested format. Be precise with numbers and cite specific
works when possible."
}

#' @keywords internal
.prompt_semantic_search <- function(query, works_text, n) {
  paste0(
    .prompt_system_bibliometric(), "\n\n",
    "TASK: Rank the following academic works by semantic relevance to this query:\n",
    "QUERY: \"", query, "\"\n\n",
    "WORKS:\n", works_text, "\n\n",
    "INSTRUCTIONS:\n",
    "1. Score each work from 0.0 (irrelevant) to 1.0 (highly relevant)\n",
    "2. Consider title, abstract, keywords, and methodology\n",
    "3. Return the top ", n, " most relevant works\n",
    "4. Provide a brief reason for each score\n\n",
    "OUTPUT FORMAT (JSON array):\n",
    '[{"work_id": "...", "title": "...", "score": 0.95, "reason": "..."}]'
  )
}

#' @keywords internal
.prompt_topic_discovery <- function(abstracts_text, n_topics) {
  n_str <- if (is.null(n_topics)) "the natural number of" else as.character(n_topics)
  paste0(
    .prompt_system_bibliometric(), "\n\n",
    "TASK: Identify ", n_str, " research topics from these academic abstracts.\n\n",
    "ABSTRACTS:\n", abstracts_text, "\n\n",
    "INSTRUCTIONS:\n",
    "1. Identify distinct research themes or topics\n",
    "2. For each topic, provide a descriptive name\n",
    "3. List 3-5 representative keywords\n",
    "4. List the work IDs that belong to each topic\n",
    "5. Provide a brief description of each topic\n\n",
    "OUTPUT FORMAT (JSON):\n",
    '{"topics": [{"name": "...", "description": "...", "keywords": ["..."], ',
    '"work_ids": ["..."], "size": 5}]}'
  )
}

#' @keywords internal
.prompt_summarize <- function(abstracts_text, style) {
  style_instructions <- switch(style,
    "executive" = paste(
      "Write an executive summary suitable for a research manager.",
      "Highlight key findings, trends, and practical implications.",
      "Length: 200-300 words."
    ),
    "methods" = paste(
      "Focus on methodological approaches used across the studies.",
      "Identify common methods, innovations, and gaps in methodology.",
      "Length: 200-300 words."
    ),
    "gaps" = paste(
      "Identify research gaps, contradictions, and under-explored areas.",
      "Suggest directions for future research.",
      "Length: 200-300 words."
    ),
    "comprehensive" = paste(
      "Provide a comprehensive synthesis covering:",
      "(1) main themes, (2) key findings, (3) methods used,",
      "(4) research gaps, (5) practical implications.",
      "Length: 400-500 words."
    ),
    paste("Summarize the following academic works.", style)
  )

  paste0(
    .prompt_system_bibliometric(), "\n\n",
    "TASK: Summarize these academic works.\n\n",
    "STYLE: ", style_instructions, "\n\n",
    "ABSTRACTS:\n", abstracts_text, "\n\n",
    "INSTRUCTIONS:\n",
    "1. Synthesize across works, don't just list them\n",
    "2. Identify patterns and themes\n",
    "3. Note contradictions or debates\n",
    "4. Use academic but accessible language\n",
    "5. Cite specific works by their work_id when making claims"
  )
}

#' @keywords internal
.prompt_gap_analysis <- function(corpus_summary, focus) {
  focus_instructions <- switch(focus,
    "thematic" = paste(
      "Identify thematic gaps: topics that are understudied,",
      "populations or contexts not covered, questions not asked."
    ),
    "methodological" = paste(
      "Identify methodological gaps: approaches not used,",
      "statistical methods not applied, data types not explored,",
      "experimental designs not attempted."
    ),
    "geographic" = paste(
      "Identify geographic gaps: regions not studied,",
      "institutional collaborations missing,",
      "country-level biases in the corpus."
    ),
    "temporal" = paste(
      "Identify temporal gaps: emerging topics not yet mature,",
      "declining areas, longitudinal studies needed."
    ),
    paste("Identify research gaps in the following dimension:", focus)
  )

  paste0(
    .prompt_system_bibliometric(), "\n\n",
    "TASK: Analyze this bibliometric corpus for research gaps.\n\n",
    "FOCUS: ", focus_instructions, "\n\n",
    "CORPUS SUMMARY:\n", corpus_summary, "\n\n",
    "INSTRUCTIONS:\n",
    "1. Identify 3-5 specific, actionable research gaps\n",
    "2. For each gap, provide evidence from the corpus\n",
    "3. Rate each gap's potential impact (high/medium/low)\n",
    "4. Suggest how each gap could be addressed\n\n",
    "OUTPUT FORMAT (JSON):\n",
    '{"gaps": [{"gap": "...", "evidence": "...", "impact": "high", ',
    '"suggestion": "..."}]}'
  )
}

#' @keywords internal
.prompt_query_expand <- function(query, database) {
  db_instructions <- switch(database,
    "scopus" = "Use Scopus field codes (TITLE-ABS-KEY, AUTHKEY, etc.)",
    "wos" = "Use Web of Science field tags (TS=, TI=, AU=, etc.)",
    "openalex" = "Use OpenAlex filter syntax or simple Boolean",
    "pubmed" = "Use MeSH terms and PubMed query syntax",
    "Use standard Boolean query syntax"
  )

  paste0(
    .prompt_system_bibliometric(), "\n\n",
    "TASK: Expand this search query for better recall in ", database, ".\n\n",
    "ORIGINAL QUERY: \"", query, "\"\n\n",
    "FORMAT: ", db_instructions, "\n\n",
    "INSTRUCTIONS:\n",
    "1. Add relevant synonyms and alternative terms\n",
    "2. Include related concepts and broader/narrower terms\n",
    "3. Consider abbreviations and variant spellings\n",
    "4. Use OR for synonyms, AND for required concepts\n",
    "5. Keep the query focused but comprehensive\n\n",
    "OUTPUT FORMAT (JSON):\n",
    '{"expanded_query": "...", "added_terms": ["..."], ',
    '"explanation": "..."}'
  )
}

#' @keywords internal
.prompt_classify <- function(works_text, categories) {
  cat_list <- paste(categories, collapse = ", ")
  paste0(
    .prompt_system_bibliometric(), "\n\n",
    "TASK: Classify each academic work into one or more categories.\n\n",
    "CATEGORIES: [", cat_list, "]\n\n",
    "WORKS:\n", works_text, "\n\n",
    "INSTRUCTIONS:\n",
    "1. Assign each work to one PRIMARY category\n",
    "2. Optionally assign secondary categories if relevant\n",
    "3. Provide a confidence score (0.0-1.0) for the primary assignment\n",
    "4. Briefly explain the reasoning\n\n",
    "OUTPUT FORMAT (JSON array):\n",
    '[{"work_id": "...", "primary": "Category1", "secondary": ["Category2"], ',
    '"confidence": 0.9, "reason": "..."}]'
  )
}

#' @keywords internal
.prompt_citation_context <- function(text_snippet, cited_works) {
  paste0(
    .prompt_system_bibliometric(), "\n\n",
    "TASK: Analyze the citation context in this academic text.\n\n",
    "TEXT:\n", text_snippet, "\n\n",
    "CITED WORKS:\n", cited_works, "\n\n",
    "INSTRUCTIONS:\n",
    "For each citation, classify the context as one of:\n",
    "- support: cited as supporting evidence\n",
    "- contrast: cited to disagree or show difference\n",
    "- method: cited for methodological approach\n",
    "- background: cited as general background\n",
    "- extension: cited as work being extended\n\n",
    "OUTPUT FORMAT (JSON array):\n",
    '[{"cited_id": "...", "context_type": "support", ',
    '"snippet": "...", "explanation": "..."}]'
  )
}
