\name{llm_gap_analysis}
\alias{llm_gap_analysis}
\title{Identify research gaps using LLM}
\usage{
llm_gap_analysis(x, focus = "thematic", provider = NULL, model = NULL)
}
\arguments{
\item{x}{A \code{biblio_project}.}

\item{focus}{Character. Analysis focus: "thematic", "methodological",
"geographic", or "temporal".}

\item{provider}{Character. LLM provider override.}

\item{model}{Character. Model override.}
}
\value{
A data frame with columns: gap, evidence, impact, suggestion.
}
\description{
Analyzes the corpus to identify understudied areas, methodological
gaps, or geographic biases.
}
\examples{
\dontrun{
llm_configure(provider = "ollama")
x <- as_biblio_project(example_biblio())
gaps <- llm_gap_analysis(x, focus = "thematic")
print(gaps)
}
}
