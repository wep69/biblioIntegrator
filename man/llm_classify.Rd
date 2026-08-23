\name{llm_classify}
\alias{llm_classify}
\title{Classify works into thematic categories using LLM}
\usage{
llm_classify(x, categories = NULL, provider = NULL, model = NULL)
}
\arguments{
\item{x}{A \code{biblio_project}.}

\item{categories}{Character vector. Categories to use. If NULL,
the LLM will suggest categories.}

\item{provider}{Character. LLM provider override.}

\item{model}{Character. Model override.}
}
\value{
A data frame with columns: work_id, title, primary,
  secondary, confidence, reason.
}
\description{
Assigns each work in the corpus to one or more user-defined
(or LLM-suggested) categories.
}
\examples{
\dontrun{
llm_configure(provider = "ollama")
x <- as_biblio_project(example_biblio())
classified <- llm_classify(x, categories = c("Agronomy", "Ecology"))
print(classified)
}
}
