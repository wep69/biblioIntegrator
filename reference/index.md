# Package index

## Core: Project & Health

Create, inspect and audit bibliographic projects.

- [`as_biblio_project()`](https://wep69.github.io/biblioIntegrator/reference/as_biblio_project.md)
  : Construct a bibliometric project
- [`biblio_health()`](https://wep69.github.io/biblioIntegrator/reference/biblio_health.md)
  : Diagnose corpus quality
- [`audit_biblio()`](https://wep69.github.io/biblioIntegrator/reference/audit_biblio.md)
  : Inspect the provenance log
- [`example_biblio()`](https://wep69.github.io/biblioIntegrator/reference/example_biblio.md)
  : Example bibliographic corpus
- [`biblio_import()`](https://wep69.github.io/biblioIntegrator/reference/biblio_import.md)
  : Import a bibliographic file

## Descriptive Analysis

Describe, compute metrics and export bibliometric data.

- [`describe_biblio()`](https://wep69.github.io/biblioIntegrator/reference/describe_biblio.md)
  : Descriptive bibliometric summary
- [`biblio_metrics()`](https://wep69.github.io/biblioIntegrator/reference/biblio_metrics.md)
  : Author-level bibliometric metrics
- [`term_frequency()`](https://wep69.github.io/biblioIntegrator/reference/term_frequency.md)
  : Term frequency from titles or abstracts
- [`tfidf_terms()`](https://wep69.github.io/biblioIntegrator/reference/tfidf_terms.md)
  : TF-IDF terms by grouping stratum
- [`trend_topics()`](https://wep69.github.io/biblioIntegrator/reference/trend_topics.md)
  : Topic trajectories by year
- [`export_biblio()`](https://wep69.github.io/biblioIntegrator/reference/export_biblio.md)
  : Export harmonized bibliographic tables
- [`export_vosviewer()`](https://wep69.github.io/biblioIntegrator/reference/export_vosviewer.md)
  : Export a network for VOSviewer
- [`to_bibliometrix()`](https://wep69.github.io/biblioIntegrator/reference/to_bibliometrix.md)
  : Convert to bibliometrix field-tag data

## Temporal & Citation

Growth, velocity, trajectory, RPYS and disruption.

- [`temporal_growth()`](https://wep69.github.io/biblioIntegrator/reference/temporal_growth.md)
  : Annual bibliometric growth
- [`citation_velocity()`](https://wep69.github.io/biblioIntegrator/reference/citation_velocity.md)
  : Citation velocity
- [`citation_trajectory()`](https://wep69.github.io/biblioIntegrator/reference/citation_trajectory.md)
  : Citation trajectory
- [`rpys()`](https://wep69.github.io/biblioIntegrator/reference/rpys.md)
  : Reference publication year spectroscopy
- [`normalized_citations()`](https://wep69.github.io/biblioIntegrator/reference/normalized_citations.md)
  : Field/year normalized citations
- [`disruption_index()`](https://wep69.github.io/biblioIntegrator/reference/disruption_index.md)
  : Disruption index from citation relations

## Comparative Inference

Group formation, comparison and sensitivity.

- [`form_groups()`](https://wep69.github.io/biblioIntegrator/reference/form_groups.md)
  : Define bibliometric groups
- [`compare_groups()`](https://wep69.github.io/biblioIntegrator/reference/compare_groups.md)
  : Compare user-defined bibliometric groups
- [`compare_sources()`](https://wep69.github.io/biblioIntegrator/reference/compare_sources.md)
  : Compare coverage across bibliographic sources
- [`group_ca()`](https://wep69.github.io/biblioIntegrator/reference/group_ca.md)
  : Correspondence analysis of group-entity associations
- [`group_mca()`](https://wep69.github.io/biblioIntegrator/reference/group_mca.md)
  : Multiple correspondence analysis of group and entity presence
- [`association_residuals()`](https://wep69.github.io/biblioIntegrator/reference/association_residuals.md)
  : Extract standardized association residuals
- [`sensitivity_analysis()`](https://wep69.github.io/biblioIntegrator/reference/sensitivity_analysis.md)
  : Sensitivity analysis for entity-frequency thresholds
- [`validate_biblium()`](https://wep69.github.io/biblioIntegrator/reference/validate_biblium.md)
  : Cross-validate native and Biblium group inference
- [`biblium_compare_groups()`](https://wep69.github.io/biblioIntegrator/reference/biblium_compare_groups.md)
  : Compare bibliometric groups with Biblium 2.16

## Networks

Build, analyse and store bibliographic networks.

- [`bibliographic_network()`](https://wep69.github.io/biblioIntegrator/reference/bibliographic_network.md)
  : Build a bibliographic network
- [`network_centrality()`](https://wep69.github.io/biblioIntegrator/reference/network_centrality.md)
  : Network centrality table
- [`network_communities()`](https://wep69.github.io/biblioIntegrator/reference/network_communities.md)
  : Detect network communities
- [`network_stability()`](https://wep69.github.io/biblioIntegrator/reference/network_stability.md)
  : Bootstrap/subsampling stability of node centrality

## Storage & Query

Persist and query with Arrow and DuckDB.

- [`biblio_store()`](https://wep69.github.io/biblioIntegrator/reference/biblio_store.md)
  : Store a bibliometric project using Arrow or DuckDB
- [`biblio_load()`](https://wep69.github.io/biblioIntegrator/reference/biblio_load.md)
  : Load a stored bibliometric project
- [`biblio_query()`](https://wep69.github.io/biblioIntegrator/reference/biblio_query.md)
  : Query a DuckDB bibliometric store

## Online APIs

Fetch from OpenAlex and OpenCitations.

- [`fetch_openalex()`](https://wep69.github.io/biblioIntegrator/reference/fetch_openalex.md)
  : Fetch works from OpenAlex
- [`fetch_opencitations()`](https://wep69.github.io/biblioIntegrator/reference/fetch_opencitations.md)
  : Fetch OpenCitations Index relations

## Python & Biblium

Optional Python backend and Biblium bridge.

- [`enable_python_backend()`](https://wep69.github.io/biblioIntegrator/reference/enable_python_backend.md)
  : Enable an existing Python backend
- [`python_backend_status()`](https://wep69.github.io/biblioIntegrator/reference/python_backend_status.md)
  : Backward-compatible Python backend status
- [`biblium_backend_status()`](https://wep69.github.io/biblioIntegrator/reference/biblium_backend_status.md)
  : Status of the optional Biblium Python backend
- [`backend_status()`](https://wep69.github.io/biblioIntegrator/reference/backend_status.md)
  : Optional backend status
- [`install_biblium_backend()`](https://wep69.github.io/biblioIntegrator/reference/install_biblium_backend.md)
  : Install an isolated Biblium backend
- [`to_biblium()`](https://wep69.github.io/biblioIntegrator/reference/to_biblium.md)
  : Create a Biblium-ready data frame

## Internal

Internal methods (not typically called directly).

- [`print(`*`<biblio_group_comparison>`*`)`](https://wep69.github.io/biblioIntegrator/reference/print.biblio_group_comparison.md)
  : Print a group comparison
- [`print(`*`<biblio_project>`*`)`](https://wep69.github.io/biblioIntegrator/reference/print.biblio_project.md)
  : Print a bibliometric project

## Workflow & Plans

Analysis plans, reports and Shiny app.

- [`form_plan()`](https://wep69.github.io/biblioIntegrator/reference/form_plan.md)
  : Create an analysis plan
- [`validate_plan()`](https://wep69.github.io/biblioIntegrator/reference/validate_plan.md)
  : Validate an analysis plan
- [`run_plan()`](https://wep69.github.io/biblioIntegrator/reference/run_plan.md)
  : Execute an integrated bibliometric plan
- [`biblio_report()`](https://wep69.github.io/biblioIntegrator/reference/biblio_report.md)
  : Generate an automated bibliometric report
- [`biblio_app()`](https://wep69.github.io/biblioIntegrator/reference/biblio_app.md)
  : Interactive bibliometric workbench

## Deduplication

Identify and remove duplicate records.

- [`deduplicate_biblio()`](https://wep69.github.io/biblioIntegrator/reference/deduplicate_biblio.md)
  : Deduplicate bibliographic records

## LLM Integration

Optional LLM-powered semantic analysis.

- [`llm_configure()`](https://wep69.github.io/biblioIntegrator/reference/llm_configure.md)
  : Configure LLM provider for biblioIntegrator
- [`llm_get_config()`](https://wep69.github.io/biblioIntegrator/reference/llm_get_config.md)
  : Get current LLM configuration
- [`llm_status()`](https://wep69.github.io/biblioIntegrator/reference/llm_status.md)
  : Check if LLM is configured and available
- [`semantic_search()`](https://wep69.github.io/biblioIntegrator/reference/semantic_search.md)
  : Semantic search in bibliographic corpus
- [`llm_topic_discovery()`](https://wep69.github.io/biblioIntegrator/reference/llm_topic_discovery.md)
  : Discover research topics using LLM
- [`llm_summarize()`](https://wep69.github.io/biblioIntegrator/reference/llm_summarize.md)
  : Summarize corpus using LLM
- [`llm_gap_analysis()`](https://wep69.github.io/biblioIntegrator/reference/llm_gap_analysis.md)
  : Identify research gaps using LLM
- [`llm_query_expand()`](https://wep69.github.io/biblioIntegrator/reference/llm_query_expand.md)
  : Expand search query using LLM
- [`llm_classify()`](https://wep69.github.io/biblioIntegrator/reference/llm_classify.md)
  : Classify works into thematic categories using LLM
- [`llm_citation_context()`](https://wep69.github.io/biblioIntegrator/reference/llm_citation_context.md)
  : Analyze citation context using LLM
