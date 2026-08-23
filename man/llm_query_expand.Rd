\name{llm_query_expand}
\alias{llm_query_expand}
\title{Expand search query using LLM}
\usage{
llm_query_expand(query, database = "openalex", provider = NULL, model = NULL)
}
\arguments{
\item{query}{Character. Original search query.}

\item{database}{Character. Target database: "scopus", "wos",
"openalex", "pubmed", or "generic".}

\item{provider}{Character. LLM provider override.}

\item{model}{Character. Model override.}
}
\value{
A list with: expanded_query, added_terms, explanation.
}
\description{
Uses an LLM to expand a search query with synonyms, related terms,
and Boolean operators optimized for a specific database.
}
\examples{
\dontrun{
llm_configure(provider = "ollama")
result <- llm_query_expand("soil carbon sequestration",
                           database = "openalex")
cat(result$expanded_query)
}
}
