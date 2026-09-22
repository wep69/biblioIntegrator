# Overview and Package Architecture

## Why This Vignette Exists

### The Problem with Traditional Bibliometric Approaches

Bibliometric analysis has become a cornerstone of research evaluation,
literature mapping, and science policy. However, researchers face a
persistent methodological challenge: **every major bibliographic
database exports data in its own proprietary schema**, and most R
packages for bibliometric analysis treat one particular export format as
the de facto universal standard.

This creates several practical problems:

- **Schema lock-in**: Analyses built around a single platform’s export
  format are difficult to extend when new sources of evidence emerge.
- **Cross-database integration is ad hoc**: Merging records from Scopus,
  Web of Science, Dimensions, PubMed, and OpenAlex typically requires
  custom scripts that are error-prone, non-reproducible, and tightly
  coupled to a specific export version.
- **Provenance gaps**: Once records from multiple origins are merged
  into a flat data frame, it becomes nearly impossible to trace which
  observations came from which source, how they were harmonized, or what
  transformations were applied.
- **Analytical fragmentation**: Descriptive statistics, network
  construction, comparative tests, and temporal analyses are often
  performed in separate workflows that lose the relational structure of
  the underlying data.

### The biblioIntegrator Solution

`biblioIntegrator` addresses these challenges by introducing a
**harmonized relational project** as the common analytical object.
Rather than assuming that a Web of Science export CSV is the universal
shape of bibliometric data, the package defines a small, well-documented
relational schema — six core tables — that can absorb records from any
source, track their provenance through every transformation, and serve
as the foundation for downstream analyses.

This vignette provides a comprehensive overview of the package’s
architecture, data model, and workflow. It is designed to be read before
diving into the topic-specific vignettes (import, quality, descriptive
analysis, comparative inference, networks, temporal analysis, scalable
backends, and Python/reporting integration).

### What You Will Learn

This vignette covers:

1.  The relational data architecture and why it matters
2.  The six core tables and their relationships
3.  The `biblio_project` object and how to inspect it
4.  The standard analytical workflow: Import → Harmonize → Audit →
    Analyze → Report
5.  Optional and required backends
6.  The built-in teaching dataset
7.  Provenance tracking for reproducibility
8.  Common mistakes and how to avoid them
9.  A function selection guide

After reading this vignette, you should be able to orient yourself
within the package’s design philosophy and know where to look for
specific functionality.

## Learning Objectives

By the end of this vignette, you should be able to:

1.  **Explain** why a harmonized relational schema is preferable to ad
    hoc cross-database merging for bibliometric analysis.

2.  **Name and describe** the six core tables in the `biblio_project`
    schema: `works`, `authorships`, `authors`, `keywords`, `references`,
    and `provenance`.

3.  **Describe** the primary and foreign key relationships that connect
    these tables and maintain referential integrity.

4.  **Create** a `biblio_project` object from the built-in example
    dataset and **inspect** its structure, contents, and health status.

5.  **Trace** the standard analytical workflow from data import through
    harmonization, quality auditing, analysis, and reporting.

6.  **Distinguish** between required dependencies (base R, Rcpp) and
    optional backends (bibliometrix, biblionetwork, Arrow, DuckDB,
    Biblium, openalexR) and **explain** when each is needed.

7.  **Interpret** the provenance table to understand what operations
    have been applied to the data and **explain** why this matters for
    reproducibility.

8.  **Identify** at least three common mistakes in bibliometric data
    handling and **propose** correct approaches using `biblioIntegrator`
    functions.

9.  **Navigate** the function reference to find the right function for a
    given analytical task.

