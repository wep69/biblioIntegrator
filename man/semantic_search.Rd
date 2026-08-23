\name{semantic_search}
\alias{semantic_search}
\title{Semantic search in bibliographic corpus}
\usage{
semantic_search(x, query, n = 10, provider = NULL, model = NULL, api_key = NULL)
}
\arguments{
\item{x}{A \code{biblio_project}.}

\item{query}{Character. Natural language search query.}

\item{n}{Integer. Maximum number of results. Default: 10.}

\item{provider}{Character. LLM provider override.}

\item{model}{Character. Model override.}

\item{api_key}{Character. API key override.}
}
\value{
A data frame with columns: work_id, title, score, reason.
}
\description{
Uses an LLM to find works relevant to a natural language query,
going beyond keyword matching to understand meaning and context.
}
\examples{
\dontrun{
llm_configure(provider = "ollama")
x <- as_biblio_project(example_biblio())
results <- semantic_search(x, "sustainable agriculture")
head(results)
}
}
