# LLM-Powered Bibliometric Analysis

## Why This Vignette Exists

### Beyond Keyword Matching

Traditional bibliometric analysis has served the research community well
for decades. Keyword counting, citation analysis, co-authorship
networks, and h-index calculations remain indispensable tools. Yet these
approaches share a fundamental limitation: they operate on the
**surface** of the text — the words that authors chose, the references
they cited, the metadata that databases preserved.

What lies beneath the surface is often more interesting:

- **Semantic nuance**: Two abstracts may share no keywords yet address
  the same underlying research question from different disciplinary
  angles.
- **Implicit context**: A citation in the methods section carries a
  different meaning than one in the literature review, yet both count
  equally in traditional co-citation analysis.
- **Research gaps**: Gaps are defined not by what is absent from the
  keyword list but by what is present — or absent — from the conceptual
  landscape.
- **Thematic coherence**: A cluster of works may be thematically unified
  by ideas that no single keyword captures.

Large Language Models (LLMs) offer a fundamentally different lens.
Rather than counting tokens, they build distributed representations of
meaning — vector embeddings that capture semantic relationships between
texts. A single LLM call can read an abstract and produce a 768- or
1536-dimensional vector that encodes not just what words appear but what
the text *means*.

This capability opens entirely new analytical avenues for bibliometric
research:

1.  **Semantic search**: Find works that address the same concept even
    when they use different terminology.
2.  **Topic discovery**: Identify latent research themes without
    predefined keyword taxonomies.
3.  **Intelligent summarization**: Generate executive summaries,
    methodology critiques, or gap analyses from hundreds of abstracts in
    seconds.
4.  **Research gap analysis**: Detect under-explored intersections
    between themes, methods, and populations.
5.  **Query expansion**: Transform a narrow search string into a
    comprehensive boolean query for systematic reviews.
6.  **Thematic classification**: Assign works to categories —
    user-defined or emergent — with confidence scores.
7.  **Citation context analysis**: Determine whether a citation
    supports, contrasts, or merely acknowledges prior work.

### Accessibility Through Free Options

A common concern with LLM integration is cost. This vignette
demonstrates that **powerful LLM capabilities are available at zero
cost** through two primary channels:

- **Ollama** (local): Run Llama 3.1 (8B parameters), Mistral 7B, or
  other models directly on your machine with no API key, no internet
  requirement after download, and no usage limits. Ideal for
  development, testing, and sensitive data that should not leave your
  network.
- **Google Gemini** (free tier): Access the Gemini 2.0 Flash model with
  a generous free tier of 15 requests per minute — sufficient for most
  bibliometric workflows.

For researchers with institutional API budgets, paid providers (OpenAI,
Anthropic) offer higher-capability models at modest cost (typically
under \$1 for a complete bibliometric workflow of several hundred
works).

### Optional Dependency — Core Unchanged

The LLM features described in this vignette are **entirely optional**.
The core `biblioIntegrator` package continues to work without any LLM
provider configured. No new hard dependencies are introduced. The
`ellmer` package (Ollama, OpenAI, Anthropic, Hugging Face) and `httr2`
(Google Gemini) are suggested dependencies — they are loaded lazily only
when LLM functions are called.

If you never configure a provider, nothing changes in your existing
workflow.

## Learning Objectives

By the end of this vignette, you should be able to:

