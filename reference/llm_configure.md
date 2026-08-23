# Configure LLM provider for biblioIntegrator

Sets the default LLM provider, API key, and model for the session.

## Usage

``` r
llm_configure(
  provider = "ollama",
  api_key = NULL,
  model = NULL,
  base_url = NULL,
  temperature = 0.3,
  max_tokens = 4096L
)
```

## Arguments

- provider:

  Character. Provider name: "ollama", "gemini", "openai", "anthropic",
  or "huggingface".

- api_key:

  Character. API key. If NULL, reads from environment variable.

- model:

  Character. Model name. If NULL, uses provider default.

- base_url:

  Character. Base URL for API (useful for Ollama or proxies).

- temperature:

  Numeric. Temperature for generation (0-1). Default: 0.3.

- max_tokens:

  Integer. Maximum tokens in response. Default: 4096.

## Value

Invisibly returns the configuration list.

## Details

Environment variables for API keys:

- Ollama: OLLAMA_BASE_URL (default: http://localhost:11434)

- Google Gemini: GOOGLE_API_KEY

- OpenAI: OPENAI_API_KEY

- Anthropic: ANTHROPIC_API_KEY

- Hugging Face: HF_API_KEY

## Examples

``` r
if (FALSE) { # \dontrun{
llm_configure(provider = "ollama")
llm_configure(provider = "gemini", api_key = "AIza...")
} # }
```
