\name{llm_summarize}
\alias{llm_summarize}
\title{Summarize corpus using LLM}
\usage{
llm_summarize(
  x,
  work_ids = NULL,
  style = "executive",
  provider = NULL,
  model = NULL
)
}
\arguments{
\item{x}{A \code{biblio_project}.}

\item{work_ids}{Character vector. Specific work IDs to summarize.}

\item{style}{Character. Summary style: "executive", "methods", "gaps", or "comprehensive".}

\item{provider}{Character. LLM provider override.}

\item{model}{Character. Model override.}
}
\value{
Character. The generated summary text.
}
\description{
Generates an intelligent summary of the bibliographic corpus,
synthesizing across works rather than listing them.
}
\examples{
\dontrun{
llm_configure(provider = "ollama")
x <- as_biblio_project(example_biblio())
summary <- llm_summarize(x, style = "executive")
cat(summary)
}
}
