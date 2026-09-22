# biblioIntegrator 0.3.0

* Fixed issues reported by the audited tutorial (`tutorial/RELATORIO-AO-AUTOR.md`):
  - LLM backend no longer passes `seed` to `ellmer::chat_ollama()`, which
    rejected the argument and broke every LLM function when `ellmer` was
    installed.
  - `fetch_opencitations()` normalizes identifiers to the `doi:` PID form
    required by the OpenCitations v2 API (previously returned HTTP 400).
  - `biblio_store(overwrite = FALSE)` now refuses to write over an existing
    path instead of silently replacing it.
  - `disruption_index()` validates `citing_id`/`cited_id` columns instead of
    silently returning `NA` counts.
  - Stochastic functions (`compare_groups()`, `network_stability()`,
    `sensitivity_analysis()`, `run_plan()`) restore the caller's
    `.Random.seed` after honoring the `seed` argument.
  - `run_plan()`/`validate_plan()` error message mentions the expected
    argument order.
  - `tfidf_terms(group =)` accepts any column of `x$works` as stratum.
  - `biblium_backend_status()` caches its result per session (invalidated by
    `install_biblium_backend()` and `enable_python_backend()`).
* Added optional LLM integration for semantic bibliometric analysis.
* New functions: semantic_search(), llm_topic_discovery(), llm_summarize(),
  llm_gap_analysis(), llm_query_expand(), llm_classify(), llm_citation_context().
* Supported LLM providers: Ollama (local, free), Google Gemini (free tier),
  OpenAI, Anthropic, Hugging Face.
* New llm_configure() for provider setup, llm_status() for diagnostics.
* Added ellmer as optional dependency for unified LLM API access.
* Expanded all 10 vignettes to comprehensive tutorials (17,657 lines total).
* Added v10-llm-integration.Rmd vignette for LLM-powered analysis.

# biblioIntegrator 0.2.0

* Added executable Biblium backend discovery and group-analysis bridge.
* Added biblionetwork engine for large bibliographic networks.
* Added Arrow/DuckDB storage and query backends.
* Expanded automated report and interactive Shiny application.
* Added release-grade validation workflow for immutable source tarballs.
