\name{llm_topic_discovery}
\alias{llm_topic_discovery}
\title{Discover research topics using LLM}
\usage{
llm_topic_discovery(x, n_topics = NULL, provider = NULL, model = NULL)
}
\arguments{
\item{x}{A \code{biblio_project}.}

\item{n_topics}{Integer or NULL. Suggested number of topics. NULL = auto.}

\item{provider}{Character. LLM provider override.}

\item{model}{Character. Model override.}
}
\value{
A list with: topics (data frame), raw_response.
}
\description{
Uses an LLM to identify distinct research themes in the corpus
without requiring a predefined number of topics.
}
\examples{
\dontrun{
llm_configure(provider = "ollama")
x <- as_biblio_project(example_biblio())
topics <- llm_topic_discovery(x, n_topics = 3)
print(topics$topics)
}
}
