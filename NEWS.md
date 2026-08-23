# biblioIntegrator 0.3.0

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
