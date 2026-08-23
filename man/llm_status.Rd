\name{llm_status}
\alias{llm_status}
\title{Check if LLM is configured and available}
\usage{
llm_status(provider = NULL, verbose = TRUE)
}
\arguments{
\item{provider}{Character. Provider to check. If NULL, uses current config.}

\item{verbose}{Logical. Print diagnostic messages. Default: TRUE.}
}
\value{
Logical. TRUE if LLM is available.
}
\description{
Checks whether the LLM provider is configured and accessible.
}
\examples{
\dontrun{
llm_status()
llm_status(provider = "ollama")
}
}
