# LLM Backend Abstraction Layer for biblioIntegrator
# Provides a unified interface to multiple LLM providers
# Uses ellmer when available, falls back to httr2

# --- Configuration ---

#' Configure LLM provider for biblioIntegrator
#'
#' Sets the default LLM provider, API key, and model for the session.
#' Configuration can also be set via environment variables.
#'
#' @param provider Character. Provider name: "ollama", "gemini", "openai",
#'   "anthropic", or "huggingface".
#' @param api_key Character. API key. If NULL, reads from environment variable
#'   (e.g., OPENAI_API_KEY, GOOGLE_API_KEY, ANTHROPIC_API_KEY).
#' @param model Character. Model name. If NULL, uses provider default.
#' @param base_url Character. Base URL for API (useful for Ollama or proxies).
#' @param temperature Numeric. Temperature for generation (0-1). Default: 0.3.
#' @param max_tokens Integer. Maximum tokens in response. Default: 4096.
#'
#' @details
#' Environment variables for API keys:
#' \itemize{
#'   \item Ollama: OLLAMA_BASE_URL (default: http://localhost:11434)
#'   \item Google Gemini: GOOGLE_API_KEY
#'   \item OpenAI: OPENAI_API_KEY
#'   \item Anthropic: ANTHROPIC_API_KEY
#'   \item Hugging Face: HF_API_KEY
#' }
#'
#' @return Invisibly returns the configuration list.
#' @export
#' @examples
#' \dontrun{
#' # Use local Ollama (no API key needed)
#' llm_configure(provider = "ollama")
#'
#' # Use Google Gemini
#' llm_configure(provider = "gemini", api_key = "AIza...")
#'
#' # Use OpenAI
#' llm_configure(provider = "openai", api_key = "sk-...")
#' }
llm_configure <- function(provider = "ollama", api_key = NULL,
                          model = NULL, base_url = NULL,
                          temperature = 0.3, max_tokens = 4096L) {
  provider <- match.arg(provider, c("ollama", "gemini", "openai",
                                     "anthropic", "huggingface"))

  # Resolve API key from environment if not provided
  if (is.null(api_key)) {
    api_key <- switch(provider,
      "ollama"        = Sys.getenv("OLLAMA_API_KEY", ""),
      "gemini"        = Sys.getenv("GOOGLE_API_KEY", ""),
      "openai"        = Sys.getenv("OPENAI_API_KEY", ""),
      "anthropic"     = Sys.getenv("ANTHROPIC_API_KEY", ""),
      "huggingface"   = Sys.getenv("HF_API_KEY", "")
    )
  }

  # Resolve base URL
  if (is.null(base_url)) {
    base_url <- switch(provider,
      "ollama"        = Sys.getenv("OLLAMA_BASE_URL", "http://localhost:11434"),
      "gemini"        = "https://generativelanguage.googleapis.com/v1beta",
      "openai"        = "https://api.openai.com/v1",
      "anthropic"     = "https://api.anthropic.com",
      "huggingface"   = "https://api-inference.huggingface.co"
    )
  }

  # Resolve default model
  if (is.null(model)) {
    model <- switch(provider,
      "ollama"        = "llama3.1:8b",
      "gemini"        = "gemini-2.0-flash",
      "openai"        = "gpt-4o-mini",
      "anthropic"     = "claude-3-5-sonnet-latest",
      "huggingface"   = "mistralai/Mistral-7B-Instruct-v0.3"
    )
  }

  config <- list(
    provider    = provider,
    api_key     = api_key,
    model       = model,
    base_url    = base_url,
    temperature = temperature,
    max_tokens  = as.integer(max_tokens)
  )

  options(biblioIntegrator.llm = config)
  invisible(config)
}

#' Get current LLM configuration
#'
#' @return List with current LLM configuration, or NULL if not configured.
#' @export
#' @examples
#' llm_get_config()
llm_get_config <- function() {
  getOption("biblioIntegrator.llm", NULL)
}

