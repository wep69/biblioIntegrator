ck_dir <- "D:/RLibrary"
if (dir.exists(ck_dir)) .libPaths(c(ck_dir, .libPaths()))
suppressPackageStartupMessages(library(biblioIntegrator))
ex <- sort(getNamespaceExports("biblioIntegrator"))
cat("total exportadas:", length(ex), "\n")
meu <- c("example_biblio","as_biblio_project","biblio_import","backend_status",
"biblio_health","deduplicate_biblio","audit_biblio",
"describe_biblio","biblio_metrics","normalized_citations",
"temporal_growth","citation_velocity","citation_trajectory","rpys","disruption_index",
"term_frequency","tfidf_terms","trend_topics",
"form_groups","compare_groups","association_residuals","group_ca","group_mca",
"sensitivity_analysis","compare_sources",
"bibliographic_network","network_centrality","network_communities","network_stability",
"export_vosviewer","biblio_store","biblio_load","biblio_query",
"fetch_openalex","fetch_opencitations",
"python_backend_status","biblium_backend_status","enable_python_backend",
"install_biblium_backend","to_biblium","biblium_compare_groups","validate_biblium",
"llm_configure","llm_get_config","llm_status","semantic_search","llm_topic_discovery",
"llm_summarize","llm_gap_analysis","llm_query_expand","llm_classify","llm_citation_context",
"form_plan","validate_plan","run_plan","biblio_report","biblio_app","export_biblio",
"to_bibliometrix")
cat("meu mapa:", length(meu), "\n")
cat("exportadas SEM modulo:", paste(setdiff(ex, meu), collapse = ", "), "\n")
cat("no mapa mas NAO exportadas:", paste(setdiff(meu, ex), collapse = ", "), "\n")
