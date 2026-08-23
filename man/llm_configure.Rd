\name{llm_configure}
\alias{llm_configure}
\title{Configure LLM provider for biblioIntegrator}
\usage{
llm_configure(
  provider = "ollama",
  api_key = NULL,
  model = NULL,
  base_url = NULL,
  temperature = 0.3,
  max_tokens = 4096L
)
}
\arguments{
\item{provider}{Character. Provider name: "ollama", "gemini", "openai",
"anthropic", or "huggingface".}

\item{api_key}{Character. API key. If NULL, reads from environment variable.}

\item{model}{Character. Model name. If NULL, uses provider default.}

\item{base_url}{Character. Base URL for API (useful for Ollama or proxies).}

\item{temperature}{Numeric. Temperature for generation (0-1). Default: 0.3.}

\item{max_tokens}{Integer. Maximum tokens in response. Default: 4096.}
}
\value{
Invisibly returns the configuration list.
}
\description{
Sets the default LLM provider, API key, and model for the session.
}
\details{
Environment variables for API keys:
\itemize{
  \item Ollama: OLLAMA_BASE_URL (default: http://localhost:11434)
  \item Google Gemini: GOOGLE_API_KEY
  \item OpenAI: OPENAI_API_KEY
  \item Anthropic: ANTHROPIC_API_KEY
  \item Hugging Face: HF_API_KEY
}
}
\examples{
\dontrun{
llm_configure(provider = "ollama")
llm_configure(provider = "gemini", api_key = "AIza...")
}
}
