\name{llm_citation_context}
\alias{llm_citation_context}
\title{Analyze citation context using LLM}
\usage{
llm_citation_context(x, text = NULL, provider = NULL, model = NULL)
}
\arguments{
\item{x}{A \code{biblio_project}.}

\item{text}{Character. Text containing citations to analyze.
If NULL, uses abstracts from the corpus.}

\item{provider}{Character. LLM provider override.}

\item{model}{Character. Model override.}
}
\value{
A data frame with columns: cited_id, context_type,
  snippet, explanation.
}
\description{
Classifies the context in which works are cited (support, contrast,
method, background, extension).
}
\examples{
\dontrun{
llm_configure(provider = "ollama")
x <- as_biblio_project(example_biblio())
contexts <- llm_citation_context(x)
print(contexts)
}
}
