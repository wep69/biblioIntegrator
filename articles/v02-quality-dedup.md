# Data Quality and Deduplication

## Why This Vignette Exists

Data quality is the foundation of valid bibliometric analysis. No amount
of sophisticated statistical modeling, network visualization, or
comparative inference can compensate for a corpus contaminated by
duplicate records, missing metadata, or inconsistent identifiers. This
vignette provides a comprehensive guide to diagnosing, auditing, and
cleaning bibliographic data using the `biblioIntegrator` package.

### The Problem of Data Quality

Bibliographic databases—including Web of Science, Scopus, PubMed, and
OpenAlex—each have their own data structures, naming conventions, and
quality standards. When researchers export data from multiple sources or
over extended time periods, several problems emerge:

1.  **Duplicate records**: The same publication may appear multiple
    times due to database updates, corrections, or cross-database
    indexing
2.  **Missing metadata**: Critical fields such as titles, publication
    years, DOIs, or author names may be incomplete
3.  **Inconsistent identifiers**: DOIs may be formatted differently
    (with or without URL prefixes), author names may vary across records
4.  **Orphan records**: Author-keyword-work linkages may reference
    non-existent records after filtering

These issues directly impact every downstream analysis:

- **Descriptive statistics**: Duplicate records inflate publication
  counts, distort annual trends, and misrepresent author productivity
- **Citation metrics**: Duplicate entries split citation counts, leading
  to underestimation of true impact
- **Network analysis**: Duplicate nodes create artificial connections,
  fragment communities, and distort centrality measures
- **Comparative inference**: Unbalanced duplicates across groups
  introduce systematic bias into hypothesis tests
- **Temporal analysis**: Duplicates with different years create phantom
  trends

### When to Check Quality

Quality checks should precede **any** analytical step. The recommended
workflow is:

    Import → Harmonize → **Quality Check** → Deduplicate → Analyze

