\name{llm_get_config}
\alias{llm_get_config}
\title{Get current LLM configuration}
\usage{
llm_get_config()
}
\value{
List with current LLM configuration, or NULL if not configured.
}
\description{
Returns the current LLM provider configuration set by \code{\link{llm_configure}}.
}
\examples{
llm_get_config()
}
