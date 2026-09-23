# biblioIntegrator 0.4.0 (in development)

* New Biblium engines (optional Python backend, `biblium >= 2.16`):
  - `biblium_diversity()`: Shannon, Simpson and Gini indices over authors,
    keywords or sources, overall, per year or per group.
  - `biblium_representativeness()`: corpus year distribution vs the global
    OpenAlex benchmark in percentage points, with on-disk reference cache.
  - `biblium_main_path()`: SPC/SPLC/SPNP main paths over the citation network.
  - `biblium_compare_means()`: automatic test selection (t/Welch/Mann-Whitney,
    ANOVA/Welch-ANOVA/Kruskal-Wallis with post-hoc), assumption checks and
    effect sizes.
  - All Python calls share `.bi_bridge_call()`, which re-emits Python stderr
    as R warnings; `to_biblium()` gains the `Source` column.
* Unified plan: `form_plan()` accepts the `diversity`, `representation`,
  `mainpath` and `means` blocks plus a `strict` switch (skip unavailable
  backends with a warning instead of stopping); `biblio_report()` mirrors an
  executed `biblio_run`; `backend_status()` also reports `biblium` and `llm`.
* New vignette `v11-biblium-engines.Rmd`.
* Wave 2: `biblium_crosstab()` (chi-squared/Fisher/effects),
  `biblium_correlate()` (Pearson/Spearman/Kendall with p-values),
  `biblium_citation_patterns()` (estimated offline or live OpenAlex histories),
  native `concept_ngrams()`/`concept_cooccurrence()`/`reference_diversity()`
  (Rao-Stirling audited against Biblium), `validate_disruption()` (native x
  Biblium CD agreement), plan blocks `crosstab`/`patterns`/`concepts`.
* Fixed `disruption_index()` excluding the focal work itself from N_k (B16).
* Wave 4 (all native R): `biblio_import_pubmed()` (NCBI E-utilities, cached);
  `deduplicate_biblio(method="fuzzy")` (Jaro-Winkler within year, auditable log);
  `biblio_plot_annual()/terms()/sources()/citations()` (base graphics);
  `biblio_config()` registry with master `biblioIntegrator.cache` switch;
  COBISS documented as wontfix.
* Wave 3: `install_biblium_backend(extras=)` for Biblium extras;
  `biblium_sdg()` (Scopus-query SDG flags); `biblium_classify_groups()`
  (TF-IDF + scikit-learn cross-validation per group); `enrich_countries()` +
  `biblium_geo()` (OpenAlex country enrichment, cached); `biblium_topics()`
  (LDA/NMF tier-2, outside the default plan blocks).

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