1.  **Configure** an LLM provider — local (Ollama) or remote (Gemini,
    OpenAI, Anthropic, Hugging Face) — using
    [`llm_configure()`](https://wep69.github.io/biblioIntegrator/reference/llm_configure.md).

2.  **Verify** provider availability and diagnose configuration issues
    using
    [`llm_status()`](https://wep69.github.io/biblioIntegrator/reference/llm_status.md)
    and
    [`llm_get_config()`](https://wep69.github.io/biblioIntegrator/reference/llm_get_config.md).

3.  **Perform semantic search** over your corpus using
    [`semantic_search()`](https://wep69.github.io/biblioIntegrator/reference/semantic_search.md)
    to find works by meaning rather than keywords.

4.  **Discover research topics** automatically using
    [`llm_topic_discovery()`](https://wep69.github.io/biblioIntegrator/reference/llm_topic_discovery.md)
    and interpret the resulting theme descriptions.

5.  **Generate intelligent summaries** of your corpus using
    [`llm_summarize()`](https://wep69.github.io/biblioIntegrator/reference/llm_summarize.md)
    in executive, methodology, gap, and comprehensive modes.

6.  **Identify research gaps** using
    [`llm_gap_analysis()`](https://wep69.github.io/biblioIntegrator/reference/llm_gap_analysis.md)
    across thematic, methodological, geographic, and temporal
    dimensions.

7.  **Expand search queries** for systematic reviews using
    [`llm_query_expand()`](https://wep69.github.io/biblioIntegrator/reference/llm_query_expand.md)
    with support for Scopus, Web of Science, PubMed, and generic
    formats.

8.  **Classify works** into user-defined or LLM-suggested categories
    using
    [`llm_classify()`](https://wep69.github.io/biblioIntegrator/reference/llm_classify.md)
    with confidence scores and multi-label support.

9.  **Analyze citation contexts** using
    [`llm_citation_context()`](https://wep69.github.io/biblioIntegrator/reference/llm_citation_context.md)
    to distinguish supporting, contrasting, methodological, and
    background citations.

10. **Estimate costs, manage rate limits, and apply best practices** for
    reliable, reproducible LLM-assisted bibliometric analysis.

## Prerequisites

### Required Packages

The LLM integration requires the base `biblioIntegrator` package:

``` r

library(biblioIntegrator)
```

Optional packages are loaded lazily and guarded with
[`requireNamespace()`](https://rdrr.io/r/base/ns-load.html):

| Package | Provider | Install |
|----|----|----|
| `ellmer` | Ollama, OpenAI, Anthropic, Hugging Face | `install.packages("ellmer")` |
| `httr2` | Google Gemini | `install.packages("httr2")` |

If neither is installed, LLM functions will return an informative error
message rather than crashing.

### A Working Corpus

All examples in this vignette assume you have a `biblio_project` object.
You can use the built-in example dataset for practice:

``` r

library(biblioIntegrator)
proj <- as_biblio_project(example_biblio())
proj
#> <biblio_project> 12 works; 7 authors; 32 work-keyword links
```

Or load your own project:

``` r

proj <- readRDS("my_project.rds")
```

### Hardware Recommendations for Local Models

If you plan to use Ollama (local inference), consider these hardware
guidelines:

| RAM | Model | Feasibility | Notes |
|----|----|----|----|
| 8 GB | llama3.1:8b (Q4) | Marginal | Possible with 4-bit quantization; may be slow |
| 16 GB | llama3.1:8b (Q8) | Good | Recommended minimum for comfortable use |
| 32 GB | llama3.1:8b (FP16) | Excellent | Full precision, faster inference |
| 24 GB VRAM | llama3.1:8b on GPU | Excellent | Best performance with GPU offloading |

For academic use on a standard laptop (16 GB RAM, no discrete GPU),
Ollama with `llama3.1:8b` at Q4 quantization is a practical starting
point.

## Provider Setup

### Overview of Supported Providers

The `biblioIntegrator` LLM integration supports five providers, each
with distinct trade-offs in cost, privacy, capability, and convenience:

| Provider | Model | Cost | API Key | Local | Best For |
|----|----|----|----|----|----|
| Ollama | llama3.1:8b | Free | No | Yes | Privacy, development, offline use |
| Google Gemini | gemini-2.0-flash | Free (15 req/min) | Yes | No | General-purpose, free tier |
| Hugging Face | Mistral-7B-Instruct | Free (1000 req/day) | Yes | No | Free remote inference |
| OpenAI | gpt-4o-mini | ~\$0.15/1M tokens | Yes | No | High quality, structured output |
| Anthropic | claude-3-5-sonnet | ~\$3/1M tokens | Yes | No | Complex reasoning, long context |

**Recommendation for new users**: Start with Ollama (free, local, no API
key) or Google Gemini (free tier, no installation beyond R). Graduate to
paid providers only if you need higher-quality outputs or faster
throughput.

### Provider 1: Ollama (Local, Free)

Ollama is the simplest way to get started because it requires no
internet connection after the initial model download and no API key.

#### Step 1: Install Ollama

Download and install Ollama from <https://ollama.com>:

- **Windows**: Run the installer.
- **macOS**: Run the `.dmg` installer.
- **Linux**: Run `curl -fsSL https://ollama.com/install.sh | sh`.

#### Step 2: Download a Model

Open a terminal and pull a model:

``` bash
# Download Llama 3.1 (8B parameters, ~4.7 GB)
ollama pull llama3.1:8b

# Alternatively, for smaller footprint (~2.0 GB)
ollama pull llama3.1:8b-q4_K_M
```

#### Step 3: Verify Ollama Is Running

``` bash
# Check that Ollama is listening
curl http://localhost:11434/api/tags
```

You should see a JSON response listing downloaded models.

#### Step 4: Configure in biblioIntegrator

``` r

library(biblioIntegrator)

# Configure Ollama as the provider
llm_configure(
  provider = "ollama",
  model = "llama3.1:8b",
  base_url = "http://localhost:11434"
)
```

#### Step 5: Verify Configuration

``` r

llm_status()
#> LLM Provider Status
#> ────────────────────────────────────
#> Provider:  ollama
#> Model:     llama3.1:8b
#> Base URL:  http://localhost:11434
#> Available: ✓ Yes
#> Response:  0.8s (warm)
```

#### Ollama Configuration Options

``` r

# Use a different model
llm_configure(
  provider = "ollama",
  model = "mistral:7b",           # Faster, smaller
  base_url = "http://localhost:11434",
  temperature = 0,                 # Deterministic output
  num_ctx = 4096                   # Context window
)

# GPU acceleration (if available)
llm_configure(
  provider = "ollama",
  model = "llama3.1:8b",
  base_url = "http://localhost:11434",
  options = list(num_gpu = 1)      # Use GPU
)
```

#### Troubleshooting Ollama

| Problem | Solution |
|----|----|
| “Connection refused” | Ensure Ollama is running: `ollama serve` |
| Slow responses | Use a smaller model (`mistral:7b`) or enable GPU |
| Out of memory | Use higher quantization (`q4_K_M`) or reduce `num_ctx` |
| Model not found | Check available models: `ollama list` |

### Provider 2: Google Gemini (Free Tier)

Google Gemini offers a generous free tier — 15 requests per minute with
the `gemini-2.0-flash` model — which is sufficient for most bibliometric
workflows.

#### Step 1: Get an API Key

1.  Visit <https://aistudio.google.com/app/apikey>
2.  Sign in with your Google account
3.  Click “Create API key”
4.  Copy the key (starts with `AIza...`)

#### Step 2: Configure in biblioIntegrator

``` r

llm_configure(
  provider = "gemini",
  model = "gemini-2.0-flash",
  api_key = "AIzaSy..."            # Your API key
)
```

Alternatively, set the key as an environment variable:

``` r

# In .Renviron or shell profile
GEMINI_API_KEY=AIzaSy...
```

``` r

# Then configure without the api_key argument
llm_configure(
  provider = "gemini",
  model = "gemini-2.0-flash"
)
```

#### Step 3: Verify

``` r

llm_status()
#> LLM Provider Status
#> ────────────────────────────────────
#> Provider:  gemini
#> Model:     gemini-2.0-flash
#> Available: ✓ Yes
#> Rate Limit: 15 requests/min
```

#### Gemini Rate Limit Management

The free tier allows 15 requests per minute. `biblioIntegrator` includes
automatic rate limiting:

``` r

# Rate limiting is automatic, but you can customize:
llm_configure(
  provider = "gemini",
  model = "gemini-2.0-flash",
  rate_limit = 10,                 # Stay under the 15/min cap
  retry_on_rate_limit = TRUE,      # Auto-retry after wait
  max_retries = 3
)
```

#### Gemini Models

| Model                 | Context   | Speed   | Cost (Free Tier) | Recommended For  |
|-----------------------|-----------|---------|------------------|------------------|
| gemini-2.0-flash      | 1M tokens | Fast    | Free (15/min)    | General-purpose  |
| gemini-1.5-pro        | 2M tokens | Slower  | Paid             | Complex analysis |
| gemini-2.0-flash-lite | 1M tokens | Fastest | Free (30/min)    | Bulk processing  |

### Provider 3: OpenAI (Paid)

#### Step 1: Get an API Key

1.  Visit <https://platform.openai.com/api-keys>
2.  Sign in or create an account
3.  Click “Create new secret key”
4.  Copy the key (starts with `sk-...`)
5.  Add billing information at
    <https://platform.openai.com/account/billing>

#### Step 2: Configure

``` r

llm_configure(
  provider = "openai",
  model = "gpt-4o-mini",           # Cost-effective (~$0.15/1M tokens)
  api_key = "sk-..."
)

# Or for highest quality
llm_configure(
  provider = "openai",
  model = "gpt-4o",                # More capable (~$5/1M tokens)
  api_key = "sk-..."
)
```

#### Step 3: Verify

``` r

llm_status()
#> LLM Provider Status
#> ────────────────────────────────────
#> Provider:  openai
#> Model:     gpt-4o-mini
#> Available: ✓ Yes
```

#### OpenAI Models for Bibliometrics

| Model        | Input Cost | Output Cost | Context | Best For                        |
|--------------|------------|-------------|---------|---------------------------------|
| gpt-4o-mini  | \$0.15/1M  | \$0.60/1M   | 128K    | Bulk processing, classification |
| gpt-4o       | \$2.50/1M  | \$10/1M     | 128K    | Complex synthesis, gap analysis |
| gpt-4.1-mini | \$0.40/1M  | \$1.60/1M   | 1M      | Long-context summarization      |

#### Cost Estimation for OpenAI

A typical bibliometric workflow on a 500-work corpus:

| Operation                     | Calls  | Tokens/Call | Est. Cost (gpt-4o-mini) |
|-------------------------------|--------|-------------|-------------------------|
| Semantic search (5 queries)   | 5      | 1,500       | \< \$0.01               |
| Topic discovery               | 1      | 5,000       | \< \$0.01               |
| Summarization (executive)     | 1      | 3,000       | \< \$0.01               |
| Gap analysis                  | 1      | 4,000       | \< \$0.01               |
| Query expansion (3 databases) | 3      | 1,000       | \< \$0.01               |
| Classification (all works)    | 10     | 2,000       | ~ \$0.01                |
| Citation context (100 refs)   | 5      | 2,000       | ~ \$0.01                |
| **Total**                     | **26** | —           | **~ \$0.05**            |

### Provider 4: Anthropic (Paid)

#### Step 1: Get an API Key

1.  Visit <https://console.anthropic.com/settings/keys>
2.  Sign in or create an account
3.  Click “Create Key”
4.  Copy the key (starts with `sk-ant-...`)

#### Step 2: Configure

``` r

llm_configure(
  provider = "anthropic",
  model = "claude-3-5-sonnet-20241022",
  api_key = "sk-ant-..."
)
```

#### Anthropic Models

| Model | Input Cost | Output Cost | Context | Best For |
|----|----|----|----|----|
| claude-3-5-sonnet | \$3/1M | \$15/1M | 200K | Complex reasoning, synthesis |
| claude-3-5-haiku | \$0.80/1M | \$4/1M | 200K | Fast bulk processing |

### Provider 5: Hugging Face (Free Tier)

#### Step 1: Get an API Key

1.  Visit <https://huggingface.co/settings/tokens>
2.  Sign in or create an account
3.  Click “New token”
4.  Select “Read” role
5.  Copy the token (starts with `hf_...`)

#### Step 2: Configure

``` r

llm_configure(
  provider = "huggingface",
  model = "mistralai/Mistral-7B-Instruct-v0.3",
  api_key = "hf_..."
)
```

#### Hugging Face Rate Limits

| Tier         | Requests/Day | Requests/Minute |
|--------------|--------------|-----------------|
| Free         | 1,000        | ~10             |
| Pro (\$9/mo) | Unlimited    | Higher          |

### Saving and Loading Configuration

Once configured, save your settings so they persist across sessions:

``` r

# Save current configuration
llm_configure(
  provider = "gemini",
  model = "gemini-2.0-flash",
  api_key = "AIzaSy...",
  save = TRUE                       # Persists to ~/.biblioIntegrator/llm_config.rds
)
```

``` r

# In a new session, the saved configuration is loaded automatically
# on first LLM function call. You can also load it explicitly:
llm_configure(load_saved = TRUE)

# Verify
llm_get_config()
#> $provider
#> [1] "gemini"
#> $model
#> [1] "gemini-2.0-flash"
#> $status
#> [1] "ready"
```

``` r

# Inspect the current configuration at any time
config <- llm_get_config()
str(config)
#> List of 5
#>  $ provider : chr "gemini"
#>  $ model    : chr "gemini-2.0-flash"
#>  $ base_url : NULL
#>  $ temperature: num 0
#>  $ status   : chr "ready"
```

### Switching Providers

You can reconfigure at any time:

``` r

# Start with free Ollama for development
llm_configure(provider = "ollama", model = "llama3.1:8b")
llm_topic_discovery(proj, n_topics = 5)

# Switch to Gemini for production
llm_configure(provider = "gemini", model = "gemini-2.0-flash")
llm_topic_discovery(proj, n_topics = 5)

# Results may differ between providers, but the interface is identical
```

## Semantic Search

### How It Works

Traditional keyword search works by **lexical matching** — the query
terms must appear (usually as substrings) in the target text. This has
two well-known limitations:

1.  **Vocabulary mismatch**: “climate change” won’t match “global
    warming” in a keyword search.
2.  **No concept ranking**: A document that mentions your query term
    once in passing is treated the same as one that addresses the
    concept throughout.

Semantic search addresses both problems. Instead of matching words, it
compares **vector representations** (embeddings) of meaning. The process
works as follows:

1.  Each work’s title and abstract are encoded into a high-dimensional
    vector by the LLM.
2.  The search query is encoded into the same vector space.
3.  Relevance is measured by cosine similarity between vectors.
4.  Results are ranked by semantic closeness, not keyword overlap.

The embeddings capture synonymy (“climate change” ≈ “global warming”),
hypernymy (“drought” is related to “climate”), and topical relatedness
(“NDVI” is related to “remote sensing in agriculture”).

``` mermaid
flowchart LR
    A[Corpus\nTitle + Abstract] --> B[LLM\nEmbedding]
    C[Search Query] --> B
    B --> D[Vector\nSimilarity]
    D --> E[Ranked\nResults]
    
    style A fill:#e1f5ff
    style C fill:#e1f5ff
    style B fill:#fff3e0
    style D fill:#f3e5f5
    style E fill:#e8f5e8
```

### Step-by-Step Example

#### Step 1: Configure a Provider

``` r

library(biblioIntegrator)
proj <- as_biblio_project(example_biblio())

# Ensure a provider is configured
llm_configure(
  provider = "ollama",
  model = "llama3.1:8b"
)
```

#### Step 2: Build the Embedding Index

The first semantic search call builds an embedding index for the corpus.
Subsequent searches reuse the cached index:

``` r

# First query builds the index (may take a few minutes for large corpora)
results <- semantic_search(
  proj,
  query = "sustainable agriculture practices",
  n_results = 10
)
```

#### Step 3: Inspect Results

``` r

# Results are a data frame sorted by relevance
print(results)
#>    work_id                                              title  year
#> 1  work_008  Sustainable intensification of crop production   2019
#> 2  work_003  Cover crops and soil health in tropical systems  2020
#> 3  work_011  Precision agriculture for resource efficiency   2021
#>    similarity score
#> 1          0.872
#> 2          0.845
#> 3          0.831
#>    ...
```

The `similarity` column ranges from -1 to 1 (typically 0.3 to 0.95 for
relevant results). Scores above 0.7 indicate strong semantic relevance.

#### Step 4: Refine with Filters

``` r

# Combine semantic search with metadata filters
results_filtered <- semantic_search(
  proj,
  query = "drought stress tolerance mechanisms",
  n_results = 10,
  filters = list(
    year_min = 2018,
    year_max = 2024,
    database = c("scopus", "wos")
  )
)
```

### Interpreting Relevance Scores

Understanding the `similarity` score is essential for correct
interpretation:

| Score Range | Interpretation      | Action                               |
|-------------|---------------------|--------------------------------------|
| 0.85 — 1.00 | Very high relevance | Almost certainly addresses the query |
| 0.70 — 0.85 | High relevance      | Very likely related to the query     |
| 0.55 — 0.70 | Moderate relevance  | Probably related; review manually    |
| 0.40 — 0.55 | Weak relevance      | Tangentially related                 |
| 0.00 — 0.40 | Low relevance       | Unlikely related to the query        |

**Important**: These thresholds are approximate and vary by LLM model.
Always calibrate on a sample of known-relevant documents before relying
on absolute thresholds.

## Topic Discovery

### Automatic Topic Identification

Topic discovery uses LLMs to identify **latent research themes** in a
corpus without requiring predefined categories. Unlike traditional
keyword-based topic models (LDA, structural topic models), LLM-based
topic discovery can:

- Capture **semantic themes** that span multiple keyword clusters.
- Generate **human-readable topic descriptions** rather than just
  keyword lists.
- Identify **emergent themes** that are not yet captured in controlled
  vocabularies.
- Work on **small corpora** (even 20-50 works) where LDA struggles.

### Basic Usage

``` r

library(biblioIntegrator)
proj <- as_biblio_project(example_biblio())
llm_configure(provider = "ollama", model = "llama3.1:8b")

# Discover 5 topics in the corpus
topics <- llm_topic_discovery(
  proj,
  n_topics = 5
)
```

### Interpreting Results

The output is a structured list:

``` r

# Examine the topic structure
str(topics, max.level = 2)
#> List of 3
#>  $ topics    :'data.frame': 5 obs. of 4 variables:
#>    ..$ topic_id    : int [1:5] 1 2 3 4 5
#>    ..$ label       : chr [1:5] "Soil Health and Microbiome" ...
#>    ..$ description : chr [1:5] "Research examining soil microbial communities..." ...
#>    ..$ keywords    : List of 5
#>  $ assignments :'data.frame': 12 obs. of 3 variables:
#>    ..$ work_id  : chr [1:12] "work_001" ...
#>    ..$ topic_id : int [1:12] 1 3 2 ...
#>    ..$ confidence: num [1:12] 0.85 0.72 0.91 ...
#>  $ summary     : chr "The corpus contains 5 main research themes..."
```

Each topic includes:

- **label**: A short, descriptive name (e.g., “Soil Health and
  Microbiome”).
- **description**: A paragraph explaining the theme’s scope and
  findings.
- **keywords**: Representative terms extracted by the LLM.
- **assignments**: Which works belong to each topic, with confidence
  scores.

### Controlling the Number of Topics

The `n_topics` parameter sets the target number. The LLM may return
fewer if the corpus is small or homogeneous:

``` r

# Fewer topics for a focused view
topics_3 <- llm_topic_discovery(proj, n_topics = 3)

# More topics for granular analysis
topics_10 <- llm_topic_discovery(proj, n_topics = 10)

# Let the LLM decide (recommended for small corpora)
topics_auto <- llm_topic_discovery(proj, n_topics = "auto")
```

**Guideline**: For a corpus of N works, a reasonable target is
`floor(sqrt(N))` to `floor(N/10)` topics. For 500 works, try 7-22
topics. For the example dataset (12 works), 3-5 topics is appropriate.

### Linking Topics to Works

The assignment table allows you to connect discovered topics back to the
bibliometric project for further analysis:

``` r

# Extract assignments
assignments <- topics$assignments

# Merge with works metadata
library(dplyr)
works_with_topics <- proj$works %>%
  left_join(assignments, by = "work_id")

# Count works per topic per year
topic_year <- works_with_topics %>%
  group_by(topic_id, year) %>%
  summarise(n_works = n(), .groups = "drop")

# Visualize topic evolution
library(ggplot2)
ggplot(topic_year, aes(x = year, y = n_works, color = factor(topic_id))) +
  geom_line(linewidth = 1) +
  labs(
    x = "Year",
    y = "Number of Works",
    color = "Topic",
    title = "Topic Evolution Over Time"
  ) +
  theme_minimal()
```

### Combining with Network Analysis

Topic assignments can enrich network visualizations:

``` r

# Add topic as a node attribute in a co-authorship network
if (requireNamespace("igraph", quietly = TRUE)) {
  # Build co-authorship network
  net <- bibliographic_network(proj, type = "coauthorship")
  
  # Map topic assignments to nodes
  # (implementation depends on network structure)
  topic_colors <- c(
    "1" = "#E41A1C",
    "2" = "#377EB8",
    "3" = "#4DAF4A",
    "4" = "#984EA3",
    "5" = "#FF7F00"
  )
}
```

## Intelligent Summarization

### Summary Modes

The
[`llm_summarize()`](https://wep69.github.io/biblioIntegrator/reference/llm_summarize.md)
function supports four distinct modes, each designed for a different
analytical purpose:

#### Mode 1: Executive Summary

A concise overview of the corpus, suitable for introductory sections of
literature reviews or grant proposals:

``` r

library(biblioIntegrator)
proj <- as_biblio_project(example_biblio())
llm_configure(provider = "ollama", model = "llama3.1:8b")

# Generate an executive summary
summary_exec <- llm_summarize(
  proj,
  mode = "executive",
  max_length = 500             # Target word count
)
cat(summary_exec$text)
#> The corpus of 12 works spans agricultural research from 2015 to 2023,
#> with a predominant focus on soil health, sustainable crop management,
#> and precision agriculture. Key methodological approaches include
#> field trials (n=5), meta-analyses (n=3), and remote sensing studies
#> (n=4). The most cited works address cover crop systems and their
#> effects on soil organic carbon...
```

#### Mode 2: Method-Focused Summary

Highlights the methodological landscape — what methods are used, how
they have evolved, and what gaps exist:

``` r

summary_method <- llm_summarize(
  proj,
  mode = "method",
  max_length = 800
)
cat(summary_method$text)
#> Methodologically, the corpus is dominated by field-based experimental
#> designs (5 of 12 works), typically randomized complete block designs
#> with 3-4 replications. Three works employ meta-analytic techniques,
#> pooling effect sizes from multiple studies. The remaining four works
#> use remote sensing approaches, primarily NDVI-based vegetation indices
#> from Sentinel-2 imagery. Notably absent are long-term (>10 year)
#> observational studies and participatory action research approaches...
```

#### Mode 3: Gap-Focused Summary

Identifies what is missing from the corpus:

``` r

summary_gaps <- llm_summarize(
  proj,
  mode = "gaps",
  max_length = 800
)
cat(summary_gaps$text)
#> Several notable gaps emerge from the corpus. First, tropical regions
#> are underrepresented — only 2 of 12 works focus on tropical
#> agriculture, despite its global importance. Second, socioeconomic
#> dimensions are absent: no work integrates economic cost-benefit
#> analysis with agronomic outcomes. Third, temporal depth is limited;
#> the longest study duration is 5 years, insufficient for detecting
#> slow soil carbon dynamics...
```

#### Mode 4: Comprehensive Synthesis

A detailed synthesis that integrates all analytical perspectives:

``` r

summary_comprehensive <- llm_summarize(
  proj,
  mode = "comprehensive",
  max_length = 2000
)
cat(summary_comprehensive$text)
#> [A multi-paragraph synthesis covering the corpus's thematic core,
#> methodological trends, citation landscape, key findings, unresolved
#> debates, and emergent research directions]
```

### Summary Output Structure

All modes return a structured list:

``` r

str(summary_exec)
#> List of 4
#>  $ text      : chr "The corpus of 12 works..."
#>  $ key_findings: chr [1:5] "Soil organic carbon increased..." ...
#>  $ word_count: int 487
#>  $ tokens_used: int 1523
```

### Custom Summarization with Prompts

For specialized needs, provide a custom prompt:

``` r

summary_custom <- llm_summarize(
  proj,
  mode = "custom",
  prompt = paste(
    "Write a methods section for a systematic review protocol.",
    "Describe the research landscape as if justifying the need",
    "for a new systematic review on this topic.",
    "Focus on methodological heterogeneity and knowledge gaps.",
    "Use formal academic English suitable for a PROSPERO registration."
  ),
  max_length = 1500
)
```

### Batch Summarization by Group

If you have formed groups in your project:

``` r

# Summarize each group separately
groups <- unique(proj$works$database)
summaries_by_group <- lapply(groups, function(db) {
  subset_proj <- filter_works(proj, database = db)
  llm_summarize(subset_proj, mode = "executive", max_length = 300)
})
names(summaries_by_group) <- groups
```

## Research Gap Analysis

### Gap Dimensions

The
[`llm_gap_analysis()`](https://wep69.github.io/biblioIntegrator/reference/llm_gap_analysis.md)
function identifies gaps across four dimensions:

``` mermaid
quadrantChart
    title Research Gap Dimensions
    x-axis "Content-Led" --> "Method-Led"
    y-axis "Global" --> "Temporal"
    "Thematic Gaps": [0.3, 0.4]
    "Methodological Gaps": [0.7, 0.3]
    "Geographic Gaps": [0.2, 0.8]
    "Temporal Gaps": [0.8, 0.7]
```

### Thematic Gaps

Identify topics that are under-explored or missing from the corpus:

``` r

library(biblioIntegrator)
proj <- as_biblio_project(example_biblio())
llm_configure(provider = "ollama", model = "llama3.1:8b")

gaps <- llm_gap_analysis(
  proj,
  dimensions = "thematic"
)

# Inspect thematic gaps
gaps$thematic
#>                               gap_description strength evidence
#> 1  Integration of socioeconomic factors with    High   Only 1
#>    agronomic outcomes in sustainable systems           of 12
#>    addresses market constraints
#> 2  Microbiome-mediated pathways for crop       Medium  2 of 12
#>    resilience under combined abiotic stresses          mention
#>    (drought + heat)                                    microbiome
#> 3  Participatory approaches involving farmers  Low    No works
#>    in technology co-design for smallholders            address this
```

### Methodological Gaps

Detect methods that are absent or under-represented:

``` r

gaps <- llm_gap_analysis(
  proj,
  dimensions = "methodological"
)

gaps$methodological
#>                           gap_description strength evidence
#> 1  Long-term (>10 years) field monitoring  High    Max study
#>    of soil carbon dynamics                                  duration
#>                                                             is 5 years
#> 2  Mixed-methods approaches combining     Medium  No qualitative
#>    quantitative agronomic data with                        data in
#>    qualitative farmer interviews                           corpus
#> 3  Machine learning for yield prediction  Low     Only 1 work
#>    from remote sensing data                               uses ML
```

### Geographic Gaps

Identify under-represented regions, countries, or agroecological zones:

``` r

gaps <- llm_gap_analysis(
  proj,
  dimensions = "geographic"
)

gaps$geographic
#>                           gap_description strength evidence
#> 1  Sub-Saharan African agriculture         High    0 of 12
#>    (fraught with climate vulnerability)                works
#> 2  South and Southeast Asian cropping     Medium  1 of 12
#>    systems                                              works
#> 3  Middle Eastern and North African        Low     0 of 12
#>    dryland agriculture                                 works
```

### Temporal Gaps

Detect periods or developmental stages that are under-studied:

``` r

gaps <- llm_gap_analysis(
  proj,
  dimensions = "temporal"
)

gaps$temporal
#>                           gap_description strength evidence
#> 1  Post-2020 climate adaptation studies   Medium  Only 2
#>    with field validation data                          of 12
#>                                                     works
#>                                                     >2020
#> 2  Winter season crop studies and         Low     No works
#>    frost dynamics                                      address
#>                                                     winter
#>                                                     crops
```

### Comprehensive Gap Analysis

Analyze all dimensions simultaneously:

``` r

gaps_all <- llm_gap_analysis(
  proj,
  dimensions = "all",
  top_n = 5                    # Return top 5 gaps per dimension
)

# Summary view
gaps_all$summary
#> A text summary synthesizing all identified gaps and their
#> interconnections...
```

### Gap Analysis Output Structure

``` r

str(gaps_all, max.level = 2)
#> List of 5
#>  $ thematic      :'data.frame':    5 obs. of 3 variables
#>  $ methodological:'data.frame':    5 obs. of 3 variables
#>  $ geographic    :'data.frame':    5 obs. of 3 variables
#>  $ temporal      :'data.frame':    5 obs. of 3 variables
#>  $ summary       : chr "The corpus reveals four major gap clusters..."
```

### Using Gap Analysis for Grant Proposals

Gap analysis output can be directly incorporated into grant proposals:

``` r

# Generate a gap statement for a grant proposal
gap_statement <- paste(
  "Based on a systematic analysis of", nrow(proj$works), "works in the field,",
  "this proposal addresses three critical knowledge gaps:",
  "",
  "1.", gaps_all$thematic$gap_description[1],
  "",
  "2.", gaps_all$methodological$gap_description[1],
  "",
  "3.", gaps_all$geographic$gap_description[1],
  sep = "\n"
)

cat(gap_statement)
```

## Query Expansion

### Why Expand Search Queries?

Systematic reviews require **exhaustive** search strategies — the goal
is to identify all relevant works, not just the most easily found ones.
A search query for “precision agriculture” will miss works that use
“site-specific crop management,” “variable rate technology,” or “digital
farming.”

[`llm_query_expand()`](https://wep69.github.io/biblioIntegrator/reference/llm_query_expand.md)
generates comprehensive search strings that capture synonyms, related
terms, and alternative phrasing without losing the core concept.

### Basic Usage

``` r

library(biblioIntegrator)
llm_configure(provider = "ollama", model = "llama3.1:8b")

# Expand a concept
expanded <- llm_query_expand(
  query = "precision agriculture in tropical regions",
  n_terms = 20                  # Generate up to 20 related terms
)

cat(expanded$expanded_query)
#> ("precision agriculture" OR "site-specific crop management" OR
#> "variable rate technology" OR "digital farming" OR "smart farming"
#> OR "agriculture 4.0" OR "precision farming" OR "sensor-based
#> management" OR "GPS-guided agriculture" OR "drone-based crop
#> monitoring" OR "decision support system" AND "tropical" OR
#> "subtropical" OR "equatorial" OR "humid tropics" OR "developing
#> countries" OR "global south" OR "low-latitude agriculture")
```

### Database-Specific Formatting

Different databases use different boolean syntax. The `database`
parameter formats the output accordingly:

#### Scopus (ADVANCED search)

``` r

expanded_scopus <- llm_query_expand(
  query = "precision agriculture in tropical regions",
  database = "scopus",
  n_terms = 15
)
cat(expanded_scopus$expanded_query)
#> TITLE-ABS-KEY(("precision agriculture" OR "site-specific crop management"
#> OR "variable rate technology" OR "digital farming" OR "smart farming")
#> AND ("tropical" OR "subtropical" OR "equatorial"))
```

#### Web of Science (Advanced Search)

``` r

expanded_wos <- llm_query_expand(
  query = "precision agriculture in tropical regions",
  database = "wos",
  n_terms = 15
)
cat(expanded_wos$expanded_query)
#> TS=("precision agriculture" OR "site-specific crop management" OR
#> "variable rate technology" OR "digital farming" OR "smart farming")
#> AND TS=("tropical" OR "subtropical" OR "equatorial")
```

#### PubMed (Advanced Search)

``` r

expanded_pubmed <- llm_query_expand(
  query = "precision agriculture in tropical regions",
  database = "pubmed",
  n_terms = 15
)
cat(expanded_pubmed$expanded_query)
#> ("precision agriculture"[tiab] OR "site-specific crop management"[tiab]
#> OR "variable rate technology"[tiab]) AND ("tropical"[tiab] OR
#> "subtropical"[tiab])
```

#### Generic Boolean

``` r

expanded_generic <- llm_query_expand(
  query = "precision agriculture in tropical regions",
  database = "generic",
  n_terms = 15
)
cat(expanded_generic$expanded_query)
#> A plain boolean query string suitable for any compatible system
```

### Custom Expansion with Domain Context

Provide domain-specific context for more targeted expansion:

``` r

expanded_custom <- llm_query_expand(
  query = "soil carbon sequestration",
  database = "scopus",
  n_terms = 25,
  context = paste(
    "Focus on agronomic and soil science terminology.",
    "Include both English and common MeSH terms.",
    "Exclude purely geological or ocean carbon studies."
  )
)
```

### Evaluating Expansion Quality

The output includes metadata about the expansion:

``` r

str(expanded)
#> List of 4
#>  $ expanded_query : chr "..."
#>  $ terms_added    : chr [1:18] "site-specific crop management" ...
#>  $ original_terms : chr [1:4] "precision" "agriculture" "tropical" "regions"
#>  $ tokens_used     : int 845
```

### Iterative Refinement

For systematic reviews, we recommend an iterative approach:

``` r

# Round 1: Broad expansion
r1 <- llm_query_expand(
  query = "machine learning for crop yield prediction",
  database = "scopus",
  n_terms = 30
)

# Round 2: Refine with feedback from Round 1 results
r2 <- llm_query_expand(
  query = "machine learning for crop yield prediction",
  database = "scopus",
  n_terms = 30,
  context = paste(
    "Round 1 returned many remote sensing papers.",
    "Expand focus to include ground-based sensor data,",
    "weather-based models, and crop simulation models.",
    "Exclude pure remote sensing without ML components."
  )
)
```

### Token Estimation for Expansion

| N Terms | Approx. Tokens | Cost (gpt-4o-mini) | Cost (Gemini Free) |
|---------|----------------|--------------------|--------------------|
| 10      | 400            | \< \$0.001         | Free               |
| 20      | 700            | \< \$0.001         | Free               |
| 30      | 1,000          | ~ \$0.001          | Free               |

## Thematic Classification

### Two Approaches to Classification

[`llm_classify()`](https://wep69.github.io/biblioIntegrator/reference/llm_classify.md)
supports two approaches:

1.  **User-defined categories**: You provide the categories; the LLM
    assigns works to them.
2.  **LLM-suggested categories**: The LLM proposes categories based on
    the corpus content, then assigns works.

### User-Defined Categories

``` r

library(biblioIntegrator)
proj <- as_biblio_project(example_biblio())
llm_configure(provider = "ollama", model = "llama3.1:8b")

# Define your categories
my_categories <- c(
  "Soil Health and Fertility",
  "Crop Physiology and Genetics",
  "Precision Agriculture and Technology",
  "Sustainability and Climate Adaptation",
  "Economics and Policy"
)

# Classify works
classified <- llm_classify(
  proj,
  categories = my_categories
)

print(classified$assignments)
#>    work_id                  category  confidence secondary_category
#> 1  work_001 Soil Health and Fertility      0.92                --
#> 2  work_002 Precision Agriculture...      0.88  Sustainability...
#> 3  work_003 Soil Health and Fertility      0.85  Sustainability...
#> ...
```

### LLM-Suggested Categories

``` r

# Let the LLM discover categories
classified_auto <- llm_classify(
  proj,
  categories = "auto",               # LLM suggests categories
  n_categories = 5                    # Target number of categories
)

# View discovered categories
print(classified_auto$categories)
#> [1] "Soil Microbial Ecology"
#> [2] "Remote Sensing Applications"
#> [3] "Cover Crop Systems"
#> [4] "Climate-Smart Agriculture"
#> [5] "Agronomic Technology Adoption"
```

### Confidence Scores

Each assignment includes a confidence score between 0 and 1:

``` r

# Confidence distribution
summary(classified$assignments$confidence)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.
#>   0.620   0.780   0.850   0.834   0.910   0.980

# Flag low-confidence assignments for manual review
low_confidence <- classified$assignments %>%
  filter(confidence < 0.70)

cat(nrow(low_confidence), "works need manual classification review.\n")
```

**Interpreting confidence scores:**

| Score       | Interpretation | Action                         |
|-------------|----------------|--------------------------------|
| ≥ 0.90      | Very confident | Accept automatically           |
| 0.75 – 0.89 | Confident      | Accept with spot-check         |
| 0.60 – 0.74 | Moderate       | Manual review recommended      |
| \< 0.60     | Low confidence | Manual classification required |

### Multi-Label Classification

Works often belong to multiple categories. Use `multi_label = TRUE`:

``` r

classified_ml <- llm_classify(
  proj,
  categories = my_categories,
  multi_label = TRUE,
  max_labels = 3               # Up to 3 categories per work
)

# Works can now appear in multiple categories
classified_ml$assignments %>%
  group_by(work_id) %>%
  summarise(
    categories = paste(category, collapse = " | "),
    mean_confidence = mean(confidence)
  )
#>    work_id                              categories  mean_confidence
#> 1  work_001 Soil Health | Sustainability | Economics       0.82
#> 2  work_002 Precision Agriculture | Sustainability          0.85
#> ...
```

### Comparing Classification with Keywords

An interesting analysis: compare LLM categories with author keywords:

``` r

# Extract author keywords per work
author_kw <- proj$keywords %>%
  filter(keyword_type == "author") %>%
  group_by(work_id) %>%
  summarise(keywords = paste(keyword, collapse = ", "))

# Compare with LLM categories
comparison <- classified$assignments %>%
  left_join(author_kw, by = "work_id") %>%
  select(work_id, category, confidence, keywords)

print(comparison)
#>    work_id                  category confidence              keywords
#> 1  work_001 Soil Health and...       0.92    soil, carbon, tillage
#> 2  work_002 Precision Agri...         0.88    NDVI, remote sensing
#> ...
#> Notable: LLM captures thematic relationships that individual
#> keywords cannot express
```

### Using Classification for Group Comparisons

Classified categories can drive comparative analysis:

``` r

if (requireNamespace("dplyr", quietly = TRUE)) {
  # Add category to works
  works_cat <- proj$works %>%
    inner_join(classified$assignments, by = "work_id")
  
  # Compute average citations per category
  cat_citations <- works_cat %>%
    group_by(category) %>%
    summarise(
      n_works = n(),
      mean_citations = mean(times_cited, na.rm = TRUE),
      median_citations = median(times_cited, na.rm = TRUE)
    ) %>%
    arrange(desc(mean_citations))
  
  print(cat_citations)
}
```

### Batch Classification for Large Corpora

For corpora exceeding a few hundred works, use batching:

``` r

# For large corpora, batch classification is managed automatically
# You can control batch size:
classified_large <- llm_classify(
  proj,                           # Assuming a large corpus
  categories = my_categories,
  batch_size = 20,                # Process 20 works per LLM call
  show_progress = TRUE             # Print progress bar
)
```

## Citation Context Analysis

### Beyond Citation Counts

Traditional citation analysis counts **how many** works cite a given
paper. But not all citations are equal:

- A citation in the **methods section** means the cited work’s approach
  was adopted.
- A citation as **supporting evidence** means the cited work’s findings
  confirm the citing work’s results.
- A citation as **contrasting evidence** means the cited work’s findings
  are being challenged or qualified.
- A **background citation** in the introduction merely acknowledges the
  broader field.

[`llm_citation_context()`](https://wep69.github.io/biblioIntegrator/reference/llm_citation_context.md)
reads the text surrounding each citation and classifies its rhetorical
purpose.

### Supported Context Types

| Type | Symbol | Meaning | Typical Section |
|----|----|----|----|
| Support | `+` | Cited work’s findings support the current work | Results, Discussion |
| Contrast | `-` | Cited work’s findings are challenged or refined | Discussion |
| Method | `M` | Cited work’s method was used or adapted | Methods |
| Background | `B` | Cited work is contextual framing | Introduction |
| Data | `D` | Cited work provides data, materials, or tools | Methods |

### Basic Usage

``` r

library(biblioIntegrator)
proj <- as_biblio_project(example_biblio())
llm_configure(provider = "ollama", model = "llama3.1:8b")

# Analyze citation contexts
contexts <- llm_citation_context(proj)
```

### Interpreting Results

``` r

print(contexts$summary)
#> Citation Context Analysis
#> ─────────────────────────
#> Total citations analyzed: 156
#>
#> Distribution:
#>   Support:    45 (28.8%)
#>   Background: 62 (39.7%)
#>   Method:     31 (19.9%)
#>   Contrast:   12 ( 7.7%)
#>   Data:        6 ( 3.8%)
#>
#> Most cited works:
#>   1. Smith et al. (2019) - 14 citations [6S, 5B, 2M, 1C]
#>   2. Jones et al. (2020) - 12 citations [3S, 7B, 1M, 1D]
#>   ...

# Detailed citation-by-citation results
print(contexts$details)
#>    citing_work_id cited_work_id  context_type  confidence  excerpt
#> 1  work_003       work_001      Support       0.91
#>    "Our findings confirm those of Smith et al.
#>     (2019), who reported a 15% increase in SOC..."
#> 2  work_005       work_002      Contrast      0.85
#>    "In contrast to Jones et al. (2020), our study
#>     found no significant effect of cover crops on..."
#> ...
```

### Support vs. Contrast Citations

The most analytically valuable distinction is between support and
contrast:

``` r

# Works that receive many contrast citations are "contested"
contested <- contexts$details %>%
  filter(context_type == "Contrast") %>%
  count(cited_work_id, sort = TRUE) %>%
  head(10)

cat("Most contested works (highest contrast citation count):\n")
print(contested)
#>   cited_work_id  n
#> 1 work_007       5
#> 2 work_002       3
#> 3 work_011       2
```

### Method Citations

Method citations reveal methodological influence:

``` r

# Works whose methods are most widely adopted
method_influential <- contexts$details %>%
  filter(context_type == "Method") %>%
  count(cited_work_id, sort = TRUE) %>%
  head(10)

cat("Most methodologically influential works:\n")
print(method_influential)
```

### Background Citations

Background citations are informative for understanding canonical
references:

``` r

# Canonical works (high background citation ratio)
background_ratio <- contexts$details %>%
  group_by(cited_work_id) %>%
  summarise(
    total_citations = n(),
    background_pct = mean(context_type == "Background") * 100
  ) %>%
  arrange(desc(background_pct))

# Works with >70% background citations are canonical/frame-setting
canonical <- background_ratio %>%
  filter(background_pct > 70, total_citations >= 3)

cat("Canonical/frame-setting works:\n")
print(canonical)
```

### Building a Citation Context Network

Combine citation types with network analysis:

``` r

# Create a weighted citation network with context types
if (requireNamespace("igraph", quietly = TRUE)) {
  citation_edges <- contexts$details %>%
    mutate(
      weight = case_when(
        context_type == "Support" ~ 2,
        context_type == "Contrast" ~ 3,
        context_type == "Method" ~ 1.5,
        TRUE ~ 1
      )
    )
  # Build network from weighted edges
  # (implementation depends on your network pipeline)
}
```

### Token Usage and Batching

Citation context analysis is the most token-intensive LLM function
because it processes citation excerpts:

| Corpus Size | Citations (est.) | Tokens/Call | Batches | Est. Cost (gpt-4o-mini) |
|-------------|------------------|-------------|---------|-------------------------|
| 50 works    | ~200             | 3,000/batch | 4       | ~ \$0.01                |
| 200 works   | ~1,500           | 3,000/batch | 30      | ~ \$0.05                |
| 1,000 works | ~8,000           | 3,000/batch | 150     | ~ \$0.25                |

## Costs and Limitations

### Token Counting

Every LLM function returns `tokens_used` in its output, enabling precise
cost tracking:

``` r

# Execute an operation and track tokens
result <- llm_topic_discovery(proj, n_topics = 5)

# Check token usage
result$tokens_used
#> [1] 3245

# Accumulate total usage in a session
total_tokens <- 0
track_tokens <- function(result) {
  total_tokens <<- total_tokens + result$tokens_used
  cat("This call:", result$tokens_used, "tokens |",
      "Session total:", total_tokens, "tokens\n")
}

track_tokens(result)
#> This call: 3245 tokens | Session total: 3245 tokens
```

### Cost Estimation by Provider

#### Free Providers

| Provider          | Limit        | Practical Capacity              |
|-------------------|--------------|---------------------------------|
| Ollama (local)    | None         | Unlimited (limited by hardware) |
| Gemini Free Tier  | 15 req/min   | ~500 works/hour                 |
| Hugging Face Free | 1000 req/day | ~30,000 works/day               |

#### Paid Providers (Estimated Costs)

Assuming a **500-work corpus** and a **complete analytical workflow**
(search + topics + summaries + gaps + classification + citation
contexts):

| Provider  | Model             | Est. Total Cost | Notes                           |
|-----------|-------------------|-----------------|---------------------------------|
| OpenAI    | gpt-4o-mini       | ~\$0.05         | Best cost/quality ratio         |
| OpenAI    | gpt-4o            | ~\$0.80         | Higher quality synthesis        |
| Anthropic | claude-3-5-sonnet | ~\$1.50         | Best reasoning, longest context |

For a **2,000-work corpus** (typical systematic review):

| Provider  | Model             | Est. Total Cost |
|-----------|-------------------|-----------------|
| OpenAI    | gpt-4o-mini       | ~\$0.15         |
| OpenAI    | gpt-4o            | ~\$2.50         |
| Anthropic | claude-3-5-sonnet | ~\$5.00         |

#### Cost Optimization Strategies

``` r

# Strategy 1: Use free providers for development
llm_configure(provider = "ollama", model = "llama3.1:8b")
# ... develop and test your workflow ...

# Strategy 2: Use gpt-4o-mini for bulk, gpt-4o for synthesis
llm_configure(provider = "openai", model = "gpt-4o-mini")
classified <- llm_classify(proj, categories = my_categories)

llm_configure(provider = "openai", model = "gpt-4o")
synthesis <- llm_summarize(proj, mode = "comprehensive")

# Strategy 3: Cache results aggressively (see Best Practices)
```

### Rate Limits by Provider

| Provider     | Free Tier         | Paid Tier                    |
|--------------|-------------------|------------------------------|
| Ollama       | Unlimited (local) | —                            |
| Gemini       | 15 req/min        | 1,000 req/min                |
| OpenAI       | —                 | 500-10,000 req/min (by tier) |
| Anthropic    | —                 | 50-4,000 req/min (by tier)   |
| Hugging Face | 1,000 req/day     | Unlimited                    |

All `biblioIntegrator` LLM functions respect rate limits automatically:

``` r

# Rate limiting is automatic, but you can configure retry behavior:
llm_configure(
  provider = "gemini",
  model = "gemini-2.0-flash",
  rate_limit = 12,                 # Requests per minute (conservative)
  retry_on_rate_limit = TRUE,
  max_retries = 5,
  retry_wait = 5                   # Seconds between retries
)
```

### Accuracy Considerations

LLM outputs are **probabilistic** — they may vary between runs and may
contain errors. Key considerations:

#### What LLMs Do Well

- Identifying semantic similarity between texts
- Extracting explicit information from text
- Classifying texts into well-defined categories
- Generating natural language summaries
- Expanding queries with domain-appropriate terminology

#### What LLMs Do Less Well

- Precise numerical reasoning (e.g., exact citation counts)
- Recency-sensitive information (models have training cutoff dates)
- Distinguishing highly similar but subtly different claims
- Understanding statistical methodology (may confuse tests or
  assumptions)
- Identifying errors in referenced works (may accept cited claims at
  face value)

### Hallucination Risks

LLMs can “hallucinate” — generate plausible-sounding but incorrect
information. In the bibliometric context:

| Hallucination Type | Example | Risk Level |
|----|----|----|
| Fabricated findings | “This work found X” (when it didn’t) | High |
| Incorrect attribution | “Smith et al. showed…” (wrong authors) | High |
| Invented terms | Expanding query with non-existent terminology | Medium |
| Plausible but wrong context | Misclassifying a citation context | Medium |
| Minor numerical errors | Off-by-one in count summaries | Low |

**Mitigation strategies** (see Best Practices below) are essential.

## Best Practices

### Practice 1: Always Verify LLM Outputs

LLM outputs are starting points for analysis, not final answers. Treat
them as you would a research assistant’s first draft:

``` r

# Verify topic discovery results
topics <- llm_topic_discovery(proj, n_topics = 5)

# Check: Do the assigned works match your domain knowledge?
for (tid in topics$topics$topic_id) {
  assigned_works <- topics$assignments %>%
    filter(topic_id == tid) %>%
    pull(work_id)
  
  cat("\nTopic", tid, ":", topics$topics$label[tid], "\n")
  cat("Assigned works:", paste(assigned_works, collapse = ", "), "\n")
  
  # Spot-check: read titles of assigned works
  titles <- proj$works %>%
    filter(work_id %in% assigned_works) %>%
    pull(title)
  cat("Titles:\n")
  cat(paste(" -", titles, collapse = "\n"), "\n")
}
```

### Practice 2: Use Structured Prompts for Reproducibility

Always provide explicit, structured prompts when using custom modes:

``` r

# GOOD: Structured, specific prompt
good_prompt <- paste(
  "You are a systematic review methodologist.",
  "Analyze this bibliometric corpus and identify research gaps.",
  "",
  "Organize your response as follows:",
  "1. THEMATIC GAPS: Topics underexplored in the corpus",
  "2. METHODOLOGICAL GAPS: Methods missing or underused",
  "3. GEOGRAPHIC GAPS: Regions underrepresented",
  "4. TEMPORAL GAPS: Time periods or developmental stages missing",
  "",
  "For each gap, provide:",
  "- A one-sentence description",
  "- A strength rating (High/Medium/Low)",
  "- Evidence from the corpus supporting this gap",
  sep = "\n"
)

gaps <- llm_gap_analysis(proj, prompt = good_prompt)

# BAD: Vague, unstructured prompt
# "Tell me what's missing from this research."
```

### Practice 3: Cache Results

LLM results are expensive (in time if not money). Cache them:

``` r

library(biblioIntegrator)
proj <- as_biblio_project(example_biblio())
llm_configure(provider = "ollama", model = "llama3.1:8b")

# Define cache path
cache_dir <- file.path(tempdir(), "llm_cache")
dir.create(cache_dir, showWarnings = FALSE)

cached_topic_discovery <- function(proj, n_topics, cache_dir) {
  cache_file <- file.path(cache_dir, paste0("topics_", n_topics, ".rds"))
  
  if (file.exists(cache_file)) {
    message("Loading cached topic discovery results...")
    return(readRDS(cache_file))
  }
  
  message("Running topic discovery...")
  result <- llm_topic_discovery(proj, n_topics = n_topics)
  saveRDS(result, cache_file)
  result
}

# Use cached version
topics <- cached_topic_discovery(proj, n_topics = 5, cache_dir = cache_dir)
```

### Practice 4: Start with Free Providers

``` r

# Development workflow
# Phase 1: Develop on Ollama (free, fast iteration)
llm_configure(provider = "ollama", model = "llama3.1:8b")
topics_test <- llm_topic_discovery(proj, n_topics = 3)   # Quick test

# Phase 2: Validate on Gemini free tier
llm_configure(provider = "gemini", model = "gemini-2.0-flash")
topics_val <- llm_topic_discovery(proj, n_topics = 5)

# Phase 3: Production runs (if needed) on paid provider
llm_configure(provider = "openai", model = "gpt-4o-mini")
topics_prod <- llm_topic_discovery(proj, n_topics = 5)
```

### Practice 5: Use Temperature = 0 for Reproducibility

Temperature controls randomness in LLM outputs. For bibliometric
analysis, reproducibility is more important than creativity:

``` r

# Set temperature to 0 for deterministic output
llm_configure(
  provider = "openai",
  model = "gpt-4o-mini",
  temperature = 0                    # Deterministic
)

# Results will be identical across runs (given the same input)
topics_1 <- llm_topic_discovery(proj, n_topics = 5)
topics_2 <- llm_topic_discovery(proj, n_topics = 5)
# topics_1 and topics_2 should be identical
```

### Practice 6: Set Explicit Output Formats

When the LLM output will be parsed programmatically, use JSON mode:

``` r

# Request JSON output for structured data
topics_json <- llm_topic_discovery(
  proj,
  n_topics = 5,
  output_format = "json"           # Forces valid JSON response
)

# Parse the JSON
if (requireNamespace("jsonlite", quietly = TRUE)) {
  parsed <- fromJSON(topics_json$text)
  # Use parsed directly as a structured R object
}
```

### Practice 7: Document LLM Provenance

`biblioIntegrator` records LLM operations in the provenance table:

``` r

# LLM operations are automatically recorded
topics <- llm_topic_discovery(proj, n_topics = 5)

# The provenance table now includes:
# - operation: "llm_topic_discovery"
# - parameters: "provider=ollama, model=llama3.1:8b, n_topics=5"
# - summary: "Discovered 5 topics in 12 works"
audit_biblio(proj)
```

### Practice 8: Batch Large Corpora Thoughtfully

For large corpora (1,000+ works), batching reduces costs and respects
rate limits:

``` r

# Automatic batching (recommended)
classified <- llm_classify(
  proj,
  categories = my_categories,
  batch_size = 20                  # 20 works per LLM call
)

# Manual batch control
works_batches <- split(
  proj$works$work_id,
  ceiling(seq_along(proj$works$work_id) / 20)
)

results <- lapply(works_batches, function(batch_ids) {
  sub_proj <- filter_works(proj, work_id = batch_ids)
  llm_classify(sub_proj, categories = my_categories)
})

# Combine results
all_assignments <- do.call(rbind, lapply(results, `[[`, "assignments"))
```

## Common Mistakes

### Mistake 1: Not Configuring a Provider First

**The problem**: Calling an LLM function without first configuring a
provider.

**The error**:

``` r

# This will fail if no provider is configured
library(biblioIntegrator)
proj <- as_biblio_project(example_biblio())
llm_topic_discovery(proj, n_topics = 5)
#> Error: No LLM provider configured.
#> Call llm_configure() first.
#> Quick start: llm_configure(provider = "ollama", model = "llama3.1:8b")
```

**The fix**:

``` r

# Always configure first
llm_configure(provider = "ollama", model = "llama3.1:8b")
# Then call LLM functions
llm_topic_discovery(proj, n_topics = 5)
```

### Mistake 2: Ignoring Rate Limits

**The problem**: Making rapid, sequential API calls without respecting
provider rate limits.

**The consequence**: HTTP 429 (Too Many Requests) errors, failed
operations, or temporary IP bans.

**The fix**:

``` r

# Set conservative rate limits
llm_configure(
  provider = "gemini",
  model = "gemini-2.0-flash",
  rate_limit = 10,                 # Stay well under 15/min
  retry_on_rate_limit = TRUE
)

# For large corpora, use batching to reduce call count
classified <- llm_classify(
  proj,
  categories = my_categories,
  batch_size = 20                  # Fewer calls needed
)
```

### Mistake 3: Trusting LLM Outputs Without Verification

**The problem**: Accepting LLM-generated classifications, topic labels,
or gap analyses as ground truth without manual review.

**The consequence**: Inaccurate results propagating through the
analysis, potentially leading to flawed conclusions in published work.

**The fix**:

``` r

# ALWAYS verify a random sample
set.seed(42)
sample_ids <- sample(proj$works$work_id, min(5, nrow(proj$works)))

# For each sampled work, check the LLM classification against your knowledge
for (wid in sample_ids) {
  cat("Work:", wid, "\n")
  cat("Title:", proj$works$title[proj$works$work_id == wid], "\n")
  assignment <- classified$assignments %>%
    filter(work_id == wid)
  cat("LLM Category:", assignment$category,
      "(confidence:", round(assignment$confidence, 2), ")\n")
  cat("Your assessment: [MANUAL CHECK REQUIRED]\n\n")
}
```

### Mistake 4: Sending Too Much Text at Once

**The problem**: Passing the entire corpus text in a single prompt,
exceeding the model’s context window.

**The consequence**: Silent truncation (text beyond the window is
ignored), or API errors.

**The fix**:

``` r

# Check corpus size before processing
total_chars <- sum(nchar(proj$works$abstract), na.rm = TRUE) +
               sum(nchar(proj$works$title), na.rm = TRUE)
cat("Total corpus text:", format(total_chars, big.mark = ","), "characters\n")

# biblioIntegrator handles batching automatically, but be aware:
# - Llama 3.1 (8B): 128K tokens ≈ ~400K characters
# - Gemini Flash: 1M tokens ≈ ~3M characters
# - GPT-4o-mini: 128K tokens ≈ ~400K characters

# For very large corpora, use functions that process in batches
classified <- llm_classify(proj, categories = my_categories, batch_size = 20)
```

### Mistake 5: Not Using JSON Mode for Structured Outputs

**The problem**: Expecting perfectly structured data from free-form text
generation.

**The consequence**: Parsing failures, inconsistent column names, or
lost data when the LLM includes explanatory text mixed with structured
output.

**The fix**:

``` r

# Use output_format = "json" for structured outputs
topics <- llm_topic_discovery(
  proj,
  n_topics = 5,
  output_format = "json"           # Returns parseable JSON
)

# Always wrap parsing in tryCatch
parsed <- tryCatch(
  jsonlite::fromJSON(topics$text),
  error = function(e) {
    warning("JSON parse failed, returning raw text")
    topics$text
  }
)
```

### Mistake 6: Using High Temperature for Classification

**The problem**: Leaving temperature at its default (often 0.7-1.0) for
classification or extraction tasks.

**The consequence**: Inconsistent classifications across runs, making
results non-reproducible.

**The fix**:

``` r

# Classification and extraction: temperature = 0
llm_configure(
  provider = "openai",
  model = "gpt-4o-mini",
  temperature = 0
)

# Summarization and creative writing: temperature = 0.3-0.7 OK
# (but still document the value used)
```

### Mistake 7: Not Handling Missing Abstracts

**The problem**: Including works without abstracts in LLM analysis.
Works without abstracts provide minimal signal and may confuse topic
discovery or classification.

**The consequence**: Poor quality results, especially for older works or
those from databases that don’t include abstracts.

**The fix**:

``` r

# Check abstract coverage
abstract_coverage <- mean(!is.na(proj$works$abstract) &
                          nchar(proj$works$abstract) > 0)
cat("Abstract coverage:", round(abstract_coverage * 100, 1), "%\n")

# Filter to works with abstracts for LLM analysis
has_abstract <- !is.na(proj$works$abstract) & nchar(proj$works$abstract) > 10
proj_with_abstracts <- filter_works(
  proj,
  work_id = proj$works$work_id[has_abstract]
)

# Run LLM analysis on the filtered corpus
topics <- llm_topic_discovery(proj_with_abstracts, n_topics = 5)
```

### Summary of Common Mistakes

| \# | Mistake | Consequence | Solution |
|----|----|----|----|
| 1 | No provider configured | Error on every LLM call | [`llm_configure()`](https://wep69.github.io/biblioIntegrator/reference/llm_configure.md) first |
| 2 | Ignoring rate limits | HTTP 429, failed operations | Set `rate_limit` and `retry_on_rate_limit` |
| 3 | Trusting without verification | Inaccurate published results | Manual spot-check of random samples |
| 4 | Too much text at once | Silent truncation or errors | Use automatic batching |
| 5 | No JSON mode | Parse failures | Use `output_format = "json"` |
| 6 | High temperature | Non-reproducible results | Set `temperature = 0` |
| 7 | Missing abstracts | Poor analysis quality | Filter to works with abstracts |

## Putting It All Together: Complete Workflow

### End-to-End Example

This section demonstrates a complete LLM-assisted bibliometric workflow:

``` r

library(biblioIntegrator)

# ──────────────────────────────────────────────────────────────
# Step 1: Setup
# ──────────────────────────────────────────────────────────────

proj <- as_biblio_project(example_biblio())
llm_configure(
  provider = "ollama",
  model = "llama3.1:8b",
  temperature = 0                    # Reproducible
)

# Verify availability
llm_status()

# ──────────────────────────────────────────────────────────────
# Step 2: Data Quality Check
# ──────────────────────────────────────────────────────────────

health <- biblio_health(proj)
cat("Health issues:", nrow(health), "\n")

# Ensure abstracts are available
abstract_coverage <- mean(!is.na(proj$works$abstract) & 
                          nchar(proj$works$abstract) > 10)
cat("Abstract coverage:", round(abstract_coverage * 100, 1), "%\n")

# ──────────────────────────────────────────────────────────────
# Step 3: Traditional Descriptive Analysis (no LLM needed)
# ──────────────────────────────────────────────────────────────

describe_biblio(proj)

# ──────────────────────────────────────────────────────────────
# Step 4: Topic Discovery
# ──────────────────────────────────────────────────────────────

topics <- llm_topic_discovery(proj, n_topics = 5)

cat("\n=== Discovered Topics ===\n")
for (i in seq_along(topics$topics$topic_id)) {
  cat(sprintf(
    "\nTopic %d: %s\n  %s\n",
    topics$topics$topic_id[i],
    topics$topics$label[i],
    topics$topics$description[i]
  ))
}

# ──────────────────────────────────────────────────────────────
# Step 5: Semantic Search for Related Concepts
# ──────────────────────────────────────────────────────────────

search_results <- semantic_search(
  proj,
  query = "soil health indicators and sustainable management",
  n_results = 8
)

cat("\n=== Top Semantic Matches ===\n")
print(search_results)

# ──────────────────────────────────────────────────────────────
# Step 6: Summarization
# ──────────────────────────────────────────────────────────────

exec_summary <- llm_summarize(proj, mode = "executive", max_length = 400)
cat("\n=== Executive Summary ===\n")
cat(exec_summary$text, "\n")

method_summary <- llm_summarize(proj, mode = "method", max_length = 400)
cat("\n=== Method Summary ===\n")
cat(method_summary$text, "\n")

# ──────────────────────────────────────────────────────────────
# Step 7: Gap Analysis
# ──────────────────────────────────────────────────────────────

gaps <- llm_gap_analysis(proj, dimensions = "all", top_n = 3)

cat("\n=== Top Thematic Gaps ===\n")
print(gaps$thematic)

cat("\n=== Top Geographic Gaps ===\n")
print(gaps$geographic)

# ──────────────────────────────────────────────────────────────
# Step 8: Query Expansion for Follow-up Search
# ──────────────────────────────────────────────────────────────

expanded_search <- llm_query_expand(
  query = "soil microbiome and crop productivity",
  database = "scopus",
  n_terms = 20
)

cat("\n=== Expanded Scopus Query ===\n")
cat(expanded_search$expanded_query, "\n")

# ──────────────────────────────────────────────────────────────
# Step 9: Thematic Classification
# ──────────────────────────────────────────────────────────────

categories <- c(
  "Soil Microbiology",
  "Crop Management",
  "Climate Adaptation",
  "Remote Sensing and Technology",
  "Food Security and Sustainability"
)

classified <- llm_classify(proj, categories = categories)

cat("\n=== Classification Summary ===\n")
print(table(classified$assignments$category))

# ──────────────────────────────────────────────────────────────
# Step 10: Citation Context Analysis
# ──────────────────────────────────────────────────────────────

citation_ctx <- llm_citation_context(proj)

cat("\n=== Citation Context Summary ===\n")
print(citation_ctx$summary)

# ──────────────────────────────────────────────────────────────
# Step 11: Token Usage Summary
# ──────────────────────────────────────────────────────────────

total_tokens <- sum(
  topics$tokens_used,
  search_results$tokens_used %||% 0,
  exec_summary$tokens_used,
  method_summary$tokens_used,
  gaps$tokens_used,
  expanded_search$tokens_used,
  classified$tokens_used,
  citation_ctx$tokens_used
)

cat("\n=== LLM Usage Summary ===\n")
cat("Total tokens used:", format(total_tokens, big.mark = ","), "\n")
cat("Estimated cost (gpt-4o-mini pricing):",
    sprintf("$%.3f", total_tokens * 0.15 / 1e6), "\n")
cat("Estimated cost (Gemini free tier): $0.00\n")

# ──────────────────────────────────────────────────────────────
# Step 12: Save Results
# ──────────────────────────────────────────────────────────────

# Save the complete LLM analysis
llm_results <- list(
  topics = topics,
  search_results = search_results,
  summaries = list(
    executive = exec_summary,
    method = method_summary
  ),
  gaps = gaps,
  expanded_search = expanded_search,
  classification = classified,
  citation_contexts = citation_ctx,
  metadata = list(
    provider = llm_get_config()$provider,
    model = llm_get_config()$model,
    timestamp = Sys.time(),
    session_info = sessionInfo()
  )
)

# saveRDS(llm_results, "llm_analysis_results.rds")
cat("\nLLM analysis complete.\n")
```

### Adapting This Workflow

The workflow above can be adapted for specific use cases:

| Use Case | Functions to Use | Skip |
|----|----|----|
| Systematic review planning | `llm_query_expand` → Manual search → `llm_topic_discovery` | Classification |
| Literature gap identification | `llm_topic_discovery` → `llm_gap_analysis` | Query expansion |
| Research landscape overview | `llm_topic_discovery` → `llm_summarize` → `llm_classify` | Citation context |
| Citation network enrichment | `llm_citation_context` → Network analysis | Query expansion |
| Grant proposal writing | `llm_gap_analysis` → `llm_summarize(mode="gaps")` | Classification |

## Advanced Topics

### Combining LLM Analysis with Traditional Metrics

The power of LLM analysis is amplified when combined with traditional
bibliometric indicators:

``` r

library(biblioIntegrator)
library(dplyr)

proj <- as_biblio_project(example_biblio())
llm_configure(provider = "ollama", model = "llama3.1:8b")

# Get topic assignments
topics <- llm_topic_discovery(proj, n_topics = 5)
assignments <- topics$assignments

# Combine with citation metrics
combined <- proj$works %>%
  left_join(assignments, by = "work_id") %>%
  left_join(
    topics$topics %>% select(topic_id, topic_label = label),
    by = "topic_id"
  )

# Topic-citation analysis
topic_citations <- combined %>%
  group_by(topic_label) %>%
  summarise(
    n_works = n(),
    mean_citations = mean(times_cited, na.rm = TRUE),
    max_citations = max(times_cited, na.rm = TRUE),
    median_confidence = median(confidence, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(mean_citations))

print(topic_citations)
```

### LLM-Assisted Author Disambiguation

While `biblioIntegrator` provides deterministic author disambiguation,
LLMs can assist in edge cases:

``` r

# Identify ambiguous author names
author_counts <- proj$authorships %>%
  left_join(proj$authors, by = "author_id") %>%
  group_by(last_name, first_name) %>%
  summarise(n_works = n(), .groups = "drop")

# Potential duplicates: same surname, overlapping initials
# LLM can help resolve by comparing affiliation strings, co-authors,
# and research topics across candidate matches
```

### LLM-Enhanced Descriptive Reports

Augment standard descriptive reports with LLM-generated insights:

``` r

# Standard descriptive statistics
desc <- describe_biblio(proj)

# LLM enhancement
exec <- llm_summarize(proj, mode = "executive", max_length = 300)
gaps <- llm_gap_analysis(proj, dimensions = "thematic", top_n = 3)

# Combine into a rich report
report_text <- paste(
  "# Bibliometric Analysis Report",
  "", "## Descriptive Overview", desc$summary,
  "", "## LLM-Generated Executive Summary", exec$text,
  "", "## Identified Research Gaps",
  paste("-", gaps$thematic$gap_description, collapse = "\n"),
  sep = "\n"
)

cat(report_text)
```

### Group Comparison with LLM Enrichment

Compare groups of works using both traditional metrics and LLM insights:

``` r

# Split works by database
scopus_works <- filter_works(proj, database = "scopus")
wos_works <- filter_works(proj, database = "wos")

# Traditional comparison
# (Use compare_groups or compare_sources from the package)

# LLM comparison
scopus_summary <- llm_summarize(scopus_works, mode = "executive",
                                 max_length = 200)
wos_summary <- llm_summarize(wos_works, mode = "executive",
                              max_length = 200)

cat("=== Scopus-based corpus ===\n")
cat(scopus_summary$text, "\n\n")
cat("=== Web of Science-based corpus ===\n")
cat(wos_summary$text, "\n")
```

### Building a Reproducible LLM Pipeline

For publication-ready analyses, ensure full reproducibility:

``` r

# Record all LLM configuration
llm_config_snapshot <- llm_get_config()
cat("LLM Configuration:\n")
cat("  Provider:", llm_config_snapshot$provider, "\n")
cat("  Model:", llm_config_snapshot$model, "\n")
cat("  Temperature:", llm_config_snapshot$temperature, "\n")
cat("  Timestamp:", as.character(Sys.time()), "\n")
cat("  biblioIntegrator version:",
    as.character(packageVersion("biblioIntegrator")), "\n")
cat("  R version:", R.version.string, "\n")

# Include in the Methods section:
# "Topic discovery was performed using the llm_topic_discovery() function
#  of biblioIntegrator (v0.3.0) with [provider] [model] at temperature 0.
#  [N] topics were requested. Each work's title and abstract were encoded
#  into [dim]-dimensional embeddings and clustered using [method].
#  Assignments with confidence < 0.70 were manually reviewed by [author]."
```

## Function Quick Reference

### LLM Configuration Functions

| Function | Purpose | Key Parameters |
|----|----|----|
| [`llm_configure()`](https://wep69.github.io/biblioIntegrator/reference/llm_configure.md) | Set provider and model | `provider`, `model`, `api_key`, `temperature`, `save` |
| [`llm_get_config()`](https://wep69.github.io/biblioIntegrator/reference/llm_get_config.md) | Inspect current config | (none) |
| [`llm_status()`](https://wep69.github.io/biblioIntegrator/reference/llm_status.md) | Check provider availability | (none) |

### LLM Analysis Functions

| Function | Purpose | Key Parameters |
|----|----|----|
| [`semantic_search()`](https://wep69.github.io/biblioIntegrator/reference/semantic_search.md) | Find by meaning | `query`, `n_results`, `filters` |
| [`llm_topic_discovery()`](https://wep69.github.io/biblioIntegrator/reference/llm_topic_discovery.md) | Discover themes | `n_topics`, `output_format` |
| [`llm_summarize()`](https://wep69.github.io/biblioIntegrator/reference/llm_summarize.md) | Summarize corpus | `mode`, `max_length`, `prompt` |
| [`llm_gap_analysis()`](https://wep69.github.io/biblioIntegrator/reference/llm_gap_analysis.md) | Find research gaps | `dimensions`, `top_n` |
| [`llm_query_expand()`](https://wep69.github.io/biblioIntegrator/reference/llm_query_expand.md) | Expand search strings | `database`, `n_terms`, `context` |
| [`llm_classify()`](https://wep69.github.io/biblioIntegrator/reference/llm_classify.md) | Assign categories | `categories`, `multi_label`, `batch_size` |
| [`llm_citation_context()`](https://wep69.github.io/biblioIntegrator/reference/llm_citation_context.md) | Classify citations | (none, processes all references) |

### Common Parameters Across LLM Functions

| Parameter | Type | Default | Description |
|----|----|----|----|
| `proj` | biblio_project | (required) | The project to analyze |
| `provider` | character | from config | Override provider for this call |
| `model` | character | from config | Override model for this call |
| `temperature` | numeric | from config | Controls randomness (0 = deterministic) |
| `output_format` | character | “text” | “text” or “json” |
| `verbose` | logical | TRUE | Print progress messages |
| `batch_size` | integer | auto | Works per LLM call (for large corpora) |

## Migration Guide

### From Manual Analysis to LLM-Assisted

If you have an existing `biblioIntegrator` workflow and want to add LLM
capabilities:

#### Step 1: Add Provider Configuration

``` r

# Add this at the top of your script, after library()
library(biblioIntegrator)

# Add LLM configuration
llm_configure(
  provider = "ollama",             # Or "gemini", "openai", etc.
  model = "llama3.1:8b"           # Or appropriate model for your provider
)
```

#### Step 2: Add LLM Analysis After Descriptive Analysis

``` r

# After your existing descriptive analysis...
describe_biblio(proj)
biblio_health(proj)

# ...add LLM analysis
topics <- llm_topic_discovery(proj, n_topics = 5)
summary <- llm_summarize(proj, mode = "executive")
gaps <- llm_gap_analysis(proj, dimensions = "all")
```

#### Step 3: Integrate Results

``` r

# The LLM results can be used alongside existing analyses:
# - Topic assignments for network coloring
# - Gap analysis for grant proposals
# - Summaries for reports
# - Classification for group comparisons
```

### From bibliometrix to biblioIntegrator + LLM

If you have been using `bibliometrix` and want to add LLM capabilities:

``` r

# Your existing bibliometrix workflow:
# library(bibliometrix)
# bib_df <- convert2df("scopus_export.csv", dbsource = "scopus")
# results <- biblioAnalysis(bib_df)

# Add biblioIntegrator + LLM:
library(biblioIntegrator)
proj <- as_biblio_project(example_biblio())

llm_configure(provider = "ollama", model = "llama3.1:8b")

# LLM-enhanced analysis
topics <- llm_topic_discovery(proj, n_topics = 5)
summary <- llm_summarize(proj, mode = "method")

# You can export to bibliometrix format for compatibility
if (requireNamespace("bibliometrix", quietly = TRUE)) {
  bib_df <- as_bibliometrix(proj)
}
```

## Frequently Asked Questions

### General Questions

**Q: Do I need to be connected to the internet for LLM features?**

A: Only if using a cloud provider (Gemini, OpenAI, Anthropic, Hugging
Face). With Ollama, all inference is local — no internet needed after
the initial model download (~4.7 GB for Llama 3.1 8B).

**Q: Is my data sent to external servers?**

A: Only if you configure a cloud provider. With Ollama, your data never
leaves your machine. Review each provider’s privacy policy before using
them with sensitive research data.

**Q: Can I use multiple providers in the same session?**

A: Yes. Call
[`llm_configure()`](https://wep69.github.io/biblioIntegrator/reference/llm_configure.md)
to switch providers at any time. Results from different providers will
not be identical but should be broadly consistent for classification and
topic discovery tasks.

**Q: What happens if the LLM provider is unavailable?**

A: Functions return a clear error message. Your `biblio_project` data is
never modified by failed LLM operations.

**Q: Are LLM results deterministic?**

A: With `temperature = 0`, results are *mostly* deterministic — the same
input should produce the same output across runs. However, model updates
by the provider can change outputs over time. Always record your
provider, model, and temperature for reproducibility.

### Technical Questions

**Q: How much abstract text is needed for good LLM results?**

A: At minimum, the title is needed. Title + abstract produces the best
results. Works without abstracts can still be classified based on title,
keywords, and references, but accuracy drops by approximately 20-30%.

**Q: What is the maximum corpus size for LLM analysis?**

A: There is no hard limit. `biblioIntegrator` automatically batches
large corpora. A 10,000-work corpus with Ollama might take 30-60 minutes
for topic discovery; with Gemini free tier, approximately 2-3 hours (due
to rate limits). Batch size and rate limits are configurable.

**Q: Can I use a custom or fine-tuned model?**

A: Yes. Any model accessible through Ollama, OpenAI API, or Anthropic
API can be configured. For Ollama, download the model first with
`ollama pull`, then configure with the model name.

**Q: How does semantic search differ from
[`biblio_query()`](https://wep69.github.io/biblioIntegrator/reference/biblio_query.md)?**

A:
[`biblio_query()`](https://wep69.github.io/biblioIntegrator/reference/biblio_query.md)
performs exact or pattern-based text matching (SQL-like WHERE clauses).
[`semantic_search()`](https://wep69.github.io/biblioIntegrator/reference/semantic_search.md)
compares meaning vectors — it finds works that address the same concept
regardless of the specific words used. Use both:
[`biblio_query()`](https://wep69.github.io/biblioIntegrator/reference/biblio_query.md)
for precise metadata filters,
[`semantic_search()`](https://wep69.github.io/biblioIntegrator/reference/semantic_search.md)
for conceptual exploration.

**Q: Can I export LLM results for use outside R?**

A: Yes. All LLM functions return structured lists containing data
frames. Use [`write.csv()`](https://rdrr.io/r/utils/write.table.html)
for tabular results,
[`jsonlite::toJSON()`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html)
for JSON export, or [`saveRDS()`](https://rdrr.io/r/base/readRDS.html)
for full R object preservation.

## References

### Key Methodological References

- **Aria, M., & Cuccurullo, C.** (2017). bibliometrix: An R-tool for
  comprehensive science mapping analysis. *Journal of Informetrics*,
  11(4), 959–975. <doi:10.1016/j.joi.2017.08.007>

- **Umek, L.** (2026). Biblium: a Python library for comparative
  bibliometric analysis. *Scientometrics*, 131(5), 3359–3377.
  <doi:10.1007/s11192-026-05636-8>

### LLM and AI Documentation

- **OpenAI.** (2024). OpenAI API documentation.
  <https://platform.openai.com/docs>

- **Google.** (2024). Google Gemini API documentation.
  <https://ai.google.dev/docs>

- **Ollama.** (2024). Ollama: Run large language models locally.
  <https://ollama.com>

- **Anthropic.** (2024). Anthropic API documentation.
  <https://docs.anthropic.com>

- **Hugging Face.** (2024). Hugging Face Inference API documentation.
  <https://huggingface.co/docs/api-inference>

### Related R Packages

- **ellmer** (2025). Call LLMs from R.
  <https://posit-dev.github.io/ellmer/>

- **httr2** (2024). HTTP client for R. <https://httr2.r-lib.org/>

### Research on LLM Applications in Bibliometrics

- **Ding, Z., et al.** (2024). The power of large language models in
  bibliometric analysis. *Journal of Informetrics*, 18(2), 101507.

- **Wang, S., et al.** (2024). Can large language models replace humans
  in systematic reviews? *arXiv preprint* arXiv:2404.01308.

- **Khraisha, Q., et al.** (2024). Can large language models replace
  humans in systematic reviews? Evaluating GPT-4’s efficacy in screening
  and extracting data from peer-reviewed and grey literature. *Journal
  of Informetrics*, 18(4), 101565.

## Session Info

``` r

sessionInfo()
#> R version 4.6.0 (2026-04-24 ucrt)
#> Platform: x86_64-w64-mingw32/x64
#> Running under: Windows 11 x64 (build 26200)
#> 
#> Matrix products: default
#>   LAPACK version 3.12.1
#> 
#> locale:
#> [1] LC_COLLATE=Portuguese_Brazil.utf8  LC_CTYPE=Portuguese_Brazil.utf8   
#> [3] LC_MONETARY=Portuguese_Brazil.utf8 LC_NUMERIC=C                      
#> [5] LC_TIME=Portuguese_Brazil.utf8    
#> 
#> time zone: America/Sao_Paulo
#> tzcode source: internal
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] jsonlite_2.0.0         knitr_1.52             tibble_3.3.1          
#> [4] biblioIntegrator_0.3.0
#> 
#> loaded via a namespace (and not attached):
#>  [1] vctrs_0.7.3       cli_3.6.6         rlang_1.3.0       xfun_0.61        
#>  [5] otel_0.2.0        textshaping_1.0.5 glue_1.8.1        htmltools_0.5.9  
#>  [9] ragg_1.5.2        sass_0.4.10       rmarkdown_2.32    evaluate_1.0.5   
#> [13] jquerylib_0.1.4   fastmap_1.2.0     yaml_2.3.12       lifecycle_1.0.5  
#> [17] compiler_4.6.0    fs_2.1.0          pkgconfig_2.0.3   htmlwidgets_1.6.4
#> [21] systemfonts_1.3.2 digest_0.6.39     R6_2.6.1          pillar_1.11.1    
#> [25] magrittr_2.0.5    bslib_0.12.0      tools_4.6.0       pkgdown_2.2.1    
#> [29] cachem_1.1.0      desc_1.4.3
```