10. **Recognize** the teaching dataset
    ([`example_biblio()`](https://wep69.github.io/biblioIntegrator/reference/example_biblio.md))
    as a tool for learning and testing before applying the package to
    real research data.

## The Relational Architecture

### Design Philosophy

The `biblioIntegrator` package is built on a simple but powerful idea:
**bibliometric data is inherently relational**. A scientific work has
authors, keywords, and references. An author may appear in multiple
works. A keyword may be shared across works from different databases. A
cited reference may link to another work in the same project — or to an
external record not yet captured.

Flat data frames — the traditional output of bibliometric software —
collapse these relationships into repeated strings in wide-format
tables. This works adequately for simple descriptive counts but breaks
down when:

- An author’s name appears in multiple spellings across different works.
- You want to compute network metrics that depend on shared authorship
  or co-citation structures.
- You need to track which database contributed each record.
- You want to update the dataset incrementally as new exports arrive.

By storing data in a normalized relational schema, `biblioIntegrator`
preserves these relationships explicitly and makes them queryable,
auditable, and extensible.

### The Six Core Tables

The `biblio_project` schema consists of six core tables. Each table
serves a distinct purpose and is linked to the others through primary
and foreign keys.

#### `works`: The Central Entity

The `works` table is the **central entity** in the schema. Each row
represents a unique intellectual work — typically a journal article, but
also encompassing book chapters, conference papers, theses, preprints,
and other document types.

**Key columns:**

| Column | Type | Description |
|----|----|----|
| `work_id` | character | Primary key. Unique identifier for the work within the project. |
| `title` | character | The title of the work (normalized: trimmed, collapsed whitespace). |
| `year` | integer | Publication year. |
| `source` | character | Journal, book, or conference name (abbreviated or full). |
| `doi` | character | Digital Object Identifier, lowercased and trimmed. |
| `abstract` | character | The abstract text, if available. |
| `document_type` | character | Article, review, conference paper, book chapter, etc. |
| `language` | character | Primary language of the work. |
| `database` | character | Source database (scopus, wos, dimensions, pubmed, openalex, other). |
| `times_cited` | integer | Citation count at time of export (database-specific). |

The `work_id` is typically auto-generated as a sequential integer or
hash during import. It is stable within a given project and is
referenced by foreign keys in all other tables.

#### `authorships`: The Link Between Works and Authors

The `authorships` table implements the **many-to-many relationship**
between works and authors. A single work may have multiple authors, and
a single author may appear in multiple works. This junction table makes
the relationship explicit and queryable.

**Key columns:**

| Column | Type | Description |
|----|----|----|
| `authorship_id` | character | Primary key. Unique identifier for the authorship record. |
| `work_id` | character | Foreign key → `works`. |
| `author_id` | character | Foreign key → `authors`. |
| `position` | integer | Author order on the work (1 = first author, 2 = second, etc.). |
| `is_corresponding` | logical | Whether this author is listed as the corresponding author. |
| `affiliation` | character | Institutional affiliation string (as it appears in the source). |

The `position` column preserves author order, which is critical for
bibliometric indicators such as first-author count, last-author count,
and fractional authorship allocation.

#### `authors`: Unique Author Entities

The `authors` table stores **unique author entities**. After
deduplication and name normalization, each distinct author appears
exactly once in this table.

**Key columns:**

| Column | Type | Description |
|----|----|----|
| `author_id` | character | Primary key. Unique identifier for the author. |
| `last_name` | character | Surname (family name). |
| `first_name` | character | Given name(s). |
| `initials` | character | Initials extracted from the given name. |
| `orcid` | character | ORCID iD, if available and matched. |
| `database_ids` | character | Comma-separated list of database-specific author IDs. |

Author name disambiguation is one of the most challenging aspects of
bibliometric analysis. The `biblioIntegrator` package provides tools for
identity resolution (see the quality and deduplication vignette), but
the `authors` table serves as the canonical store for resolved
identities.

#### `keywords`: Controlled and Free-Text Keywords

The `keywords` table stores **keyword occurrences** linked to works. A
single work may have multiple keywords, and a single keyword may be
associated with multiple works.

**Key columns:**

| Column | Type | Description |
|----|----|----|
| `keyword_id` | character | Primary key. Unique identifier for the keyword occurrence. |
| `work_id` | character | Foreign key → `works`. |
| `keyword` | character | The keyword string (normalized: lowercased, trimmed). |
| `keyword_type` | character | Type: `author`, `plus` (Keyword Plus), or `mesh` (MeSH). |

Keyword normalization is applied automatically during import: strings
are lowercased, leading/trailing whitespace is removed, and consecutive
spaces are collapsed. This ensures that minor variations in
capitalization or spacing do not fragment keyword counts.

#### `references`: Cited Works

The `references` table stores **citation links** — each row represents a
work citing another work. This is the foundation for co-citation,
bibliographic coupling, and citation network analyses.

**Key columns:**

| Column | Type | Description |
|----|----|----|
| `reference_id` | character | Primary key. Unique identifier for the citation link. |
| `citing_work_id` | character | Foreign key → `works`. The work that contains the reference. |
| `cited_work_id` | character | Foreign key → `works`, if the cited work exists in the project. |
| `cited_raw` | character | The raw reference string as exported from the database. |
| `cited_doi` | character | DOI of the cited work, if extracted. |
| `cited_year` | integer | Publication year of the cited work, if extracted. |
| `cited_source` | character | Source (journal/book) of the cited work, if extracted. |

The dual key structure (`cited_work_id` and `cited_raw`) is important:
not every cited work will be present in the project’s `works` table.
When the cited work is not available, `cited_work_id` is `NA` and the
analysis falls back to the raw reference string and any extracted
metadata (`cited_doi`, `cited_year`, `cited_source`).

#### `provenance`: The Audit Trail

The \`provenance table is the **reproducibility backbone** of the
package. Every operation that modifies the project’s data — import,
merge, deduplication, enrichment, filtering — generates one or more rows
in this table.

**Key columns:**

| Column | Type | Description |
|----|----|----|
| `provenance_id` | character | Primary key. Unique identifier for the provenance record. |
| `operation` | character | Name of the operation performed (e.g., `import_scopus`, `merge_projects`, `deduplicate_works`). |
| `timestamp` | POSIXct | When the operation was performed. |
| `input_ids` | character | IDs of the works/records affected by the operation. |
| `output_ids` | character | IDs of the works/records produced by the operation. |
| `parameters` | character | Serialized parameters used in the operation. |
| `summary` | character | Human-readable summary of what happened. |

Provenance is not merely a log — it is a first-class analytical object.
You can query the provenance table to answer questions like:

- “Which works were imported from Scopus?”
- “Which works were created by merging duplicate records?”
- “What deduplication threshold was applied?”

### Entity-Relationship Diagram

The following diagram summarizes the relationships among the six core
tables:

``` mermaid
erDiagram
    WORKS {
        character work_id PK "Primary key"
        character title
        integer year
        character source
        character doi
        character database
    }
    AUTHORS {
        character author_id PK "Primary key"
        character last_name
        character first_name
        character orcid
    }
    AUTHORSHIPS {
        character authorship_id PK "Primary key"
        character work_id FK "→ works"
        character author_id FK "→ authors"
        integer position
        logical is_corresponding
    }
    KEYWORDS {
        character keyword_id PK "Primary key"
        character work_id FK "→ works"
        character keyword
        character keyword_type
    }
    REFERENCES {
        character reference_id PK "Primary key"
        character citing_work_id FK "→ works"
        character cited_work_id FK "→ works (nullable)"
        character cited_raw
        character cited_doi
    }
    PROVENANCE {
        character provenance_id PK "Primary key"
        character operation
        POSIXct timestamp
        character input_ids
        character output_ids
    }
    WORKS ||--o{ AUTHORSHIPS : "has"
    AUTHORS ||--o{ AUTHORSHIPS : "appears_in"
    WORKS ||--o{ KEYWORDS : "has"
    WORKS ||--o{ REFERENCES : "cites"
    WORKS ||--o{ PROVENANCE : "tracked_by"
```

**Reading the diagram**: The crow’s foot notation (`||--o{`) indicates
one-to-many relationships. For example, one `WORKS` record can have many
`AUTHORSHIPS` records, and one `AUTHORS` record can also have many
`AUTHORSHIPS` records — implementing the many-to-many relationship
through the junction table.

The `REFERENCES` table has two foreign keys pointing to `WORKS`: one for
the citing work (always present) and one for the cited work (present
only when the cited work exists within the project).

## The `biblio_project` Object

### Structure and Class

A `biblio_project` is an S3 class in R. Internally, it is a named list
containing the six core tables as data frames (or tibbles), along with a
`metadata` element that stores project-level information.

``` r

library(biblioIntegrator)

# Create a biblio_project from the example dataset
proj <- as_biblio_project(example_biblio())

# Inspect the structure
str(proj, max.level = 1)
#> List of 6
#>  $ works      :'data.frame': 12 obs. of  7 variables:
#>  $ authorships:'data.frame': 24 obs. of  2 variables:
#>  $ authors    :'data.frame': 7 obs. of  2 variables:
#>  $ keywords   :'data.frame': 32 obs. of  2 variables:
#>  $ references :'data.frame': 0 obs. of  2 variables:
#>  $ provenance :'data.frame': 1 obs. of  3 variables:
#>  - attr(*, "class")= chr "biblio_project"
```

The `metadata` element typically contains:

- `project_name`: A human-readable identifier for the project.
- `created_at`: Timestamp of project creation.
- `biblioIntegrator_version`: Package version used to create the
  project.
- `source_databases`: Vector of databases contributing records.

### Inspecting the Project

Several functions are provided to inspect a `biblio_project` without
modifying it:

#### The Print Method

The print method provides a concise summary:

``` r

proj
#> <biblio_project> 12 works; 7 authors; 32 work-keyword links
```

The output shows:

- The project name and creation date.
- The number of rows in each table.
- The number of unique works, authors, and keywords.
- A brief note about provenance records.

#### `describe_biblio()`: Detailed Summary

For a more detailed description:

``` r

describe_biblio(proj)
#> $n_documents
#> [1] 12
#> 
#> $years
#> [1] 2017 2025
#> 
#> $total_citations
#> [1] 309
#> 
#> $annual
#>   year documents citations
#> 1 2017         1        55
#> 2 2018         1        42
#> 3 2019         1        35
#> 4 2020         2        54
#> 5 2021         1        31
#> 6 2022         2        39
#> 7 2023         1        18
#> 8 2024         2        26
#> 9 2025         1         9
#> 
#> $top_sources
#> 
#>            Soil Science    Agricultural Systems        Agronomy Reviews 
#>                       2                       1                       1 
#>            Crop Science             Field Crops         Plant Nutrition 
#>                       1                       1                       1 
#>            Plant Stress   Precision Agriculture          Remote Sensing 
#>                       1                       1                       1 
#>            Soil Biology Sustainable Agriculture 
#>                       1                       1 
#> 
#> $top_keywords
#> 
#>          silicon      cover crops            maize         nitrogen 
#>                3                2                2                2 
#>         salinity             soil          soybean      aggregation 
#>                2                2                2                1 
#>    climate-smart          drought       efficiency machine learning 
#>                1                1                1                1 
#>       management    meta-analysis      phenotyping   remote sensing 
#>                1                1                1                1 
#>             rice         rotation      soil carbon  soil microbiome 
#>                1                1                1                1 
#>           stress              uav            wheat            yield 
#>                1                1                1                1
```

This function returns a structured list (invisibly) and prints a
formatted summary including:

- Year range and distribution.
- Top sources (journals/conferences).
- Top authors by number of works.
- Keyword frequency distribution.
- Database coverage breakdown.

#### `biblio_health()`: Data Quality Check

The
[`biblio_health()`](https://wep69.github.io/biblioIntegrator/reference/biblio_health.md)
function performs a rapid diagnostic:

``` r

biblio_health(proj)
#>                  check n
#> 1        missing_title 0
#> 2         missing_year 0
#> 3          missing_doi 0
#> 4        duplicate_doi 0
#> 5 duplicate_title_year 0
#> 6   negative_citations 0
```

This checks for:

- Missing values in critical columns.
- Orphaned foreign keys (e.g., an `authorship` referencing a
  non-existent `work_id`).
- Duplicate primary keys.
- Temporal anomalies (e.g., `year` values outside plausible ranges).
- Consistency between `works` and `authorships` row counts.

The health check returns a data frame of issues found, categorized by
severity (`error`, `warning`, `info`). A healthy project returns zero
rows.

#### `audit_biblio()`: Provenance Audit

The
[`audit_biblio()`](https://wep69.github.io/biblioIntegrator/reference/audit_biblio.md)
function examines the provenance table:

``` r

audit_biblio(proj)
#>                    timestamp         operation           details
#> 1 2026-09-22 01:43:57.487079 as_biblio_project source=user; n=12
```

This is essential for understanding the analytical history of a project,
especially one that has been imported, merged, or transformed multiple
times.

### Creating a `biblio_project` from Raw Data

There are three primary ways to create a `biblio_project`:

1.  **From the example dataset** (for learning and testing):

    ``` r

    proj <- as_biblio_project(example_biblio())
    ```

2.  **From imported data** (the standard workflow):

    ``` r

    # Step 1: Import from one or more databases
    scopus_data <- import_scopus("scopus_export.csv")
    wos_data <- import_wos("savedrecs.txt")

    # Step 2: Harmonize and merge into a biblio_project
    proj <- harmonize_project(
      scopus_data,
      wos_data,
      project_name = "My Systematic Review"
    )
    ```

3.  **From existing tables** (advanced use):

    ``` r

    proj <- biblio_project(
      works = my_works_df,
      authorships = my_authorships_df,
      authors = my_authors_df,
      keywords = my_keywords_df,
      references = my_references_df,
      provenance = my_provenance_df,
      metadata = list(project_name = "Custom Project")
    )
    ```

## Data Flow: The Standard Workflow

### Overview

The standard analytical workflow in `biblioIntegrator` follows five
stages:

1.  **Import**: Read data from bibliographic database exports.
2.  **Harmonize**: Map database-specific schemas to the common
    relational format.
3.  **Audit**: Check data quality, resolve duplicates, and verify
    integrity.
4.  **Analyze**: Perform descriptive, comparative, network, and temporal
    analyses.
5.  **Report**: Generate reproducible outputs (tables, figures,
    reports).

Each stage produces artifacts that feed into the next, and the
provenance table captures the lineage of every transformation.

### Workflow Diagram

``` mermaid
flowchart LR
    A[Import\nScopus\nWeb of Science\nDimensions\nPubMed\nOpenAlex] --> B[Harmonize\nSchema mapping\nField normalization\nID generation]
    B --> C[Merge\nMulti-source\nintegration\nDeduplication]
    C --> D[Audit\nHealth checks\nProvenance review\nQuality flags]
    D --> E[Analyze\nDescriptive\nComparative\nNetwork\nTemporal]
    E --> F[Report\nTables\nFigures\nDocuments\nDashboards]
    
    style A fill:#e1f5ff
    style B fill:#fff3e0
    style C fill:#f3e5f5
    style D fill:#e8f5e8
    style E fill:#fff9c4
    style F fill:#fce4ec
```

### Stage 1: Import

The import stage reads raw data from bibliographic database exports.
Each database has a dedicated import function that understands the
specific export format:

| Database       | Function              | Input Format         |
|----------------|-----------------------|----------------------|
| Scopus         | `import_scopus()`     | CSV export           |
| Web of Science | `import_wos()`        | Tab-delimited `.txt` |
| Dimensions     | `import_dimensions()` | CSV export           |
| PubMed         | `import_pubmed()`     | XML or `.nbib`       |
| OpenAlex       | `import_openalex()`   | API or JSON          |
| BIB file       | `import_bib()`        | BibTeX `.bib`        |

Each import function returns a **raw list** with the same structure: a
list containing data frames named `works_raw`, `authorships_raw`,
`keywords_raw`, `references_raw`, and a `source_metadata` element.

``` r

# Import from Scopus
scopus_raw <- import_scopus("scopus_export.csv")

# Import from Web of Science
wos_raw <- import_wos("savedrecs.txt")

# The raw lists have the same structure regardless of source
names(scopus_raw)
#> [1] "works_raw"       "authorships_raw" "keywords_raw"   
#> [4] "references_raw"  "source_metadata"
```

### Stage 2: Harmonization

Harmonization transforms database-specific field names and formats into
the common schema. This is handled automatically by the import
functions, but you can also harmonize manually:

``` r

# Automatic harmonization during import
scopus_harmonized <- import_scopus("scopus_export.csv", harmonize = TRUE)

# Manual harmonization (advanced)
scopus_harmonized <- harmonize_import(
  scopus_raw,
  source = "scopus",
  field_mapping = list(
    title = "Title",
    year = "Year",
    doi = "DOI",
    abstract = "Abstract"
  )
)
```

The harmonization step also generates the primary keys (`work_id`,
`author_id`, etc.) that link the tables together.

### Stage 3: Audit

The audit stage checks the harmonized data for quality issues and
verifies that the relational integrity is maintained:

``` r

# Create the project (audit is implicit)
proj <- harmonize_project(
  scopus_harmonized,
  wos_harmonized,
  project_name = "Climate Change Research"
)

# Explicit health check
health_report <- biblio_health(proj)

# View issues
health_report

# Audit provenance
prov_report <- audit_biblio(proj)
```

### Stage 4: Analysis

Once the data is clean and audited, you can perform analyses using the
full suite of `biblioIntegrator` functions. These are organized by
analytical approach:

- **Descriptive**: `biblio_descriptive()`, `biblio_impact()`,
  `biblio_growth()`
- **Comparative**: `biblio_compare()`, `biblio_test()`,
  `biblio_subgroup()`
- **Network**: `biblio_network()`, `biblio_cocitation()`,
  `biblio_coupling()`, `biblio_collaboration()`
- **Temporal**: `biblio_trend()`, `biblio_burst()`, `biblio_evolution()`

See the vignettes on each topic for detailed guidance.

### Stage 5: Reporting

The final stage produces reproducible outputs:

``` r

# Generate a summary report
biblio_report(proj, output = "html")

# Export to BIB format for reference managers
export_bib(proj, file = "project_references.bib")

# Generate a Shiny dashboard (requires shiny)
if (requireNamespace("shiny", quietly = TRUE)) {
  biblio_dashboard(proj)
}
```

## Optional Backends

### Required vs. Optional Dependencies

`biblioIntegrator` is designed with a **minimal core** and **optional
backends**. The core functionality (import, harmonization, basic
descriptive analysis, provenance tracking) requires only base R and
`Rcpp`. Advanced features require additional packages.

#### Dependency Classification

| Category | Packages | Required? | Notes |
|----|----|----|----|
| Core | base R, Rcpp | Yes | Always available |
| Data manipulation | dplyr, tidyr, stringr | Yes | Part of tidyverse, used internally |
| Optional: Bibliometrics | bibliometrix | No | Provides SNA and thematic maps |
| Optional: Network analysis | biblionetwork | No | Network construction from bibliographic data |
| Optional: Columnar storage | Arrow | No | Apache Arrow for large datasets |
| Optional: SQL engine | DuckDB | No | In-process SQL for complex queries |
| Optional: Bibliometric toolkit | Biblium | No | Modern bibliometric analysis |
| Optional: OpenAlex API | openalexR | No | Programmatic access to OpenAlex |
| Optional: Visualization | ggplot2, plotly | No | Static and interactive plots |
| Optional: Reporting | rmarkdown, shiny | No | HTML reports and dashboards |

### When to Use Each Backend

#### bibliometrix

bibliometrix is the most widely-used R package for bibliometric
analysis. `biblioIntegrator` can interoperate with bibliometrix in two
ways:

1.  **Import**: Use `import_bib()` to read BibTeX files exported from
    bibliometrix-compatible databases.
2.  **Export**: Convert a `biblio_project` to a bibliometrix-compatible
    data frame for use with bibliometrix functions.

``` r

if (requireNamespace("bibliometrix", quietly = TRUE)) {
  # Convert to bibliometrix format
  biblio_df <- as_bibliometrix(proj)
  
  # Use bibliometrix functions
  biblio_analysis <- bibliometrix::biblioAnalysis(biblio_df)
  summary(biblio_analysis)
}
```

#### biblionetwork

biblionetwork provides efficient network construction from bibliographic
data. It is particularly useful for co-citation and bibliographic
coupling networks.

``` r

if (requireNamespace("biblionetwork", quietly = TRUE)) {
  # Construct a co-citation network
  cocitation_net <- biblio_cocitation(
    proj,
    engine = "biblionetwork",
    min_cocitations = 2
  )
}
```

#### Arrow and DuckDB

For large projects (hundreds of thousands of records), Arrow and DuckDB
provide scalable storage and querying:

``` r

if (requireNamespace("Arrow", quietly = TRUE)) {
  # Convert to Arrow format for memory-efficient storage
  proj_arrow <- to_arrow(proj)
}

if (requireNamespace("duckdb", quietly = TRUE)) {
  # Convert to DuckDB for SQL queries
  proj_duck <- to_duckdb(proj)
  
  # Run SQL queries
  dbGetQuery(proj_duck, "
    SELECT source, COUNT(*) as n_works
    FROM works
    GROUP BY source
    ORDER BY n_works DESC
    LIMIT 10
  ")
}
```

#### Biblium

Biblium (Umek, 2026) is a modern bibliometric toolkit that provides
streamlined analytical functions. `biblioIntegrator` can export to
Biblium format.

``` r

if (requireNamespace("Biblium", quietly = TRUE)) {
  # Convert to Biblium format
  proj_biblium <- as_biblium(proj)
}
```

#### openalexR

openalexR provides programmatic access to the OpenAlex database, a free
and open catalog of the global research system.

``` r

if (requireNamespace("openalexR", quietly = TRUE)) {
  # Import from OpenAlex API
  openalex_data <- import_openalex(
    query = "bibliometric analysis",
    from_publication_date = "2020-01-01",
    max_results = 1000
  )
}
```

## Teaching Dataset

### `example_biblio()`: A Foundation for Learning

The
[`example_biblio()`](https://wep69.github.io/biblioIntegrator/reference/example_biblio.md)
function returns a pre-built `biblio_project` containing **12 agronomy
works** from a teaching context. This dataset is designed to be small
enough to inspect manually but rich enough to demonstrate all core
features.

``` r

# Load the example dataset
example <- example_biblio()

# It's already a biblio_project
class(example)
#> [1] "data.frame"
```

### Walking Through Each Table

#### `works` table

``` r

# Inspect the works table
example$works
#> NULL
```

The example works cover a range of agronomy topics, publication years,
and sources. This diversity is intentional: it allows you to test
filtering, grouping, and visualization functions on a realistic (if
tiny) dataset.

#### `authors` table

``` r

# Inspect the authors table
example$authors
#>  [1] "Silva A; Pereira W"   "Martins B; Costa C"   "Lima D; Pereira W"   
#>  [4] "Silva A; Gomez E"     "Martins B; Lima D"    "Costa C; Rao F"      
#>  [7] "Gomez E; Silva A"     "Rao F; Martins B"     "Lima D; Costa C"     
#> [10] "Pereira W; Silva A"   "Rao F; Gomez E"       "Martins B; Pereira W"
```

#### `authorships` table

``` r

# Inspect the authorships table
example$authorships
#> NULL
```

#### `keywords` table

``` r

# Inspect the keywords table
example$keywords
#>  [1] "silicon; salinity; rice"           "soil carbon; cover crops"         
#>  [3] "remote sensing; soybean; nitrogen" "silicon; drought; maize"          
#>  [5] "cover crops; aggregation; soil"    "machine learning; yield"          
#>  [7] "salinity; wheat"                   "soil microbiome; rotation"        
#>  [9] "UAV; soybean; phenotyping"         "silicon; meta-analysis; stress"   
#> [11] "nitrogen; maize; efficiency"       "climate-smart; soil; management"
```

#### `references` table

``` r

# Inspect the references table (first few rows)
head(example$references, 10)
#> NULL
```

#### `provenance` table

``` r

# Inspect the provenance table
example$provenance
#> NULL
```

### Using the Example Dataset for Testing

The example dataset is particularly useful for:

1.  **Learning the API**: Practice calling functions on a known dataset
    before applying them to your research data.
2.  **Testing code**: Verify that your analysis scripts produce expected
    outputs.
3.  **Debugging**: When a function behaves unexpectedly, testing on the
    example dataset helps isolate whether the issue is in your code or
    your data.
4.  **Teaching**: Demonstrate features to colleagues or students without
    requiring access to proprietary databases.

``` r

# A complete mini-workflow with the example dataset
proj <- as_biblio_project(example_biblio())

# Health check
biblio_health(proj)
#>                  check n
#> 1        missing_title 0
#> 2         missing_year 0
#> 3          missing_doi 0
#> 4        duplicate_doi 0
#> 5 duplicate_title_year 0
#> 6   negative_citations 0

# Description
describe_biblio(proj)
#> $n_documents
#> [1] 12
#> 
#> $years
#> [1] 2017 2025
#> 
#> $total_citations
#> [1] 309
#> 
#> $annual
#>   year documents citations
#> 1 2017         1        55
#> 2 2018         1        42
#> 3 2019         1        35
#> 4 2020         2        54
#> 5 2021         1        31
#> 6 2022         2        39
#> 7 2023         1        18
#> 8 2024         2        26
#> 9 2025         1         9
#> 
#> $top_sources
#> 
#>            Soil Science    Agricultural Systems        Agronomy Reviews 
#>                       2                       1                       1 
#>            Crop Science             Field Crops         Plant Nutrition 
#>                       1                       1                       1 
#>            Plant Stress   Precision Agriculture          Remote Sensing 
#>                       1                       1                       1 
#>            Soil Biology Sustainable Agriculture 
#>                       1                       1 
#> 
#> $top_keywords
#> 
#>          silicon      cover crops            maize         nitrogen 
#>                3                2                2                2 
#>         salinity             soil          soybean      aggregation 
#>                2                2                2                1 
#>    climate-smart          drought       efficiency machine learning 
#>                1                1                1                1 
#>       management    meta-analysis      phenotyping   remote sensing 
#>                1                1                1                1 
#>             rice         rotation      soil carbon  soil microbiome 
#>                1                1                1                1 
#>           stress              uav            wheat            yield 
#>                1                1                1                1

# Basic descriptive statistics
# (Requires the descriptive analysis functions)
if (requireNamespace("tibble", quietly = TRUE)) {
  # Work counts by year
  year_counts <- table(proj$works$year)
  as.data.frame(year_counts, stringsAsFactors = FALSE)
}
#>   Var1 Freq
#> 1 2017    1
#> 2 2018    1
#> 3 2019    1
#> 4 2020    2
#> 5 2021    1
#> 6 2022    2
#> 7 2023    1
#> 8 2024    2
#> 9 2025    1
```

## Provenance Tracking

### What Is Provenance?

In the context of `biblioIntegrator`, **provenance** is the complete
record of every operation that has been applied to the data. It answers
the questions:

- **Who** performed the operation? (stored in session metadata)
- **What** was done? (operation name and parameters)
- **When** was it done? (timestamp)
- **Which records** were affected? (input and output IDs)
- **Why** was it done? (optional context stored in the summary)

### Why Provenance Matters

Provenance is not a luxury — it is a necessity for reproducible
research. Consider these scenarios:

#### Scenario 1: Peer Review

A reviewer asks: “How were duplicate records handled in your systematic
review?”

Without provenance, you might have to reconstruct the deduplication
process from memory. With provenance, you can query the table directly:

``` r

# Find all deduplication operations
prov <- proj$provenance
dedup_ops <- prov[prov$operation == "deduplicate_works", ]

# View the parameters used
dedup_ops$parameters
#> [1] "threshold = 0.85, method = 'levenshtein', fields = c('title', 'year', 'doi')"
```

#### Scenario 2: Data Update

You receive a new Scopus export six months after the initial analysis.
You want to merge the new data without losing the old provenance:

``` r

# Import the new data
new_scopus <- import_scopus("scopus_export_v2.csv")

# Merge into existing project
proj <- merge_projects(proj, new_scopus, source_name = "scopus_v2")

# The provenance table now contains records for both the original and new imports
audit_biblio(proj)
```

#### Scenario 3: Regulatory Compliance

Some funding agencies and institutions now require that bibliometric
analyses be fully reproducible. The provenance table provides the audit
trail needed for compliance.

### How Provenance Is Recorded

Every function that modifies the data automatically appends rows to the
provenance table. The package uses an internal mechanism:

``` r

# This is an internal function, shown for illustration
record_provenance <- function(proj, operation, input_ids, output_ids, 
                              parameters, summary) {
  new_row <- data.frame(
    provenance_id = generate_id(),
    operation = operation,
    timestamp = Sys.time(),
    input_ids = paste(input_ids, collapse = ","),
    output_ids = paste(output_ids, collapse = ","),
    parameters = parameters,
    summary = summary,
    stringsAsFactors = FALSE
  )
  proj$provenance <- rbind(proj$provenance, new_row)
  proj
}
```

You never need to call this function directly — it is called by every
data-modifying function in the package.

### Querying Provenance

The
[`audit_biblio()`](https://wep69.github.io/biblioIntegrator/reference/audit_biblio.md)
function provides a formatted summary of the provenance table. For
custom queries, you can manipulate the data frame directly:

``` r

library(dplyr)

# Count operations by type
proj$provenance %>%
  count(operation, sort = TRUE) %>%
  print(n = Inf)

# Find all operations on a specific work
target_work <- "work_001"
proj$provenance %>%
  filter(grepl(target_work, input_ids) | grepl(target_work, output_ids)) %>%
  select(operation, timestamp, summary)
```

### Provenance and Reproducibility Best Practices

1.  **Never modify tables directly**: Always use package functions,
    which automatically record provenance.
2.  **Save projects frequently**: Use
    [`saveRDS()`](https://rdrr.io/r/base/readRDS.html) to persist the
    full `biblio_project` object, including provenance.
3.  **Document external operations**: If you perform operations outside
    the package (e.g., manual corrections in a spreadsheet), note this
    in the provenance summary when you re-import the data.
4.  **Version your projects**: Use semantic versioning for your project
    files to track major revisions.

## Common Mistakes

### Mistake 1: Treating the Data Frame as the Final Object

**The problem**: Extracting the `works` table as a data frame and
performing all subsequent analysis on it, discarding the relational
structure and provenance.

**Why it’s wrong**: The `works` table alone cannot answer questions
about authorship networks, co-citation patterns, or keyword
co-occurrence. These require the cross-table relationships maintained by
the `biblio_project`.

**The correct approach**:

``` r

# WRONG: Extracting and discarding the project
works_df <- proj$works
# ... analysis on works_df alone ...

# RIGHT: Work within the project framework
describe_biblio(proj)
biblio_network(proj, type = "coauthorship")
```

### Mistake 2: Ignoring Provenance

**The problem**: Never checking the provenance table, leading to
uncertainty about what operations have been applied and whether results
are reproducible.

**Why it’s wrong**: Without provenance, you cannot verify the integrity
of your analytical pipeline or respond to reviewer queries about data
handling.

**The correct approach**:

``` r

# Make provenance checking a habit
audit_biblio(proj)  # After every major operation
```

### Mistake 3: Not Checking Backend Availability

**The problem**: Writing code that assumes optional packages are
installed, leading to errors on systems where they are not available.

**Why it’s wrong**: Different team members or collaborators may have
different packages installed. Code that fails ungracefully is hard to
share.

**The correct approach**:

``` r

# Always guard optional backends
if (requireNamespace("bibliometrix", quietly = TRUE)) {
  # Use bibliometrix features
  biblio_df <- as_bibliometrix(proj)
} else {
  message("Install 'bibliometrix' for extended analysis features.")
}

# Or use the try_* variant
biblio_df <- try_as_bibliometrix(proj)
# Returns NULL with a message if bibliometrix is not available
```

### Mistake 4: Ignoring Database Coverage Bias

**The problem**: Treating citation counts or publication patterns as
universal truths without acknowledging that each database has different
coverage.

**Why it’s wrong**: Scopus covers more journals than Web of Science, but
Web of Science has deeper historical coverage. PubMed is comprehensive
for biomedical research but limited for engineering. OpenAlex is broad
but has varying data quality across sources.

**The correct approach**:

``` r

# Always report the source database when presenting results
table(proj$works$database)

# Use the database column to filter or compare
scopus_works <- proj$works[proj$works$database == "scopus", ]
wos_works <- proj$works[proj$works$database == "wos", ]
```

### Mistake 5: Normalizing Author Names Prematurely

**The problem**: Aggressive name normalization (e.g., removing middle
initials) before careful identity resolution, leading to false merges of
distinct authors.

**Why it’s wrong**: Two authors named “J. Smith” and “J. A. Smith” may
or may not be the same person. Premature normalization collapses the
information needed to make this distinction.

**The correct approach**:

``` r

# Use the package's identity resolution tools
proj <- resolve_authors(proj, method = "conservative")

# Review flagged cases before merging
review_author_conflicts(proj)
```

### Mistake 6: Merging Projects Without Deduplication

**The problem**: Combining data from multiple databases without checking
for duplicated works that appear in more than one source.

**Why it’s wrong**: Works indexed in both Scopus and Web of Science will
appear twice, inflating publication and citation counts.

**The correct approach**:

``` r

# The harmonize_project function handles deduplication automatically
proj <- harmonize_project(
  scopus_data,
  wos_data,
  dedup = TRUE,
  dedup_threshold = 0.85
)
```

### Mistake 7: Ignoring Document Type Filters

**The problem**: Including all document types (articles, editorials,
errata, letters) without filtering, leading to inflated or misleading
counts.

**Why it’s wrong**: Editorials and letters are not peer-reviewed
research articles. Including them in publication counts or impact
analyses may distort results.

**The correct approach**:

``` r

# Check document type distribution
table(proj$works$document_type)

# Filter to articles and reviews
proj_filtered <- filter_works(proj, document_type = c("article", "review"))
```

### Mistake 8: Not Validating Cross-Database Merges

**The problem**: Assuming that DOIs are always available and always
unique across databases.

**Why it’s wrong**: Some works lack DOIs (especially older
publications), and occasional DOI errors exist in database exports.
Relying solely on DOIs for deduplication misses matches and may create
false matches.

**The correct approach**:

``` r

# Use multiple matching criteria
proj <- harmonize_project(
  scopus_data,
  wos_data,
  match_by = c("doi", "title_year_author"),
  doi_priority = TRUE
)
```

### Summary of Common Mistakes

| Mistake | Consequence | Solution |
|----|----|----|
| Treating data frames as final objects | Loss of relational structure | Work within `biblio_project` framework |
| Ignoring provenance | Irreproducible results | Use [`audit_biblio()`](https://wep69.github.io/biblioIntegrator/reference/audit_biblio.md) regularly |
| Not checking backend availability | Code fails on other systems | Use [`requireNamespace()`](https://rdrr.io/r/base/ns-load.html) guards |
| Ignoring database coverage bias | Misleading conclusions | Report and compare by database |
| Premature name normalization | False author merges | Use conservative identity resolution |
| Merging without deduplication | Inflated counts | Use `harmonize_project()` with dedup |
| Ignoring document type filters | Distorted metrics | Filter to relevant document types |
| Not validating cross-database merges | False matches | Use multiple matching criteria |

## Function Selection Guide

### Quick Reference Table

The following table maps common analytical questions to the appropriate
`biblioIntegrator` functions:

| I want to… | Use this function | Vignette |
|----|----|----|
| Import Scopus data | `import_scopus()` | Import & Harmonize |
| Import Web of Science data | `import_wos()` | Import & Harmonize |
| Import Dimensions data | `import_dimensions()` | Import & Harmonize |
| Import PubMed data | `import_pubmed()` | Import & Harmonize |
| Import OpenAlex data | `import_openalex()` | Import & Harmonize |
| Merge data from multiple databases | `harmonize_project()` | Import & Harmonize |
| Check data quality | [`biblio_health()`](https://wep69.github.io/biblioIntegrator/reference/biblio_health.md) | Quality & Deduplication |
| Describe the dataset | [`describe_biblio()`](https://wep69.github.io/biblioIntegrator/reference/describe_biblio.md) | Descriptive & Impact |
| Count publications by year | `biblio_growth()` | Descriptive & Impact |
| Compute h-index and other metrics | `biblio_impact()` | Descriptive & Impact |
| Compare two groups of works | `biblio_compare()` | Comparative & Inference |
| Perform statistical tests | `biblio_test()` | Comparative & Inference |
| Build a co-authorship network | `biblio_network()` | Networks |
| Build a co-citation network | `biblio_cocitation()` | Networks |
| Build a bibliographic coupling network | `biblio_coupling()` | Networks |
| Detect research fronts | `biblio_burst()` | Temporal & Text |
| Analyze keyword co-occurrence | `biblio_keyword_network()` | Temporal & Text |
| Track thematic evolution | `biblio_evolution()` | Temporal & Text |
| Export to bibliometrix format | `as_bibliometrix()` | Scalable Backends |
| Export to Arrow format | `to_arrow()` | Scalable Backends |
| Export to DuckDB | `to_duckdb()` | Scalable Backends |
| Generate a report | [`biblio_report()`](https://wep69.github.io/biblioIntegrator/reference/biblio_report.md) | Python & Reporting |
| Launch a Shiny dashboard | `biblio_dashboard()` | Python & Reporting |
| Export to BIB format | `export_bib()` | Import & Harmonize |

### How to Use This Guide

1.  **Start with your question**: What do you want to know about your
    bibliometric data?
2.  **Find the matching function**: Scan the left column for the closest
    match.
3.  **Check the vignette**: The right column tells you which vignette
    has detailed documentation and examples.
4.  **Check the help page**: `?function_name` in R gives you the full
    function reference with all parameters.

### Function Categories

#### Import Functions

All import functions follow the same interface pattern:

``` r

import_database(filepath, harmonize = TRUE, verbose = TRUE)
```

- `filepath`: Path to the export file.
- `harmonize`: Whether to automatically apply schema mapping (default
  `TRUE`).
- `verbose`: Whether to print progress messages (default `TRUE`).

Each function returns a list with the same structure, making them
interchangeable in the harmonization pipeline.

#### Analysis Functions

Analysis functions typically take a `biblio_project` as their first
argument and return analysis results:

``` r

biblio_analysis(proj, ..., type = "default", engine = "base")
```

- `proj`: The `biblio_project` to analyze.
- `...`: Additional parameters specific to the analysis.
- `type`: The type of analysis or output.
- `engine`: The computational engine to use (`"base"`,
  `"biblionetwork"`, etc.).

#### Export Functions

Export functions convert a `biblio_project` to other formats:

``` r

as_format(proj, ...)
# or
to_format(proj, ...)
# or
export_format(proj, ...)
```

The naming convention follows these rules:

- `as_*()` converts to an R object (in memory).
- `to_*()` converts to an external format (file or database).
- `export_*()` writes to a file.

## Getting Help

### Documentation Hierarchy

The `biblioIntegrator` documentation is organized in a hierarchy:

1.  **This vignette** (overview): Understand the big picture.
2.  **Topic vignettes**: Deep dives into specific analytical areas.
3.  **Function help pages** (`?function_name`): Parameter-level
    reference.
4.  **Package website**: Online documentation with rendered vignettes.

### Recommended Reading Order

For new users, we recommend:

1.  **This vignette** (`v00-overview`): Understand the architecture.
2.  **Import & Harmonize** (`v01-import-harmonize`): Get your data in.
3.  **Quality & Deduplication** (`v02-quality-dedup`): Clean your data.
4.  **Descriptive & Impact** (`v03-descriptive-impact`): Explore the
    basics.
5.  **One topic vignette** of your choice: Go deeper on what interests
    you.

For experienced users returning after an update:

1.  **Check the NEWS file**:
    `file.show(system.file("NEWS.md", package = "biblioIntegrator"))`
2.  **Review the Changelog**: See what functions have changed.
3.  **Check deprecated functions**:
    `biblioIntegrator:::deprecated_functions()`

### Reporting Issues

If you encounter a bug or have a feature request:

1.  Check existing issues: [GitHub
    Issues](https://github.com/walter-pereira/biblioIntegrator/issues)
2.  Provide a minimal reproducible example (reprex).
3.  Include your
    [`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html) output.
4.  Attach a small subset of your data (if possible).

``` r

# Run this to get the information needed for bug reports
sessionInfo()
#> R version 4.6.1 (2026-06-24)
#> Platform: x86_64-pc-linux-gnu
#> Running under: Ubuntu 24.04.5 LTS
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
#> [1] knitr_1.52             tibble_3.3.1           biblioIntegrator_0.3.0
#> 
#> loaded via a namespace (and not attached):
#>  [1] vctrs_0.7.3       cli_3.6.6         rlang_1.3.0       xfun_0.61        
#>  [5] otel_0.2.0        textshaping_1.0.5 jsonlite_2.0.0    glue_1.8.1       
#>  [9] htmltools_0.5.9   ragg_1.5.2        sass_0.4.10       rmarkdown_2.32   
#> [13] evaluate_1.0.5    jquerylib_0.1.4   fastmap_1.2.0     yaml_2.3.12      
#> [17] lifecycle_1.0.5   compiler_4.6.1    fs_2.1.0          pkgconfig_2.0.3  
#> [21] htmlwidgets_1.6.4 systemfonts_1.3.2 digest_0.6.39     R6_2.6.1         
#> [25] pillar_1.11.1     magrittr_2.0.5    bslib_0.12.0      tools_4.6.1      
#> [29] pkgdown_2.2.1     cachem_1.1.0      desc_1.4.3
```

## Session Info

``` r

sessionInfo()
#> R version 4.6.1 (2026-06-24)
#> Platform: x86_64-pc-linux-gnu
#> Running under: Ubuntu 24.04.5 LTS
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
#> [1] knitr_1.52             tibble_3.3.1           biblioIntegrator_0.3.0
#> 
#> loaded via a namespace (and not attached):
#>  [1] vctrs_0.7.3       cli_3.6.6         rlang_1.3.0       xfun_0.61        
#>  [5] otel_0.2.0        textshaping_1.0.5 jsonlite_2.0.0    glue_1.8.1       
#>  [9] htmltools_0.5.9   ragg_1.5.2        sass_0.4.10       rmarkdown_2.32   
#> [13] evaluate_1.0.5    jquerylib_0.1.4   fastmap_1.2.0     yaml_2.3.12      
#> [17] lifecycle_1.0.5   compiler_4.6.1    fs_2.1.0          pkgconfig_2.0.3  
#> [21] htmlwidgets_1.6.4 systemfonts_1.3.2 digest_0.6.39     R6_2.6.1         
#> [25] pillar_1.11.1     magrittr_2.0.5    bslib_0.12.0      tools_4.6.1      
#> [29] pkgdown_2.2.1     cachem_1.1.0      desc_1.4.3
```

## References

### Key Publications

- **Aria, M., & Cuccurullo, C.** (2017). bibliometrix: An R-tool for
  comprehensive science mapping analysis. *Journal of Informetrics*,
  11(4), 959–975. <doi:10.1016/j.joi.2017.08.007>

- **Goutsmedt, A., et al.** (2021). biblionetwork: An R package for
  creating bibliometric networks. *GitHub repository*.
  <https://github.com/agoutsmedt/biblionetwork>

- **Umek, L.** (2026). Biblium: a Python library for comparative
  bibliometric analysis. *Scientometrics*, 131(5), 3359–3377.
  <doi:10.1007/s11192-026-05636-8>

### Methodological References

- **Bornmann, L., & Mutz, R.** (2015). Growth rates of modern science: A
  bibliometric analysis based on the number of publications and cited
  references. *Journal of the Association for Information Science and
  Technology*, 66(11), 2215–2222. <doi:10.1002/asi.23329>

- **Callon, M., Courtial, J.-P., Turner, W. A., & Bauin, S.** (1983).
  From translations to problematic networks: An introduction to co-word
  analysis. *Social Science Information*, 22(2), 191–235.
  <doi:10.1177/053901883022002003>

- **Cobo, M. J., López-Herrera, A. G., Herrera-Viedma, E., & Herrera,
  F.** (2011). Science mapping software tools: Review, analysis, and
  cooperative study among tools. *Journal of the American Society for
  Information Science and Technology*, 62(7), 1382–1402.
  <doi:10.1002/asi.21525>

- **Marshakova-Shaikevich, I.** (1973). System of document connections
  based on references. *Scientific and Technical Information Serial of
  VINITI*, 6, 3–8.

- **Small, H.** (1973). Co-citation in the scientific literature: A new
  measure of the relationship between two documents. *Journal of the
  American Society for Information Science*, 24(4), 265–269.
  <doi:10.1002/asi.4630240406>

- **Waltman, L., & van Eck, N. J.** (2012). A new methodology for
  constructing a publication-level classification system of science.
  *Journal of the American Society for Information Science and
  Technology*, 63(12), 2378–2392. <doi:10.1002/asi.22748>

### R Package References

- **R Core Team** (2024). R: A language and environment for statistical
  computing. R Foundation for Statistical Computing, Vienna, Austria.
  <https://www.R-project.org/>

- **Wickham, H., et al.** (2019). Welcome to the tidyverse. *Journal of
  Open Source Software*, 4(43), 1686. <doi:10.21105/joss.01686>

- **Eddelbuettel, D., & François, R.** (2011). Rcpp: Seamless R and C++
  integration. *Journal of Statistical Software*, 40(8), 1–18.
  <doi:10.18637/jss.v040.i08>

### Database Documentation

- **Elsevier** (2024). Scopus Content Coverage Guide.
  <https://www.elsevier.com/solutions/scopus/content>

- **Clarivate** (2024). Web of Science Core Collection.
  <https://clarivate.com/webofsciencegroup/solutions/web-of-science-core-collection/>

- **Dimensions** (2024). Dimensions: The next evolution in linked
  research information. <https://www.dimensions.ai/>

- **National Library of Medicine** (2024). PubMed.
  <https://pubmed.ncbi.nlm.nih.gov/>

- **OpenAlex** (2024). OpenAlex: The open catalog of the global research
  system. <https://openalex.org/>