#' Check if LLM is configured and available
#'
#' @param provider Character. Provider to check. If NULL, uses current config.
#' @param verbose Logical. Print diagnostic messages. Default: TRUE.
#'
#' @return Logical. TRUE if LLM is available.
#' @export
#' @examples
#' \dontrun{
#' llm_status()
#' llm_status(provider = "ollama")
#' }
llm_status <- function(provider = NULL, verbose = TRUE) {
  config <- llm_get_config()

  if (is.null(provider)) {
    if (is.null(config)) {
      if (verbose) message("LLM not configured. Run llm_configure() first.")
      return(invisible(FALSE))
    }
    provider <- config$provider
  }

  # Check if ellmer is available
  has_ellmer <- requireNamespace("ellmer", quietly = TRUE)

  # Check provider-specific availability
  available <- switch(provider,
    "ollama" = {
      url <- config$base_url %||% "http://localhost:11434"
      tryCatch({
        resp <- httr2::request(paste0(url, "/api/tags")) |>
          httr2::req_timeout(5) |>
          httr2::req_perform()
        httr2::resp_status(resp) == 200
      }, error = function(e) FALSE)
    },
    "gemini" = {
      nzchar(config$api_key %||% Sys.getenv("GOOGLE_API_KEY", ""))
    },
    "openai" = {
      nzchar(config$api_key %||% Sys.getenv("OPENAI_API_KEY", ""))
    },
    "anthropic" = {
      nzchar(config$api_key %||% Sys.getenv("ANTHROPIC_API_KEY", ""))
    },
    "huggingface" = {
      nzchar(config$api_key %||% Sys.getenv("HF_API_KEY", ""))
    },
    FALSE
  )

  if (verbose) {
    cat("LLM Status:\n")
    cat(sprintf("  Provider: %s\n", provider))
    cat(sprintf("  Model: %s\n", config$model %||% "not set"))
    cat(sprintf("  ellmer package: %s\n", ifelse(has_ellmer, "available", "not installed")))
    cat(sprintf("  Provider available: %s\n", ifelse(available, "yes", "no")))
    if (provider == "ollama" && !available) {
      cat("  Tip: Start Ollama with 'ollama serve' in a terminal\n")
    }
  }

  invisible(available && (has_ellmer || provider %in% c("ollama", "openai")))
}

# --- Internal Chat Function ---

#' Send a message to LLM and get response
#'
#' Internal function that abstracts the LLM API call.
#'
#' @param messages List of message objects with role and content.
#' @param provider Character. Provider override.
#' @param model Character. Model override.
#' @param temperature Numeric. Temperature override.
#' @param max_tokens Integer. Max tokens override.
#' @param json_mode Logical. Request JSON output. Default: FALSE.
#'
#' @return Character. LLM response text.
#' @keywords internal
.llm_chat <- function(messages, provider = NULL, model = NULL,
                      temperature = NULL, max_tokens = NULL,
                      json_mode = FALSE) {
  config <- llm_get_config()

  if (is.null(config)) {
    stop("LLM not configured. Run llm_configure() first.", call. = FALSE)
  }

  provider    <- provider    %||% config$provider
  model       <- model       %||% config$model
  temperature <- temperature %||% config$temperature
  max_tokens  <- max_tokens  %||% config$max_tokens

  # Try ellmer first, fall back to httr2
  if (requireNamespace("ellmer", quietly = TRUE)) {
    .llm_chat_ellmer(messages, provider, model, config,
                     temperature, max_tokens, json_mode)
  } else {
    .llm_chat_httr2(messages, provider, model, config,
                    temperature, max_tokens, json_mode)
  }
}