This vignette assumes you have already imported and harmonized your data
using the functions described in
[`vignette("v01-import-harmonize")`](https://wep69.github.io/biblioIntegrator/articles/v01-import-harmonize.md).
If you are working with a raw data frame, convert it first:

``` r

library(biblioIntegrator)
x <- as_biblio_project(my_data, source = "my_export")
```

### What You Will Not Find Here

This vignette does not cover:

- Data import from specific databases (see
  [`vignette("v01-import-harmonize")`](https://wep69.github.io/biblioIntegrator/articles/v01-import-harmonize.md))
- Network construction or community detection (see
  [`vignette("v05-networks")`](https://wep69.github.io/biblioIntegrator/articles/v05-networks.md))
- Comparative statistical inference (see
  [`vignette("v04-comparative-inference")`](https://wep69.github.io/biblioIntegrator/articles/v04-comparative-inference.md))
- Scalable backends for large corpora (see
  [`vignette("v08-scalable-backends")`](https://wep69.github.io/biblioIntegrator/articles/v08-scalable-backends.md))

These topics build on the clean, deduplicated corpus you will prepare
here.

## Learning Objectives

After working through this vignette, you will be able to:

1.  **Diagnose corpus health** using
    [`biblio_health()`](https://wep69.github.io/biblioIntegrator/reference/biblio_health.md)
    and interpret each diagnostic check
2.  **Identify missing metadata** including titles, years, DOIs, and
    author information
3.  **Detect duplicate records** using DOI matching, title+year
    combinations, and fuzzy string matching
4.  **Understand deduplication strategies** and their tradeoffs between
    precision and recall
5.  **Apply deduplication** systematically using
    [`deduplicate_biblio()`](https://wep69.github.io/biblioIntegrator/reference/deduplicate_biblio.md)
    with different methods
6.  **Audit data integrity** with
    [`audit_biblio()`](https://wep69.github.io/biblioIntegrator/reference/audit_biblio.md)
    to verify provenance tracking
7.  **Identify orphan records** and referential integrity issues in
    harmonized data
8.  **Evaluate deduplication quality** by comparing results across
    methods
9.  **Document data transformations** through provenance logs for
    reproducibility
10. **Avoid common pitfalls** in bibliometric data cleaning workflows

### Prerequisites

This vignette assumes basic familiarity with:

- R data frames and basic data manipulation
- The `biblio_project` object class (see
  [`vignette("v00-overview")`](https://wep69.github.io/biblioIntegrator/articles/v00-overview.md))
- The concept of bibliometric indicators (see
  [`vignette("v03-descriptive-impact")`](https://wep69.github.io/biblioIntegrator/articles/v03-descriptive-impact.md))

No external packages beyond `biblioIntegrator` are required for the core
examples. Optional fuzzy matching demonstrations require the
`stringdist` package, which is not a dependency of `biblioIntegrator`
but can be installed separately.

``` r

# Core package
library(biblioIntegrator)

# Optional: for fuzzy matching examples
has_stringdist <- requireNamespace("stringdist", quietly = TRUE)
```

## The Health Diagnostic

The
[`biblio_health()`](https://wep69.github.io/biblioIntegrator/reference/biblio_health.md)
function provides a systematic overview of data quality issues in a
`biblio_project`. It performs six standardized checks and returns a data
frame summarizing the number of records affected by each issue.

### Running biblio_health()

Let us start with the example corpus included in the package:

``` r

# Load example data
raw <- example_biblio()

# Create a biblio_project
x <- as_biblio_project(raw, source = "example corpus")

# Run health diagnostics
health_report <- biblio_health(x)
print(health_report)
#>                  check n
#> 1        missing_title 0
#> 2         missing_year 0
#> 3          missing_doi 0
#> 4        duplicate_doi 0
#> 5 duplicate_title_year 0
#> 6   negative_citations 0
```

The output is a data frame with two columns:

- **check**: The name of the quality check
- **n**: The number of records flagged by that check

### Understanding the Output Structure

The health report includes six standardized checks. Let us examine what
each one detects:

``` r

# Display the health report in a readable format
cat("Quality Health Report\n")
#> Quality Health Report
cat("====================\n\n")
#> ====================
for (i in seq_len(nrow(health_report))) {
  cat(sprintf("%-25s %d records\n", 
              health_report$check[i], 
              health_report$n[i]))
}
#> missing_title             0 records
#> missing_year              0 records
#> missing_doi               0 records
#> duplicate_doi             0 records
#> duplicate_title_year      0 records
#> negative_citations        0 records
```

The six checks are:

| Check | Description |
|----|----|
| `missing_title` | Records with empty or whitespace-only titles |
| `missing_year` | Records with `NA` publication year |
| `missing_doi` | Records with empty DOI field |
| `duplicate_doi` | Records sharing the same DOI (excluding empty DOIs) |
| `duplicate_title_year` | Records with identical title+year combinations |
| `negative_citations` | Records with negative citation counts |

### Interpreting Each Check

#### Missing Titles

Missing titles are problematic because titles are used as identifiers in
deduplication and are essential for human verification of results:

``` r

# Check for missing titles
missing_title_count <- health_report$n[health_report$check == "missing_title"]
cat("Records with missing titles:", missing_title_count, "\n")
#> Records with missing titles: 0

# If non-zero, identify the affected records
if (missing_title_count > 0) {
  problem_records <- x$works[!nzchar(trimws(x$works$title)), ]
  print(problem_records[, c("work_id", "year", "doi")])
}
```

**Impact**: Records without titles cannot be reliably deduplicated by
title matching and should be flagged for manual review.

#### Missing Years

Missing publication years affect temporal analysis, citation velocity
calculations, and period-based comparisons:

``` r

# Check for missing years
missing_year_count <- health_report$n[health_report$check == "missing_year"]
cat("Records with missing years:", missing_year_count, "\n")
#> Records with missing years: 0

# If non-zero, show the problematic records
if (missing_year_count > 0) {
  problem_records <- x$works[is.na(x$works$year), ]
  print(problem_records[, c("work_id", "title", "doi")])
}
```

**Impact**: Functions like
[`describe_biblio()`](https://wep69.github.io/biblioIntegrator/reference/describe_biblio.md),
[`trend_topics()`](https://wep69.github.io/biblioIntegrator/reference/trend_topics.md),
and
[`temporal_growth()`](https://wep69.github.io/biblioIntegrator/reference/temporal_growth.md)
will exclude or misclassify records with missing years.

#### Missing DOIs

DOIs (Digital Object Identifiers) are the most reliable unique
identifier for scholarly publications:

``` r

# Check for missing DOIs
missing_doi_count <- health_report$n[health_report$check == "missing_doi"]
cat("Records with missing DOIs:", missing_doi_count, "\n")
#> Records with missing DOIs: 0

# Calculate percentage
cat(sprintf("%.1f%% of records lack DOIs\n", 
            100 * missing_doi_count / nrow(x$works)))
#> 0.0% of records lack DOIs
```

**Impact**: Without DOIs, deduplication must rely on less reliable
title+year matching, increasing the risk of false positives (merging
distinct records) or false negatives (missing actual duplicates).

#### Duplicate DOIs

Duplicate DOIs are a strong indicator of true duplicates, since DOIs are
designed to be unique identifiers:

``` r

# Check for duplicate DOIs
dup_doi_count <- health_report$n[health_report$check == "duplicate_doi"]
cat("Records with duplicate DOIs:", dup_doi_count, "\n")
#> Records with duplicate DOIs: 0

# If non-zero, identify the duplicated DOIs
if (dup_doi_count > 0) {
  doi_table <- table(x$works$doi[nzchar(x$works$doi)])
  repeated_dois <- names(doi_table[doi_table > 1])
  cat("\nDuplicated DOIs:\n")
  for (doi in head(repeated_dois, 5)) {
    cat(sprintf("  %s: %d copies\n", doi, sum(x$works$doi == doi)))
  }
}
```

**Deduplication strategy**: When DOIs match, we can be highly confident
these are true duplicates. The DOI-based matching has near-zero false
positive rate.

#### Duplicate Title+Year

Title+year matching catches duplicates that may have different or
missing DOIs:

``` r

# Check for duplicate title+year combinations
dup_ty_count <- health_report$n[health_report$check == "duplicate_title_year"]
cat("Records with duplicate title+year:", dup_ty_count, "\n")
#> Records with duplicate title+year: 0

# Show examples if any exist
if (dup_ty_count > 0) {
  title_year <- paste(tolower(x$works$title), x$works$year)
  ty_table <- table(title_year)
  repeated_ty <- names(ty_table[ty_table > 1])
  cat("\nDuplicated title+year combinations:\n")
  for (ty in head(repeated_ty, 3)) {
    cat(sprintf("  '%s'\n", ty))
  }
}
```

**Precision concern**: Some legitimate publications share the same title
and year (e.g., preprints and final versions, or corrected/retracted
articles). Manual review is recommended for title+year matches without
DOI confirmation.

#### Negative Citations

Negative citation counts are data errors that should be corrected or
excluded:

``` r

# Check for negative citations
neg_cite_count <- health_report$n[health_report$check == "negative_citations"]
cat("Records with negative citations:", neg_cite_count, "\n")
#> Records with negative citations: 0
```

**Impact**: Negative citations will distort
[`biblio_metrics()`](https://wep69.github.io/biblioIntegrator/reference/biblio_metrics.md),
[`normalized_citations()`](https://wep69.github.io/biblioIntegrator/reference/normalized_citations.md),
and
[`citation_velocity()`](https://wep69.github.io/biblioIntegrator/reference/citation_velocity.md)
calculations.

### Filtering the Health Report

For large corpora, you may want to focus on actual problems rather than
checks that passed:

``` r

# Show only checks that detected issues
problems <- subset(health_report, n > 0)
cat("Active quality issues:\n")
#> Active quality issues:
print(problems)
#> [1] check n    
#> <0 rows> (or 0-length row.names)

# If no issues found
if (nrow(problems) == 0) {
  cat("No quality issues detected. Corpus is clean.\n")
}
#> No quality issues detected. Corpus is clean.
```

### Visualizing Health Status

For a quick overview, you can visualize the health report:

``` r

# Basic barplot of issues (only if issues exist)
problems <- subset(health_report, n > 0)
if (nrow(problems) > 0) {
  barplot(problems$n, 
          names.arg = problems$check,
          main = "Data Quality Issues",
          xlab = "Check Type",
          ylab = "Number of Records",
          col = ifelse(problems$n > 0, "coral", "lightgreen"),
          las = 2)
}
```

## Introducing Quality Issues

To demonstrate the deduplication workflow, we will systematically
introduce quality issues into the example corpus. This approach allows
us to verify that our cleaning procedures work correctly.

### Creating a Contaminated Corpus

``` r

# Start with clean example data
clean_data <- example_biblio()

# Create duplicates by repeating records
# 1. Exact DOI duplicate
dup1 <- clean_data[1, ]  # First record

# 2. Same title+year but different DOI (simulates cross-database duplicate)
dup2 <- clean_data[3, ]
dup2$doi <- "10.9999/alternate.doi.3"

# 3. Similar but not identical title (will test fuzzy matching)
dup3 <- clean_data[5, ]
dup3$title <- "Cover Crop Effects on Soil Aggregation"  # Slightly different
dup3$doi <- ""  # No DOI

# Combine into contaminated corpus
contaminated_data <- rbind(clean_data, dup1, dup2, dup3)

# Also introduce some missing data
contaminated_data$title[2] <- ""  # Missing title
contaminated_data$year[4] <- NA   # Missing year
contaminated_data$doi[6] <- ""    # Missing DOI
contaminated_data$citations[8] <- -5  # Negative citation

cat("Original records:", nrow(clean_data), "\n")
#> Original records: 12
cat("Contaminated records:", nrow(contaminated_data), "\n")
#> Contaminated records: 15
cat("Added records:", nrow(contaminated_data) - nrow(clean_data), "\n")
#> Added records: 3
```

### Converting to biblio_project

``` r

# Convert contaminated data to biblio_project
x_dirty <- as_biblio_project(contaminated_data, source = "contaminated example")

# Run health check on contaminated data
health_dirty <- biblio_health(x_dirty)
cat("\nHealth report for contaminated corpus:\n")
#> 
#> Health report for contaminated corpus:
print(health_dirty)
#>                  check n
#> 1        missing_title 1
#> 2         missing_year 1
#> 3          missing_doi 2
#> 4        duplicate_doi 1
#> 5 duplicate_title_year 2
#> 6   negative_citations 1
```

You should see elevated counts for several checks, reflecting the issues
we introduced.

### Examining the Contaminated Data

``` r

# Show the problematic records
cat("Records with issues:\n\n")
#> Records with issues:

# Missing title
if (any(!nzchar(trimws(x_dirty$works$title)))) {
  cat("Missing titles:\n")
  print(x_dirty$works[!nzchar(trimws(x_dirty$works$title)), 
                      c("work_id", "title", "year", "doi")])
}
#> Missing titles:
#>     work_id title year            doi
#> 2 W000035cb       2019 10.1000/agri.2

# Missing year
if (any(is.na(x_dirty$works$year))) {
  cat("\nMissing years:\n")
  print(x_dirty$works[is.na(x_dirty$works$year), 
                      c("work_id", "title", "year", "doi")])
}
#> 
#> Missing years:
#>     work_id                              title year            doi
#> 4 W0001a71c Silicon nutrition in maize drought   NA 10.1000/agri.4

# Negative citations
if (any(x_dirty$works$cited_by_count < 0, na.rm = TRUE)) {
  cat("\nNegative citations:\n")
  print(x_dirty$works[x_dirty$works$cited_by_count < 0, 
                      c("work_id", "title", "year", "cited_by_count")])
}
#> 
#> Negative citations:
#>     work_id                          title year cited_by_count
#> 8 W000176af Soil microbiome under rotation 2020             -5
```

## Deduplication Strategies

Deduplication is the process of identifying and removing duplicate
records from a dataset. In bibliometric analysis, this is critical
because duplicates inflate counts and distort analyses. The
`biblioIntegrator` package implements a hierarchical deduplication
strategy that balances precision (correctly identifying true duplicates)
and recall (finding all actual duplicates).

### The Matching Hierarchy

The
[`deduplicate_biblio()`](https://wep69.github.io/biblioIntegrator/reference/deduplicate_biblio.md)
function implements a two-stage matching hierarchy:

    Stage 1: DOI Matching (High Precision)
        ↓ No DOI match
    Stage 2: Title+Year Matching (Moderate Precision)
        ↓ Results combined
    Final: Deduplicated Corpus

#### Stage 1: DOI Matching

DOI matching is the most reliable deduplication method because DOIs are
designed to be globally unique identifiers for scholarly publications.

**Advantages:** - Near-zero false positive rate - Fast computation -
Handles abbreviations and URL prefixes automatically

**Limitations:** - Only works when DOIs are present and correctly
formatted - Some older publications lack DOIs - Preprints and final
versions may have different DOIs

``` r

# Demonstrate DOI normalization
example_dois <- c(
  "10.1000/agri.1",
  "https://doi.org/10.1000/agri.2",
  "doi:10.1000/ag.3",
  "10.1000/agri.4",
  NA,
  ""
)

# Show how biblioIntegrator normalizes DOIs
cat("DOI normalization examples:\n")
#> DOI normalization examples:
cat("Raw → Normalized\n")
#> Raw → Normalized
cat("--- → ----------\n")
#> --- → ----------
for (doi in example_dois) {
  # Simple DOI normalization (lowercase, strip prefix)
  normalized <- tolower(trimws(as.character(doi)))
  normalized <- sub("^https?://(dx\\.)?doi\\.org/", "", normalized)
  normalized <- sub("^doi:\\s*", "", normalized)
  cat(sprintf("%s → %s\n", 
              ifelse(is.na(doi), "NA", paste0("'", doi, "'")),
              paste0("'", normalized, "'")))
}
#> '10.1000/agri.1' → '10.1000/agri.1'
#> 'https://doi.org/10.1000/agri.2' → '10.1000/agri.2'
#> 'doi:10.1000/ag.3' → '10.1000/ag.3'
#> '10.1000/agri.4' → '10.1000/agri.4'
#> NA → 'NA'
#> '' → ''
```

#### Stage 2: Title+Year Matching

When DOIs are missing or do not match, the algorithm falls back to
title+year matching.

**Process:** 1. Normalize titles: convert to lowercase, remove
non-alphanumeric characters 2. Combine with year: create key as
`normalized_title:year` 3. Match on these combined keys

**Advantages:** - Works for publications without DOIs - Catches
duplicates across databases with different DOI assignments

**Limitations:** - Higher false positive rate than DOI matching -
Sensitive to title variations (subtitles, abbreviations, typos) -
Legitimate duplicate titles exist (e.g., corrected papers, errata)

``` r

# Demonstrate title normalization
example_titles <- c(
  "Silicon and salinity tolerance in rice",
  "Silicon and Salinity Tolerance in Rice",
  "Silicon  &  salinity  tolerance  in  rice!",
  "Silicon and salinity tolerance in rice: A review"
)

# Show normalization process
cat("Title normalization examples:\n")
#> Title normalization examples:
for (title in example_titles) {
  # Replicate normalization from deduplicate_biblio()
  normalized <- gsub("[^[:alnum:]]", "", tolower(title))
  cat(sprintf("'%s'\n  → '%s'\n", title, normalized))
}
#> 'Silicon and salinity tolerance in rice'
#>   → 'siliconandsalinitytoleranceinrice'
#> 'Silicon and Salinity Tolerance in Rice'
#>   → 'siliconandsalinitytoleranceinrice'
#> 'Silicon  &  salinity  tolerance  in  rice!'
#>   → 'siliconsalinitytoleranceinrice'
#> 'Silicon and salinity tolerance in rice: A review'
#>   → 'siliconandsalinitytoleranceinriceareview'
```

### Precision vs. Recall Tradeoff

The choice of deduplication strategy involves balancing two competing
objectives:

| Strategy            | Precision | Recall    | Best For                           |
|---------------------|-----------|-----------|------------------------------------|
| DOI only            | Very High | Low       | Clean data with good DOI coverage  |
| Title+Year only     | Moderate  | High      | Data with poor DOI coverage        |
| DOI then Title+Year | High      | High      | General use (default)              |
| Fuzzy matching      | Lower     | Very High | Aggressive cleaning, manual review |

**Precision** = (True Duplicates Found) / (All Pairs Flagged as
Duplicates)

**Recall** = (True Duplicates Found) / (All Actual Duplicates)

The default `doi_title_year` method prioritizes precision while
maintaining reasonable recall by using DOI matching first, then falling
back to title+year only for records without DOI matches.

### Alternative: Fuzzy String Matching

For more aggressive duplicate detection, fuzzy string matching can
identify records with similar (but not identical) titles. This is
**not** built into
[`deduplicate_biblio()`](https://wep69.github.io/biblioIntegrator/reference/deduplicate_biblio.md)
because:

1.  It requires the optional `stringdist` package
2.  It has a higher false positive rate
3.  It requires careful threshold tuning
4.  Results typically need manual verification

However, we demonstrate how to implement it for advanced users:

``` r

if (has_stringdist) {
  # Example fuzzy matching (not part of deduplicate_biblio)
  library(stringdist)
  
  # Create a small example
  titles <- c(
    "Cover crops and soil aggregation",
    "Cover Crop Effects on Soil Aggregation",
    "Machine learning for crop yield",
    "Remote sensing of soybean nitrogen"
  )
  
  # Calculate pairwise string distances
  dist_matrix <- stringdistmatrix(titles, titles, method = "jw")
  
  # Find potential duplicates (distance < 0.15)
  threshold <- 0.15
  cat("Potential fuzzy duplicates (Jaro-Winkler < ", threshold, "):\n")
  for (i in 1:(length(titles) - 1)) {
    for (j in (i + 1):length(titles)) {
      if (dist_matrix[i, j] < threshold) {
        cat(sprintf("  [%.3f] '%s' ≈ '%s'\n", 
                    dist_matrix[i, j], titles[i], titles[j]))
      }
    }
  }
}
#> Potential fuzzy duplicates (Jaro-Winkler <  0.15 ):
```

**Recommendation**: Use the default `doi_title_year` method for most
analyses. Only consider fuzzy matching if you have evidence of
widespread title variations and are prepared to manually verify results.

## Step-by-Step Deduplication Workflow

Now that we understand the strategies, let us apply them systematically
to clean our contaminated corpus.

### Step 1: Initial Health Assessment

Always start with a health check to understand the scope of quality
issues:

``` r

# Load contaminated data (from Section 4)
raw <- example_biblio()

# Create duplicates
dup1 <- raw[1, ]  # Exact DOI duplicate
dup2 <- raw[3, ]  # Same title+year, different DOI
dup2$doi <- "10.9999/alternate.3"
dup3 <- raw[5, ]  # Similar title, no DOI
dup3$title <- "Cover Crop Effects on Soil Aggregation"
dup3$doi <- ""

contaminated <- rbind(raw, dup1, dup2, dup3)

# Introduce missing data
contaminated$title[2] <- ""
contaminated$year[4] <- NA
contaminated$doi[6] <- ""
contaminated$citations[8] <- -5

# Create biblio_project
x_dirty <- as_biblio_project(contaminated, source = "contaminated")

# Step 1: Assess quality
cat("=== STEP 1: Initial Health Assessment ===\n\n")
#> === STEP 1: Initial Health Assessment ===
health_before <- biblio_health(x_dirty)
print(health_before)
#>                  check n
#> 1        missing_title 1
#> 2         missing_year 1
#> 3          missing_doi 2
#> 4        duplicate_doi 1
#> 5 duplicate_title_year 2
#> 6   negative_citations 1

cat("\nSummary:\n")
#> 
#> Summary:
cat(sprintf("  Total records: %d\n", nrow(x_dirty$works)))
#>   Total records: 15
cat(sprintf("  Records with issues: %d\n", 
            sum(health_before$n[health_before$check != "negative_citations"])))
#>   Records with issues: 7
```

### Step 2: Apply Deduplication

``` r

# Step 2: Deduplicate using default method
cat("\n=== STEP 2: Deduplication ===\n\n")
#> 
#> === STEP 2: Deduplication ===

x_clean <- deduplicate_biblio(x_dirty)

cat("Deduplication results:\n")
#> Deduplication results:
cat(sprintf("  Records before: %d\n", nrow(x_dirty$works)))
#>   Records before: 15
cat(sprintf("  Records after:  %d\n", nrow(x_clean$works)))
#>   Records after:  14
cat(sprintf("  Records removed: %d\n", nrow(x_dirty$works) - nrow(x_clean$works)))
#>   Records removed: 1
```

### Step 3: Examine the Deduplication Log

The deduplication log records which records were removed and why:

``` r

# Step 3: Review deduplication log
cat("\n=== STEP 3: Deduplication Log ===\n\n")
#> 
#> === STEP 3: Deduplication Log ===

dedup_log <- attr(x_clean, "dedup_log")
cat("Removed records:\n")
#> Removed records:
print(dedup_log)
#>      work_id                                  title            doi
#> 13 W0001f7e3 Silicon and salinity tolerance in rice 10.1000/agri.1

cat("\nInterpretation:\n")
#> 
#> Interpretation:
cat("- Records are removed when they match an earlier record by DOI or title+year\n")
#> - Records are removed when they match an earlier record by DOI or title+year
cat("- The first occurrence is always kept\n")
#> - The first occurrence is always kept
cat("- The log preserves removed records for verification\n")
#> - The log preserves removed records for verification
```

### Step 4: Verify Post-Deduplication Health

``` r

# Step 4: Check health after deduplication
cat("\n=== STEP 4: Post-Deduplication Health ===\n\n")
#> 
#> === STEP 4: Post-Deduplication Health ===

health_after <- biblio_health(x_clean)
print(health_after)
#>                  check n
#> 1        missing_title 1
#> 2         missing_year 1
#> 3          missing_doi 2
#> 4        duplicate_doi 0
#> 5 duplicate_title_year 1
#> 6   negative_citations 1

cat("\nComparison:\n")
#> 
#> Comparison:
cat(sprintf("  Duplicate DOIs removed: %d\n", 
            health_before$n[health_before$check == "duplicate_doi"] - 
            health_after$n[health_after$check == "duplicate_doi"]))
#>   Duplicate DOIs removed: 1
cat(sprintf("  Duplicate title+year removed: %d\n",
            health_before$n[health_before$check == "duplicate_title_year"] - 
            health_after$n[health_after$check == "duplicate_title_year"]))
#>   Duplicate title+year removed: 1
```

### Step 5: Audit the Provenance

The provenance log records all transformations applied to the corpus:

``` r

# Step 5: Audit provenance
cat("\n=== STEP 5: Provenance Audit ===\n\n")
#> 
#> === STEP 5: Provenance Audit ===

audit_log <- audit_biblio(x_clean)
cat("Provenance log:\n")
#> Provenance log:
print(audit_log)
#>                    timestamp          operation                   details
#> 1 2026-08-23 13:29:41.248727  as_biblio_project source=contaminated; n=15
#> 2  2026-08-23 13:29:41.41303 deduplicate_biblio                 removed=1

cat("\nProvenance entries:\n")
#> 
#> Provenance entries:
cat(sprintf("  as_biblio_project: %d entries\n", 
            sum(audit_log$operation == "as_biblio_project")))
#>   as_biblio_project: 1 entries
cat(sprintf("  deduplicate_biblio: %d entries\n",
            sum(audit_log$operation == "deduplicate_biblio")))
#>   deduplicate_biblio: 1 entries
```

### Step 6: Compare Records Before and After

``` r

# Step 6: Verify record counts
cat("\n=== STEP 6: Record Comparison ===\n\n")
#> 
#> === STEP 6: Record Comparison ===

cat("Works table:\n")
#> Works table:
cat(sprintf("  Before: %d records\n", nrow(x_dirty$works)))
#>   Before: 15 records
cat(sprintf("  After:  %d records\n", nrow(x_clean$works)))
#>   After:  14 records
cat(sprintf("  Change: %d records removed\n", 
            nrow(x_dirty$works) - nrow(x_clean$works)))
#>   Change: 1 records removed

cat("\nAuthorships table:\n")
#> 
#> Authorships table:
cat(sprintf("  Before: %d links\n", nrow(x_dirty$authorships)))
#>   Before: 28 links
cat(sprintf("  After:  %d links\n", nrow(x_clean$authorships)))
#>   After:  28 links

cat("\nKeywords table:\n")
#> 
#> Keywords table:
cat(sprintf("  Before: %d links\n", nrow(x_dirty$keywords)))
#>   Before: 38 links
cat(sprintf("  After:  %d links\n", nrow(x_clean$keywords)))
#>   After:  38 links
```

### Step 7: Test Different Methods

Although the package currently implements only the `doi_title_year`
method, understanding the matching logic helps interpret results:

``` r

# Step 7: Demonstrate matching logic
cat("\n=== STEP 7: Matching Logic ===\n\n")
#> 
#> === STEP 7: Matching Logic ===

# Show how keys are constructed
works <- x_dirty$works
keys <- ifelse(
  nzchar(works$doi),
  paste0("doi:", works$doi),
  paste0("ty:", tolower(gsub("[^[:alnum:]]", "", works$title)), ":", works$year)
)

cat("Matching keys for first 6 records:\n")
#> Matching keys for first 6 records:
for (i in 1:min(6, nrow(works))) {
  cat(sprintf("  [%d] %s\n", i, substr(keys[i], 1, 60)))
}
#>   [1] doi:10.1000/agri.1
#>   [2] doi:10.1000/agri.2
#>   [3] doi:10.1000/agri.3
#>   [4] doi:10.1000/agri.4
#>   [5] doi:10.1000/agri.5
#>   [6] ty:machinelearningforcropyield:2023

# Identify duplicates by key
dup_keys <- keys[duplicated(keys)]
if (length(dup_keys) > 0) {
  cat("\nDuplicate keys found:\n")
  for (k in unique(dup_keys)) {
    count <- sum(keys == k)
    cat(sprintf("  '%s' appears %d times\n", substr(k, 1, 50), count))
  }
}
#> 
#> Duplicate keys found:
#>   'doi:10.1000/agri.1' appears 2 times
```

## Handling Specific Quality Issues

Beyond deduplication, several quality issues require attention. This
section addresses each systematically.

### Missing Titles

Missing titles prevent reliable deduplication and make records difficult
to verify:

``` r

# Identify records with missing titles
x <- as_biblio_project(example_biblio())
x$works$title[3] <- ""  # Simulate missing title

missing_title_idx <- which(!nzchar(trimws(x$works$title)))

if (length(missing_title_idx) > 0) {
  cat("Records with missing titles:\n")
  print(x$works[missing_title_idx, c("work_id", "year", "doi", "source")])
  
  cat("\nOptions:\n")
  cat("1. Look up titles using DOI (if available)\n")
  cat("2. Look up titles using metadata APIs (OpenAlex, CrossRef)\n")
  cat("3. Exclude records with missing titles\n")
  cat("4. Flag for manual review\n")
}
#> Records with missing titles:
#>     work_id year            doi         source
#> 3 W0001b6e0 2020 10.1000/agri.3 Remote Sensing
#> 
#> Options:
#> 1. Look up titles using DOI (if available)
#> 2. Look up titles using metadata APIs (OpenAlex, CrossRef)
#> 3. Exclude records with missing titles
#> 4. Flag for manual review
```

### Missing Years

Missing years affect temporal analyses:

``` r

# Identify records with missing years
x$works$year[5] <- NA  # Simulate missing year

missing_year_idx <- which(is.na(x$works$year))

if (length(missing_year_idx) > 0) {
  cat("Records with missing years:\n")
  print(x$works[missing_year_idx, c("work_id", "title", "doi", "source")])
  
  cat("\nOptions:\n")
  cat("1. Look up year using DOI (if available)\n")
  cat("2. Infer year from citation patterns\n")
  cat("3. Assign to 'unknown' period and exclude from temporal analysis\n")
  cat("4. Manual correction\n")
}
#> Records with missing years:
#>     work_id                            title            doi       source
#> 5 W0001932e Cover crops and soil aggregation 10.1000/agri.5 Soil Science
#> 
#> Options:
#> 1. Look up year using DOI (if available)
#> 2. Infer year from citation patterns
#> 3. Assign to 'unknown' period and exclude from temporal analysis
#> 4. Manual correction
```

### Missing DOIs

Records without DOIs require alternative identification strategies:

``` r

# Calculate DOI coverage
doi_coverage <- sum(nzchar(x$works$doi)) / nrow(x$works)
cat(sprintf("DOI coverage: %.1f%%\n", 100 * doi_coverage))
#> DOI coverage: 100.0%

if (doi_coverage < 0.9) {
  cat("\nWarning: Low DOI coverage may affect deduplication quality.\n")
  cat("Consider:\n")
  cat("1. Re-exporting with DOI fields included\n")
  cat("2. Using title+year matching (default)\n")
  cat("3. Manual DOI lookup for high-impact records\n")
}
```

### Inconsistent DOIs

DOI format inconsistencies can prevent matching:

``` r

# Demonstrate DOI normalization
example_dois <- c(
  "10.1000/AGRI.1",
  "10.1000/agri.1",
  "https://doi.org/10.1000/agri.1",
  "http://dx.doi.org/10.1000/agri.1",
  "doi:10.1000/agri.1",
  "DOI:10.1000/agri.1"
)

# Show normalization
cat("DOI normalization examples:\n")
#> DOI normalization examples:
for (doi in example_dois) {
  normalized <- tolower(trimws(as.character(doi)))
  normalized <- sub("^https?://(dx\\.)?doi\\.org/", "", normalized)
  normalized <- sub("^doi:\\s*", "", normalized)
  cat(sprintf("  %-45s → %s\n", doi, normalized))
}
#>   10.1000/AGRI.1                                → 10.1000/agri.1
#>   10.1000/agri.1                                → 10.1000/agri.1
#>   https://doi.org/10.1000/agri.1                → 10.1000/agri.1
#>   http://dx.doi.org/10.1000/agri.1              → 10.1000/agri.1
#>   doi:10.1000/agri.1                            → 10.1000/agri.1
#>   DOI:10.1000/agri.1                            → 10.1000/agri.1
```

The `biblioIntegrator` package automatically normalizes DOIs during
import, but if you are merging data from multiple sources, verify that
normalization was applied consistently.

### Negative Citation Counts

Negative citations are data errors that should be corrected:

``` r

# Identify negative citations
x$works$cited_by_count[2] <- -10  # Simulate error

negative_idx <- which(x$works$cited_by_count < 0)

if (length(negative_idx) > 0) {
  cat("Records with negative citations:\n")
  print(x$works[negative_idx, c("work_id", "title", "year", "cited_by_count")])
  
  # Options for handling
  cat("\nOptions:\n")
  cat("1. Set to 0 (conservative)\n")
  cat("2. Set to NA and exclude from citation analysis\n")
  cat("3. Look up correct value and correct\n")
  
  # Example correction
  x$works$cited_by_count[negative_idx] <- 0
  cat("\nCorrected by setting to 0.\n")
}
#> Records with negative citations:
#>     work_id                         title year cited_by_count
#> 2 W000160f5 Soil carbon under cover crops 2019            -10
#> 
#> Options:
#> 1. Set to 0 (conservative)
#> 2. Set to NA and exclude from citation analysis
#> 3. Look up correct value and correct
#> 
#> Corrected by setting to 0.
```

## The Audit Function

The
[`audit_biblio()`](https://wep69.github.io/biblioIntegrator/reference/audit_biblio.md)
function provides access to the provenance log, which records all
transformations applied to a `biblio_project`. This is essential for
reproducibility and transparency in bibliometric analysis.

### Understanding Provenance

Every `biblio_project` maintains a provenance log that records:

1.  **Timestamp**: When the operation was performed
2.  **Operation**: The name of the function called
3.  **Details**: Key parameters and outcomes

``` r

# Create a project and apply transformations
x <- as_biblio_project(example_biblio(), source = "audit demo")

# Apply deduplication
x <- deduplicate_biblio(x)

# Access provenance
audit_log <- audit_biblio(x)
cat("Provenance log:\n")
#> Provenance log:
print(audit_log)
#>                    timestamp          operation                 details
#> 1 2026-08-23 13:29:43.214826  as_biblio_project source=audit demo; n=12
#> 2 2026-08-23 13:29:43.216047 deduplicate_biblio               removed=0
```

### Interpreting Provenance Entries

Each row in the provenance log represents one transformation:

``` r

# Interpret each entry
cat("Provenance interpretation:\n\n")
#> Provenance interpretation:

for (i in seq_len(nrow(audit_log))) {
  entry <- audit_log[i, ]
  cat(sprintf("Entry %d [%s]\n", i, entry$timestamp))
  cat(sprintf("  Operation: %s\n", entry$operation))
  cat(sprintf("  Details: %s\n", entry$details))
  cat("\n")
}
#> Entry 1 [2026-08-23 13:29:43.214826]
#>   Operation: as_biblio_project
#>   Details: source=audit demo; n=12
#> 
#> Entry 2 [2026-08-23 13:29:43.216047]
#>   Operation: deduplicate_biblio
#>   Details: removed=0
```

### Checking Referential Integrity

After deduplication, verify that all linkages are consistent:

``` r

# Check referential integrity
cat("Referential integrity check:\n\n")
#> Referential integrity check:

# All work_ids in authorships should exist in works
orphan_authorships <- !x$authorships$work_id %in% x$works$work_id
cat(sprintf("Orphan authorship links: %d\n", sum(orphan_authorships)))
#> Orphan authorship links: 0

# All work_ids in keywords should exist in works
orphan_keywords <- !x$keywords$work_id %in% x$works$work_id
cat(sprintf("Orphan keyword links: %d\n", sum(orphan_keywords)))
#> Orphan keyword links: 0

# All author_ids in authorships should exist in authors
orphan_authors <- !x$authorships$author_id %in% x$authors$author_id
cat(sprintf("Orphan author references: %d\n", sum(orphan_authors)))
#> Orphan author references: 0
```

**Note**: The
[`deduplicate_biblio()`](https://wep69.github.io/biblioIntegrator/reference/deduplicate_biblio.md)
function automatically removes associated authorship and keyword links
when a work is removed. Orphan records should be zero after proper
deduplication.

### Identifying Orphan Records

Orphan records are linkages that reference non-existent entities:

``` r

# Demonstrate orphan detection
cat("\nOrphan detection:\n\n")
#> 
#> Orphan detection:

# Create a scenario with orphans for illustration
x_demo <- as_biblio_project(example_biblio())

# Manually create orphan (not recommended in practice)
orphan_link <- data.frame(
  work_id = "nonexistent_work_123",
  author_id = "A00000001",
  stringsAsFactors = FALSE
)
x_demo$authorships <- rbind(x_demo$authorships, orphan_link)

# Detect orphans
orphan_check <- !x_demo$authorships$work_id %in% x_demo$works$work_id
if (any(orphan_check)) {
  cat("Found orphan authorship links:\n")
  print(x_demo$authorships[orphan_check, ])
  
  # Clean up
  x_demo$authorships <- x_demo$authorships[!orphan_check, ]
  cat("\nOrphans removed.\n")
}
#> Found orphan authorship links:
#>                work_id author_id
#> 1 nonexistent_work_123 A00000001
#> 
#> Orphans removed.
```

### Provenance for Reproducibility

The audit trail enables reproducible analysis:

``` r

# Example: Complete audit trail for a cleaning workflow
x <- as_biblio_project(example_biblio(), source = "reproducibility demo")
x <- deduplicate_biblio(x)

# Export the audit trail
audit_df <- audit_biblio(x)

# Save for documentation (example)
temp_file <- tempfile(fileext = ".csv")
write.csv(audit_df, temp_file, row.names = FALSE)

cat("Audit trail saved to:", temp_file, "\n")
#> Audit trail saved to: /tmp/RtmpYtwfnz/file20ea32bbf884.csv
cat("\nAudit trail contents:\n")
#> 
#> Audit trail contents:
print(audit_df)
#>                    timestamp          operation
#> 1 2026-08-23 13:29:43.887262  as_biblio_project
#> 2 2026-08-23 13:29:43.888303 deduplicate_biblio
#>                             details
#> 1 source=reproducibility demo; n=12
#> 2                         removed=0

# Verify all steps are recorded
cat("\nVerification:\n")
#> 
#> Verification:
cat(sprintf("Total operations recorded: %d\n", nrow(audit_df)))
#> Total operations recorded: 2
cat(sprintf("Operations: %s\n", paste(audit_df$operation, collapse = " → ")))
#> Operations: as_biblio_project → deduplicate_biblio
```

## Comparing Deduplication Results

Understanding how different deduplication approaches affect results is
essential for methodological transparency.

### Setting Up Comparisons

``` r

# Create a dataset with known duplicates
raw <- example_biblio()

# Add exact duplicates
dup_exact <- raw[c(1, 3, 5), ]

# Add title+year duplicates (different DOI)
dup_ty <- raw[c(2, 4), ]
dup_ty$doi <- c("10.9999/alt.2", "10.9999/alt.4")

# Add similar titles (fuzzy matches)
dup_fuzzy <- raw[c(6, 8), ]
dup_fuzzy$title <- c(
  "Machine Learning Applications for Crop Yield Prediction",
  "Soil Microbiome Dynamics Under Crop Rotation Systems"
)

# Combine all
full_data <- rbind(raw, dup_exact, dup_ty, dup_fuzzy)

cat("Original records:", nrow(raw), "\n")
#> Original records: 12
cat("Total records:", nrow(full_data), "\n")
#> Total records: 19
cat("Expected duplicates:", nrow(full_data) - nrow(raw), "\n")
#> Expected duplicates: 7
```

### Applying Default Deduplication

``` r

# Apply default deduplication
x_original <- as_biblio_project(full_data, source = "comparison")
x_dedup <- deduplicate_biblio(x_original)

# Analyze results
cat("\nDefault deduplication (doi_title_year):\n")
#> 
#> Default deduplication (doi_title_year):
cat(sprintf("  Input records: %d\n", nrow(x_original$works)))
#>   Input records: 19
cat(sprintf("  Output records: %d\n", nrow(x_dedup$works)))
#>   Output records: 14
cat(sprintf("  Removed: %d (%.1f%%)\n", 
            nrow(x_original$works) - nrow(x_dedup$works),
            100 * (nrow(x_original$works) - nrow(x_dedup$works)) / nrow(x_original$works)))
#>   Removed: 5 (26.3%)

# Show what was removed
dedup_log <- attr(x_dedup, "dedup_log")
cat("\nRemoved records:\n")
#> 
#> Removed records:
print(dedup_log)
#>      work_id                                                   title
#> 13 W0001f7e3                  Silicon and salinity tolerance in rice
#> 14 W0001b6e0                      Remote sensing of soybean nitrogen
#> 15 W0001932e                        Cover crops and soil aggregation
#> 18 W0003711f Machine Learning Applications for Crop Yield Prediction
#> 19 W00032cdf    Soil Microbiome Dynamics Under Crop Rotation Systems
#>               doi
#> 13 10.1000/agri.1
#> 14 10.1000/agri.3
#> 15 10.1000/agri.5
#> 18 10.1000/agri.6
#> 19 10.1000/agri.8
```

### Analyzing Matching Behavior

``` r

# Understand why records were removed
cat("\nMatching analysis:\n\n")
#> 
#> Matching analysis:

# Reconstruct matching keys
works <- x_original$works
keys <- ifelse(
  nzchar(works$doi),
  paste0("doi:", works$doi),
  paste0("ty:", tolower(gsub("[^[:alnum:]]", "", works$title)), ":", works$year)
)

# Count duplicates by key
key_table <- table(keys)
dup_keys <- key_table[key_table > 1]

cat("Duplicate key groups:\n")
#> Duplicate key groups:
for (i in seq_along(dup_keys)) {
  key_name <- names(dup_keys)[i]
  count <- dup_keys[i]
  cat(sprintf("  %s: %d records\n", 
              substr(key_name, 1, 60), count))
}
#>   doi:10.1000/agri.1: 2 records
#>   doi:10.1000/agri.3: 2 records
#>   doi:10.1000/agri.5: 2 records
#>   doi:10.1000/agri.6: 2 records
#>   doi:10.1000/agri.8: 2 records

# Categorize by matching strategy
doi_matches <- sum(grepl("^doi:", keys[duplicated(keys)]))
ty_matches <- sum(grepl("^ty:", keys[duplicated(keys)]))

cat(sprintf("\nDOI matches: %d\n", doi_matches))
#> 
#> DOI matches: 5
cat(sprintf("Title+year matches: %d\n", ty_matches))
#> Title+year matches: 0
```

### Effect on Downstream Analysis

Different deduplication approaches can significantly impact results:

``` r

# Compare corpus statistics before and after
cat("Impact comparison:\n\n")
#> Impact comparison:

# Original vs deduplicated
metrics_orig <- nrow(x_original$works)
metrics_dedup <- nrow(x_dedup$works)

cat("Record counts:\n")
#> Record counts:
cat(sprintf("  Original:            %d works\n", metrics_orig))
#>   Original:            19 works
cat(sprintf("  After deduplication: %d works\n", metrics_dedup))
#>   After deduplication: 14 works
cat(sprintf("  Reduction:           %.1f%%\n", 
            100 * (metrics_orig - metrics_dedup) / metrics_orig))
#>   Reduction:           26.3%

# Author counts
authors_orig <- nrow(x_original$authors)
authors_dedup <- nrow(x_dedup$authors)
cat(sprintf("\nAuthors:\n"))
#> 
#> Authors:
cat(sprintf("  Original:            %d unique authors\n", authors_orig))
#>   Original:            7 unique authors
cat(sprintf("  After deduplication: %d unique authors\n", authors_dedup))
#>   After deduplication: 7 unique authors

# Citation totals
citations_orig <- sum(x_original$works$cited_by_count, na.rm = TRUE)
citations_dedup <- sum(x_dedup$works$cited_by_count, na.rm = TRUE)
cat(sprintf("\nTotal citations:\n"))
#> 
#> Total citations:
cat(sprintf("  Original:            %d\n", citations_orig))
#>   Original:            511
cat(sprintf("  After deduplication: %d\n", citations_dedup))
#>   After deduplication: 375
```

## Common Mistakes

This section documents frequent errors in bibliometric data cleaning and
how to avoid them.

### Mistake 1: Deduplicating Before Harmonization

**Problem**: Applying deduplication to raw, unharmonized data.

**Why it’s wrong**: Different databases use different field names,
formats, and conventions. Deduplication before harmonization will miss
duplicates that look different in raw form.

**Solution**: Always harmonize first using
[`as_biblio_project()`](https://wep69.github.io/biblioIntegrator/reference/as_biblio_project.md).

``` r

# WRONG: Deduplicating raw data
cat("WRONG approach:\n")
#> WRONG approach:
cat("  raw_data <- read.csv('scopus_export.csv')\n")
#>   raw_data <- read.csv('scopus_export.csv')
cat("  clean_data <- deduplicate_biblio(raw_data)  # Error!\n\n")
#>   clean_data <- deduplicate_biblio(raw_data)  # Error!

# CORRECT: Harmonize first, then deduplicate
cat("CORRECT approach:\n")
#> CORRECT approach:
cat("  raw_data <- read.csv('scopus_export.csv')\n")
#>   raw_data <- read.csv('scopus_export.csv')
cat("  x <- as_biblio_project(raw_data, source = 'scopus')\n")
#>   x <- as_biblio_project(raw_data, source = 'scopus')
cat("  x_clean <- deduplicate_biblio(x)\n")
#>   x_clean <- deduplicate_biblio(x)

# Demonstrate
cat("\nPractical example:\n")
#> 
#> Practical example:
raw <- example_biblio()
x <- as_biblio_project(raw, source = "example")
x_clean <- deduplicate_biblio(x)
cat(sprintf("  Harmonized: %d records\n", nrow(x$works)))
#>   Harmonized: 12 records
cat(sprintf("  Deduplicated: %d records\n", nrow(x_clean$works)))
#>   Deduplicated: 12 records
```

### Mistake 2: Using Only One Deduplication Method

**Problem**: Relying solely on DOI matching or only on title matching.

**Why it’s wrong**: Each method has different strengths:

- DOI matching misses duplicates without DOIs
- Title matching misses duplicates with title variations
- Neither catches all duplicates alone

**Solution**: Use the hierarchical `doi_title_year` method (default).

``` r

# Show why multiple methods are needed
cat("Method comparison:\n\n")
#> Method comparison:

# Create test data with different duplicate types
test_data <- example_biblio()
dup_doi <- test_data[1, ]  # Will match by DOI
dup_title <- test_data[2, ]  # Will match by title+year
dup_title$doi <- ""  # No DOI, must use title+year

combined <- rbind(test_data, dup_doi, dup_title)
x_test <- as_biblio_project(combined, source = "method test")

# Show matching keys
works <- x_test$works
keys <- ifelse(
  nzchar(works$doi),
  paste0("doi:", works$doi),
  paste0("ty:", tolower(gsub("[^[:alnum:]]", "", works$title)), ":", works$year)
)

cat("Matching keys:\n")
#> Matching keys:
for (i in 1:min(5, nrow(works))) {
  cat(sprintf("  Record %d: %s\n", i, substr(keys[i], 1, 50)))
}
#>   Record 1: doi:10.1000/agri.1
#>   Record 2: doi:10.1000/agri.2
#>   Record 3: doi:10.1000/agri.3
#>   Record 4: doi:10.1000/agri.4
#>   Record 5: doi:10.1000/agri.5

cat("\nThe doi_title_year method handles both cases automatically.\n")
#> 
#> The doi_title_year method handles both cases automatically.
```

### Mistake 3: Ignoring False Positives in Fuzzy Matching

**Problem**: Applying aggressive fuzzy matching without manual
verification.

**Why it’s wrong**: Legitimate publications can have similar titles:

- Review articles on the same topic
- Sequel papers (“Part I”, “Part II”)
- Different papers with common keywords

**Solution**: If using fuzzy matching (outside the package), always
verify a sample.

``` r

# Example of legitimate similar titles
similar_titles <- c(
  "Silicon and salinity tolerance in rice",
  "Silicon and salinity tolerance in rice: A review",
  "Silicon and salinity tolerance in rice: Response mechanisms"
)

cat("Legitimate similar titles:\n")
#> Legitimate similar titles:
for (t in similar_titles) {
  cat(sprintf("  '%s'\n", t))
}
#>   'Silicon and salinity tolerance in rice'
#>   'Silicon and salinity tolerance in rice: A review'
#>   'Silicon and salinity tolerance in rice: Response mechanisms'

cat("\nThese are DIFFERENT publications despite similar titles.\n")
#> 
#> These are DIFFERENT publications despite similar titles.
cat("Fuzzy matching could incorrectly merge them.\n\n")
#> Fuzzy matching could incorrectly merge them.
cat("Best practice:\n")
#> Best practice:
cat("  1. Use default doi_title_year method for automatic cleaning\n")
#>   1. Use default doi_title_year method for automatic cleaning
cat("  2. If adding fuzzy matching, require manual review\n")
#>   2. If adding fuzzy matching, require manual review
cat("  3. Check a random sample of 5-10% of fuzzy matches\n")
#>   3. Check a random sample of 5-10% of fuzzy matches
```

### Mistake 4: Not Recording Deduplication in Provenance

**Problem**: Applying deduplication without documenting what was
changed.

**Why it’s wrong**: Without provenance, analyses cannot be reproduced or
audited.

**Solution**: Always check
[`audit_biblio()`](https://wep69.github.io/biblioIntegrator/reference/audit_biblio.md)
after deduplication.

``` r

# Demonstrate proper provenance tracking
x <- as_biblio_project(example_biblio(), source = "provenance demo")
x <- deduplicate_biblio(x)

# Check provenance
audit_log <- audit_biblio(x)

cat("Provenance after deduplication:\n")
#> Provenance after deduplication:
print(audit_log)
#>                    timestamp          operation                      details
#> 1 2026-08-23 13:29:45.285139  as_biblio_project source=provenance demo; n=12
#> 2 2026-08-23 13:29:45.286178 deduplicate_biblio                    removed=0

cat("\nThis log records:\n")
#> 
#> This log records:
cat("  - When deduplication was performed\n")
#>   - When deduplication was performed
cat("  - How many records were removed\n")
#>   - How many records were removed
cat("  - The method used\n")
#>   - The method used

# Verify provenance has deduplication recorded
has_dedup <- any(audit_log$operation == "deduplicate_biblio")
cat(sprintf("\nDeduplication recorded: %s\n", has_dedup))
#> 
#> Deduplication recorded: TRUE
```

### Mistake 5: Deduplicating Without Checking First

**Problem**: Applying deduplication without understanding what will be
removed.

**Why it’s wrong**: You might remove legitimate records or miss
important duplicates.

**Solution**: Always run
[`biblio_health()`](https://wep69.github.io/biblioIntegrator/reference/biblio_health.md)
first and examine the issues.

``` r

# Correct workflow
cat("Correct deduplication workflow:\n\n")
#> Correct deduplication workflow:
cat("1. Run biblio_health() to identify issues\n")
#> 1. Run biblio_health() to identify issues
cat("2. Examine specific problems (missing data, duplicates)\n")
#> 2. Examine specific problems (missing data, duplicates)
cat("3. Decide on strategy (fix vs. exclude)\n")
#> 3. Decide on strategy (fix vs. exclude)
cat("4. Apply deduplication\n")
#> 4. Apply deduplication
cat("5. Verify results with biblio_health() again\n")
#> 5. Verify results with biblio_health() again
cat("6. Check audit_biblio() for documentation\n")
#> 6. Check audit_biblio() for documentation

# Demonstrate
x <- as_biblio_project(example_biblio(), source = "workflow demo")

cat("\n=== Step 1: Health check ===\n")
#> 
#> === Step 1: Health check ===
health <- biblio_health(x)
print(health)
#>                  check n
#> 1        missing_title 0
#> 2         missing_year 0
#> 3          missing_doi 0
#> 4        duplicate_doi 0
#> 5 duplicate_title_year 0
#> 6   negative_citations 0

cat("\n=== Step 2: Examine issues ===\n")
#> 
#> === Step 2: Examine issues ===
problems <- subset(health, n > 0)
if (nrow(problems) > 0) {
  cat("Issues found:\n")
  print(problems)
} else {
  cat("No issues found.\n")
}
#> No issues found.

cat("\n=== Step 4: Deduplicate ===\n")
#> 
#> === Step 4: Deduplicate ===
x_clean <- deduplicate_biblio(x)

cat("\n=== Step 5: Verify ===\n")
#> 
#> === Step 5: Verify ===
health_after <- biblio_health(x_clean)
print(health_after)
#>                  check n
#> 1        missing_title 0
#> 2         missing_year 0
#> 3          missing_doi 0
#> 4        duplicate_doi 0
#> 5 duplicate_title_year 0
#> 6   negative_citations 0

cat("\n=== Step 6: Audit ===\n")
#> 
#> === Step 6: Audit ===
audit <- audit_biblio(x_clean)
cat(sprintf("Operations recorded: %d\n", nrow(audit)))
#> Operations recorded: 2
```

## Advanced Topics

This section covers advanced techniques for users with specific needs.

### Custom Deduplication Keys

While
[`deduplicate_biblio()`](https://wep69.github.io/biblioIntegrator/reference/deduplicate_biblio.md)
uses a fixed key strategy, you can implement custom approaches:

``` r

# Create custom deduplication keys
x <- as_biblio_project(example_biblio(), source = "custom keys demo")
works <- x$works

# Strategy 1: Author + Year + First Words of Title
custom_key_1 <- paste(
  substr(tolower(works$title), 1, 30),  # First 30 chars of title
  works$year,
  sep = "|"
)

# Strategy 2: DOI (normalized) or Title Hash + Year
custom_key_2 <- ifelse(
  nzchar(works$doi),
  works$doi,
  paste(
    substr(gsub("[^a-z]", "", tolower(works$title)), 1, 20),
    works$year,
    sep = "|"
  )
)

cat("Custom key examples:\n")
#> Custom key examples:
for (i in 1:min(3, nrow(works))) {
  cat(sprintf("Record %d:\n", i))
  cat(sprintf("  Strategy 1: %s\n", substr(custom_key_1[i], 1, 50)))
  cat(sprintf("  Strategy 2: %s\n", substr(custom_key_2[i], 1, 50)))
}
#> Record 1:
#>   Strategy 1: silicon and salinity tolerance|2018
#>   Strategy 2: 10.1000/agri.1
#> Record 2:
#>   Strategy 1: soil carbon under cover crops|2019
#>   Strategy 2: 10.1000/agri.2
#> Record 3:
#>   Strategy 1: remote sensing of soybean nitr|2020
#>   Strategy 2: 10.1000/agri.3
```

### Handling Large Corpora

For very large corpora, deduplication can be computationally expensive:

``` r

# Strategies for large corpora (pseudocode)
cat("Large corpus strategies:\n\n")
cat("1. Index on DOI first (O(n) lookup)\n")
cat("2. Use hash tables for title matching\n")
cat("3. Parallelize fuzzy matching (if needed)\n")
cat("4. Process in batches by year range\n")
cat("5. Use the Arrow backend for memory efficiency\n")

# Demonstrate batch processing concept
cat("\nBatch processing example (conceptual):\n")
cat("  years <- sort(unique(works$year))\n")
cat("  results <- lapply(years, function(y) {\n")
cat("    batch <- works[works$year == y, ]\n")
cat("    deduplicate_batch(batch)\n")
cat("  })\n")
cat("  final <- do.call(rbind, results)\n")
```

### Integrating with External Tools

The deduplication log can be exported for external verification:

``` r

# Export deduplication log for external review
x <- as_biblio_project(example_biblio(), source = "export demo")
x <- deduplicate_biblio(x)

# Get the log
dedup_log <- attr(x, "dedup_log")

if (nrow(dedup_log) > 0) {
  # Export to CSV for manual review
  temp_file <- tempfile(fileext = ".csv")
  write.csv(dedup_log, temp_file, row.names = FALSE)
  
  cat("Deduplication log exported to:", temp_file, "\n")
  cat("\nLog contents:\n")
  print(dedup_log)
  
  cat("\nThis log can be:\n")
  cat("  1. Reviewed in Excel/Calc\n")
  cat("  2. Compared with external deduplication tools\n")
  cat("  3. Included in supplementary materials\n")
  cat("  4. Used for inter-rater reliability checks\n")
} else {
  cat("No duplicates found - log is empty.\n")
}
#> No duplicates found - log is empty.
```

### Quality Metrics

Calculate quality metrics to assess corpus health:

``` r

# Calculate quality metrics
x <- as_biblio_project(example_biblio(), source = "metrics demo")

# Metadata completeness
total_records <- nrow(x$works)
metrics <- data.frame(
  metric = c(
    "Title completeness",
    "Year completeness", 
    "DOI completeness",
    "Author completeness",
    "Keyword completeness"
  ),
  count = c(
    sum(nzchar(trimws(x$works$title))),
    sum(!is.na(x$works$year)),
    sum(nzchar(x$works$doi)),
    nrow(x$authorships[x$authorships$work_id %in% x$works$work_id, ]),
    nrow(x$keywords[x$keywords$work_id %in% x$works$work_id, ])
  ),
  stringsAsFactors = FALSE
)

# Calculate percentages
metrics$percent <- 100 * metrics$count / total_records

cat("Metadata completeness:\n")
#> Metadata completeness:
print(metrics)
#>                 metric count  percent
#> 1   Title completeness    12 100.0000
#> 2    Year completeness    12 100.0000
#> 3     DOI completeness    12 100.0000
#> 4  Author completeness    24 200.0000
#> 5 Keyword completeness    32 266.6667
cat(sprintf("\nOverall completeness: %.1f%%\n", mean(metrics$percent)))
#> 
#> Overall completeness: 153.3%
```

## Worked Example with Realistic Data

This section provides a complete, realistic workflow using the example
corpus with simulated quality issues.

### Scenario Description

We simulate a common scenario: merging data from two database exports
(Web of Science and Scopus) for a bibliometric study of agronomy
research.

``` r

# Simulate merging two database exports
cat("Scenario: Merging WoS and Scopus exports\n\n")
#> Scenario: Merging WoS and Scopus exports

# Load base data
base_data <- example_biblio()

# Simulate WoS export (first 8 records, some duplicates)
wos_data <- base_data[1:8, ]
wos_data$source <- "Web of Science"

# Simulate Scopus export (records 5-12, with duplicates)
scopus_data <- base_data[5:12, ]
scopus_data$source <- "Scopus"

# Add realistic quality issues
# 1. Slightly different DOI format in Scopus
scopus_data$doi <- paste0("https://doi.org/", scopus_data$doi)

# 2. Missing DOIs for older records in Scopus
scopus_data$doi[1:2] <- ""

# 3. Title variation in one record
scopus_data$title[3] <- toupper(scopus_data$title[3])

# 4. Missing year in one record
scopus_data$year[4] <- NA

# 5. Duplicate entry in Scopus
scopus_data <- rbind(scopus_data, scopus_data[1, ])

# Merge exports
merged_data <- rbind(wos_data, scopus_data)
cat("Records after merge:\n")
#> Records after merge:
cat(sprintf("  WoS: %d records\n", nrow(wos_data)))
#>   WoS: 8 records
cat(sprintf("  Scopus: %d records\n", nrow(scopus_data)))
#>   Scopus: 9 records
cat(sprintf("  Total: %d records\n", nrow(merged_data)))
#>   Total: 17 records
cat(sprintf("  Expected unique: ~12 records\n"))
#>   Expected unique: ~12 records
```

### Step 1: Harmonize the Merged Data

``` r

# Step 1: Harmonize
cat("\n=== Step 1: Harmonization ===\n\n")
#> 
#> === Step 1: Harmonization ===

x_merged <- as_biblio_project(merged_data, source = "WoS+Scopus merge")
cat("Harmonization results:\n")
#> Harmonization results:
cat(sprintf("  Works: %d records\n", nrow(x_merged$works)))
#>   Works: 17 records
cat(sprintf("  Authors: %d unique\n", nrow(x_merged$authors)))
#>   Authors: 7 unique
cat(sprintf("  Keywords: %d links\n", nrow(x_merged$keywords)))
#>   Keywords: 41 links
```

### Step 2: Initial Health Assessment

``` r

# Step 2: Health assessment
cat("\n=== Step 2: Health Assessment ===\n\n")
#> 
#> === Step 2: Health Assessment ===

health_initial <- biblio_health(x_merged)
print(health_initial)
#>                  check n
#> 1        missing_title 0
#> 2         missing_year 1
#> 3          missing_doi 3
#> 4        duplicate_doi 2
#> 5 duplicate_title_year 4
#> 6   negative_citations 0

# Identify critical issues
critical <- subset(health_initial, n > 0 & check %in% 
                     c("duplicate_doi", "duplicate_title_year"))
if (nrow(critical) > 0) {
  cat("\nCritical issues requiring action:\n")
  print(critical)
}
#> 
#> Critical issues requiring action:
#>                  check n
#> 4        duplicate_doi 2
#> 5 duplicate_title_year 4
```

### Step 3: Deduplication

``` r

# Step 3: Deduplication
cat("\n=== Step 3: Deduplication ===\n\n")
#> 
#> === Step 3: Deduplication ===

x_clean <- deduplicate_biblio(x_merged)

cat("Deduplication results:\n")
#> Deduplication results:
cat(sprintf("  Input records: %d\n", nrow(x_merged$works)))
#>   Input records: 17
cat(sprintf("  Output records: %d\n", nrow(x_clean$works)))
#>   Output records: 14
cat(sprintf("  Records removed: %d\n", 
            nrow(x_merged$works) - nrow(x_clean$works)))
#>   Records removed: 3
cat(sprintf("  Reduction: %.1f%%\n", 
            100 * (nrow(x_merged$works) - nrow(x_clean$works)) / nrow(x_merged$works)))
#>   Reduction: 17.6%

# Show what was removed
dedup_log <- attr(x_clean, "dedup_log")
if (nrow(dedup_log) > 0) {
  cat("\nRemoved records:\n")
  print(dedup_log)
}
#> 
#> Removed records:
#>      work_id                            title            doi
#> 11 W00011a29      SALINITY RESPONSES OF WHEAT 10.1000/agri.7
#> 12 W000167dc   Soil microbiome under rotation 10.1000/agri.8
#> 17 W0000f03c Cover crops and soil aggregation
```

### Step 4: Post-Deduplication Verification

``` r

# Step 4: Verification
cat("\n=== Step 4: Verification ===\n\n")
#> 
#> === Step 4: Verification ===

# Health check after deduplication
health_final <- biblio_health(x_clean)
cat("Post-deduplication health:\n")
#> Post-deduplication health:
print(health_final)
#>                  check n
#> 1        missing_title 0
#> 2         missing_year 0
#> 3          missing_doi 2
#> 4        duplicate_doi 0
#> 5 duplicate_title_year 2
#> 6   negative_citations 0

# Verify no duplicates remain
remaining_dups <- health_final$n[health_final$check == "duplicate_doi"] +
                  health_final$n[health_final$check == "duplicate_title_year"]
cat(sprintf("\nRemaining duplicates: %d\n", remaining_dups))
#> 
#> Remaining duplicates: 2
cat(sprintf("Status: %s\n", ifelse(remaining_dups == 0, "CLEAN", "NEEDS ATTENTION")))
#> Status: NEEDS ATTENTION

# Check referential integrity
orphan_auth <- !x_clean$authorships$work_id %in% x_clean$works$work_id
orphan_kw <- !x_clean$keywords$work_id %in% x_clean$works$work_id
cat(sprintf("\nReferential integrity:\n"))
#> 
#> Referential integrity:
cat(sprintf("  Orphan authorships: %d\n", sum(orphan_auth)))
#>   Orphan authorships: 0
cat(sprintf("  Orphan keywords: %d\n", sum(orphan_kw)))
#>   Orphan keywords: 0
```

### Step 5: Provenance Documentation

``` r

# Step 5: Documentation
cat("\n=== Step 5: Provenance Documentation ===\n\n")
#> 
#> === Step 5: Provenance Documentation ===

audit_log <- audit_biblio(x_clean)
cat("Complete audit trail:\n")
#> Complete audit trail:
print(audit_log)
#>                    timestamp          operation                       details
#> 1 2026-08-23 13:29:46.503851  as_biblio_project source=WoS+Scopus merge; n=17
#> 2 2026-08-23 13:29:46.827374 deduplicate_biblio                     removed=3

cat("\nSummary of transformations:\n")
#> 
#> Summary of transformations:
for (op in unique(audit_log$operation)) {
  count <- sum(audit_log$operation == op)
  cat(sprintf("  %s: %d operation(s)\n", op, count))
}
#>   as_biblio_project: 1 operation(s)
#>   deduplicate_biblio: 1 operation(s)
```

### Step 6: Prepare for Analysis

``` r

# Step 6: Ready for analysis
cat("\n=== Step 6: Corpus Ready for Analysis ===\n\n")
#> 
#> === Step 6: Corpus Ready for Analysis ===

cat("Final corpus statistics:\n")
#> Final corpus statistics:
cat(sprintf("  Works: %d\n", nrow(x_clean$works)))
#>   Works: 14
cat(sprintf("  Year range: %d-%d\n", 
            min(x_clean$works$year, na.rm = TRUE),
            max(x_clean$works$year, na.rm = TRUE)))
#>   Year range: 2017-2025
cat(sprintf("  Sources: %d journals\n", length(unique(x_clean$works$source))))
#>   Sources: 2 journals
cat(sprintf("  Total citations: %d\n", 
            sum(x_clean$works$cited_by_count, na.rm = TRUE)))
#>   Total citations: 349

cat("\nThe corpus is now ready for:\n")
#> 
#> The corpus is now ready for:
cat("  - Descriptive analysis (describe_biblio)\n")
#>   - Descriptive analysis (describe_biblio)
cat("  - Impact metrics (biblio_metrics)\n")
#>   - Impact metrics (biblio_metrics)
cat("  - Network analysis (bibliographic_network)\n")
#>   - Network analysis (bibliographic_network)
cat("  - Comparative inference (compare_groups)\n")
#>   - Comparative inference (compare_groups)
cat("  - Temporal analysis (trend_topics)\n")
#>   - Temporal analysis (trend_topics)
```

## References

### Key Literature

The following references provide background on bibliometric data quality
and deduplication:

1.  **Aria, M., & Cuccurullo, C. (2017)**. bibliometrix: An R-tool for
    comprehensive science mapping analysis. *Journal of Informetrics*,
    11(4), 959-975. doi:
    [10.1016/j.joi.2017.08.007](https://doi.org/10.1016/j.joi.2017.08.007)

    - Introduces the bibliometrix package and discusses data quality in
      science mapping
    - Provides the foundation for many bibliometric workflows in R

2.  **Mongeon, P., & Paul-Hus, A. (2016)**. The journal coverage of Web
    of Science and Scopus: A comparative analysis. *Scientometrics*,
    106(1), 213-228. doi:
    [10.1007/s11192-015-1765-5](https://doi.org/10.1007/s11192-015-1765-5)

    - Compares database coverage and discusses implications for
      bibliometric validity

3.  **Visser, M., Van Eck, N. J., & Waltman, L. (2021)**. Large-scale
    comparison of bibliographic data sources: Scopus, Web of Science,
    Dimensions, Crossref, and Microsoft Academic. *Quantitative Science
    Studies*, 2(1), 20-41. doi:
    [10.1162/qss_a_00112](https://doi.org/10.1162/qss_a_00112)

    - Latest comprehensive comparison of major bibliographic databases

### Package Documentation

- **Package overview**:
  [`vignette("v00-overview")`](https://wep69.github.io/biblioIntegrator/articles/v00-overview.md)
- **Import and harmonization**:
  [`vignette("v01-import-harmonize")`](https://wep69.github.io/biblioIntegrator/articles/v01-import-harmonize.md)
- **Descriptive and impact analysis**:
  [`vignette("v03-descriptive-impact")`](https://wep69.github.io/biblioIntegrator/articles/v03-descriptive-impact.md)
- **Comparative inference**:
  [`vignette("v04-comparative-inference")`](https://wep69.github.io/biblioIntegrator/articles/v04-comparative-inference.md)
- **Network analysis**:
  [`vignette("v05-networks")`](https://wep69.github.io/biblioIntegrator/articles/v05-networks.md)

### Function References

- [`as_biblio_project()`](https://wep69.github.io/biblioIntegrator/reference/as_biblio_project.md):
  [`?as_biblio_project`](https://wep69.github.io/biblioIntegrator/reference/as_biblio_project.md)
- [`biblio_health()`](https://wep69.github.io/biblioIntegrator/reference/biblio_health.md):
  [`?biblio_health`](https://wep69.github.io/biblioIntegrator/reference/biblio_health.md)
- [`deduplicate_biblio()`](https://wep69.github.io/biblioIntegrator/reference/deduplicate_biblio.md):
  [`?deduplicate_biblio`](https://wep69.github.io/biblioIntegrator/reference/deduplicate_biblio.md)
- [`audit_biblio()`](https://wep69.github.io/biblioIntegrator/reference/audit_biblio.md):
  [`?audit_biblio`](https://wep69.github.io/biblioIntegrator/reference/audit_biblio.md)
- [`biblio_import()`](https://wep69.github.io/biblioIntegrator/reference/biblio_import.md):
  [`?biblio_import`](https://wep69.github.io/biblioIntegrator/reference/biblio_import.md)

### External Resources

- **DOI Foundation**: <https://www.doi.org/>
- **CrossRef**: <https://www.crossref.org/>
- **OpenAlex**: <https://openalex.org/>

### Reproducibility

To reproduce the examples in this vignette:

``` r

# Install biblioIntegrator
# install.packages("biblioIntegrator")

# Load the package
library(biblioIntegrator)

# Set seed for reproducibility (if using random processes)
set.seed(42)

# Run examples as shown in each section
```

For the most up-to-date version of this vignette, visit the package
documentation:

``` r

browseVignettes("biblioIntegrator")
```

### Session Info

``` r

sessionInfo()
#> R version 4.6.1 (2026-06-24)
#> Platform: x86_64-pc-linux-gnu
#> Running under: Ubuntu 24.04.4 LTS
#> 
#> Matrix products: default
#> BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
#> LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
#> 
#> locale:
#>  [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8       
#>  [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8   
#>  [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C          
#> [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C   
#> 
#> time zone: UTC
#> tzcode source: system (glibc)
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] stringdist_0.9.17      biblioIntegrator_0.3.0
#> 
#> loaded via a namespace (and not attached):
#>  [1] digest_0.6.39     desc_1.4.3        R6_2.6.1          fastmap_1.2.0    
#>  [5] xfun_0.60         cachem_1.1.0      parallel_4.6.1    knitr_1.51       
#>  [9] htmltools_0.5.9   rmarkdown_2.31    lifecycle_1.0.5   cli_3.6.6        
#> [13] sass_0.4.10       pkgdown_2.2.1     textshaping_1.0.5 jquerylib_0.1.4  
#> [17] systemfonts_1.3.2 compiler_4.6.1    tools_4.6.1       ragg_1.5.2       
#> [21] bslib_0.12.0      evaluate_1.0.5    yaml_2.3.12       otel_0.2.0       
#> [25] jsonlite_2.0.0    rlang_1.3.0       fs_2.1.0          htmlwidgets_1.6.4
```

------------------------------------------------------------------------

*Vignette generated with `biblioIntegrator` version 0.3.0.*