.llm_chat_ellmer <- function(messages, provider, model, config,
                             temperature, max_tokens, json_mode) {
  chat <- switch(provider,
    "ollama" = ellmer::chat_ollama(
      model    = model,
      base_url = config$base_url,
      seed     = 42
    ),
    "gemini" = ellmer::chat_google_gemini(
      model   = model,
      api_key = config$api_key
    ),
    "openai" = ellmer::chat_openai(
      model   = model,
      api_key = config$api_key
    ),
    "anthropic" = ellmer::chat_anthropic(
      model   = model,
      api_key = config$api_key
    ),
    "huggingface" = ellmer::chat_huggingface(
      model   = model,
      api_key = config$api_key
    ),
    stop("Unsupported provider: ", provider, call. = FALSE)
  )

  # Set system message if present
  system_msg <- Filter(function(m) m$role == "system", messages)
  if (length(system_msg) > 0) {
    chat$set_system_prompt(system_msg[[1]]$content)
  }

  # Get user message (last non-system message)
  user_msgs <- Filter(function(m) m$role != "system", messages)
  if (length(user_msgs) == 0) {
    stop("No user message provided.", call. = FALSE)
  }

  response <- chat$chat(user_msgs[[length(user_msgs)]]$content)
  return(response)
}

.llm_chat_httr2 <- function(messages, provider, model, config,
                            temperature, max_tokens, json_mode) {
  # Build request based on provider
  req <- switch(provider,
    "ollama" = {
      body <- list(
        model    = model,
        messages = messages,
        stream   = FALSE,
        options  = list(
          temperature = temperature,
          num_predict = max_tokens
        )
      )
      if (json_mode) body$format <- "json"

      httr2::request(paste0(config$base_url, "/api/chat")) |>
        httr2::req_body_json(body)
    },
    "openai" = {
      body <- list(
        model       = model,
        messages    = messages,
        temperature = temperature,
        max_tokens  = max_tokens
      )
      if (json_mode) body$response_format <- list(type = "json_object")

      httr2::request(paste0(config$base_url, "/chat/completions")) |>
        httr2::req_headers(Authorization = paste("Bearer", config$api_key)) |>
        httr2::req_body_json(body)
    },
    "gemini" = {
      # Convert messages to Gemini format
      contents <- lapply(Filter(function(m) m$role != "system", messages), function(m) {
        list(role = ifelse(m$role == "user", "user", "model"),
             parts = list(list(text = m$content)))
      })

      body <- list(
        contents = contents,
        generationConfig = list(
          temperature     = temperature,
          maxOutputTokens = max_tokens
        )
      )

      system_msg <- Filter(function(m) m$role == "system", messages)
      if (length(system_msg) > 0) {
        body$systemInstruction <- list(parts = list(list(text = system_msg[[1]]$content)))
      }

      url <- paste0(config$base_url, "/models/", model, ":generateContent?key=", config$api_key)
      httr2::request(url) |>
        httr2::req_body_json(body)
    },
    "anthropic" = {
      system_msg <- Filter(function(m) m$role == "system", messages)
      user_msgs <- Filter(function(m) m$role != "system", messages)

      body <- list(
        model       = model,
        max_tokens  = max_tokens,
        temperature = temperature,
        messages    = lapply(user_msgs, function(m) {
          list(role = m$role, content = m$content)
        })
      )

      if (length(system_msg) > 0) {
        body$system <- system_msg[[1]]$content
      }

      httr2::request(paste0(config$base_url, "/v1/messages")) |>
        httr2::req_headers(
          `x-api-key`         = config$api_key,
          `anthropic-version` = "2023-06-01",
          `content-type`      = "application/json"
        ) |>
        httr2::req_body_json(body)
    },
    stop("Unsupported provider for httr2 fallback: ", provider, call. = FALSE)
  )

  # Perform request with retry
  resp <- req |>
    httr2::req_retry(max_tries = 3, backoff = ~2) |>
    httr2::req_timeout(120) |>
    httr2::req_perform()

  # Parse response
  parsed <- httr2::resp_body_json(resp)

  switch(provider,
    "ollama"    = parsed$message$content,
    "openai"    = parsed$choices[[1]]$message$content,
    "gemini"    = parsed$candidates[[1]]$content$parts[[1]]$text,
    "anthropic" = parsed$content[[1]]$text,
    stop("Cannot parse response from: ", provider, call. = FALSE)
  )
}

# --- Utility ---

`%||%` <- function(x, y) if (is.null(x)) y else x
