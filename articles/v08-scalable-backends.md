# Scalable Storage and Query Backends

## Why This Vignette Exists

### The Challenge of Large Bibliographic Datasets

Modern bibliometric analysis often involves datasets with hundreds of
thousands or even millions of records. Source files from Scopus, Web of
Science, OpenAlex, and other databases can easily reach gigabytes in
size. Loading these datasets entirely into R’s memory becomes
impractical, and traditional data frames cannot scale to meet the
demands of large-scale research projects.

Researchers face several structural challenges:

- **Memory limitations**: R stores data frames in RAM, but bibliographic
  datasets often exceed available memory
- **Query complexity**: Simple subsetting operations become slow when
  datasets grow large
- **Reproducibility**: Sharing large intermediate datasets is cumbersome
  without efficient storage formats
- **Collaboration**: Multiple researchers need to query the same dataset
  without duplicating storage

### The Scalable Backend Solution

`biblioIntegrator` addresses these challenges through two optional
scalable backends:

1.  **Apache Arrow**: Columnar storage optimized for analytical queries
    and fast data retrieval
2.  **DuckDB**: Embedded SQL database that runs queries without a
    separate server

These backends keep the core package lightweight (they are optional
dependencies) while enabling:

- **Larger-than-memory workflows**: Process datasets that exceed
  available RAM
- **SQL queries**: Use familiar SQL syntax for complex data operations
- **Columnar storage**: Efficient storage that speeds up analytical
  queries
- **Zero-administration databases**: No server setup required
- **Cross-platform compatibility**: Works identically on Windows, macOS,
  and Linux

### When to Use This Vignette

This vignette is essential if you:

- Work with bibliographic datasets larger than 1GB
- Need to run SQL queries on your bibliometric data
- Want to store projects efficiently for long-term archival
- Collaborate with team members who need direct database access
- Plan to integrate bibliometric data with external SQL-based tools

### Relationship to Other Vignettes

This vignette completes the `biblioIntegrator` workflow by providing the
storage and query infrastructure. It should be read after:

- `v01-import-harmonize.Rmd`: Understanding how data enters the system
- `v07-foundations-to-advanced-tutorial.Rmd`: The complete workflow
  overview

The backends demonstrated here are used throughout the package’s
advanced features and are essential for production-scale bibliometric
analysis.

## Learning Objectives

After completing this vignette, you will be able to:

1.  **Check backend availability** using
    [`backend_status()`](https://wep69.github.io/biblioIntegrator/reference/backend_status.md)
    to understand your system’s capabilities
2.  **Store bibliographic data in Apache Arrow format** using
    `biblio_store(backend = "arrow")`
3.  **Store bibliographic data in DuckDB** using
    `biblio_store(backend = "duckdb")`
4.  **Load projects back from Arrow storage** using
    `biblio_load(backend = "arrow")`
5.  **Load projects back from DuckDB** using
    `biblio_load(backend = "duckdb")`
6.  **Run SQL queries on DuckDB** using
    [`biblio_query()`](https://wep69.github.io/biblioIntegrator/reference/biblio_query.md)
    for complex data operations
7.  **Compare backend performance** to choose the right tool for your
    use case
8.  **Understand tradeoffs** between Arrow’s columnar storage and
    DuckDB’s SQL capabilities
9.  **Implement best practices** for storage, caching, and query
    optimization
10. **Troubleshoot common issues** with backend initialization and
    queries

## Prerequisites

### Required Packages

Before starting, ensure you have the following packages installed:

``` r

# Core package
install.packages("biblioIntegrator")

# Scalable backends (optional but recommended)
install.packages("arrow")      # For Apache Arrow support
install.packages("duckdb")     # For DuckDB support
install.packages("DBI")        # Database interface (required by DuckDB)

# Optional: for enhanced visualization
install.packages("ggplot2")
install.packages("dplyr")
```

### Verify Installation

Check if backends are available in your R session:

``` r

library(biblioIntegrator)

# Check what's available
status <- backend_status()
print(status)
#>                     backend available
#> biblionetwork biblionetwork      TRUE
#> arrow                 arrow      TRUE
#> duckdb               duckdb      TRUE
#> DBI                     DBI      TRUE
#> bibliometrix   bibliometrix      TRUE
#> openalexR         openalexR      TRUE

# Summary
cat("\nBackend availability summary:\n")
#> 
#> Backend availability summary:
cat(sprintf("  Arrow: %s\n", ifelse(status$available[status$backend == "arrow"], "✓ Available", "✗ Not installed")))
#>   Arrow: ✓ Available
cat(sprintf("  DuckDB: %s\n", ifelse(status$available[status$backend == "duckdb"], "✓ Available", "✗ Not installed")))
#>   DuckDB: ✓ Available
cat(sprintf("  DBI: %s\n", ifelse(status$available[status$backend == "DBI"], "✓ Available", "✗ Not installed")))
#>   DBI: ✓ Available
```

### System Requirements

| Backend | Minimum R Version | Disk Space         | Memory Usage                |
|---------|-------------------|--------------------|-----------------------------|
| Arrow   | R 3.5+            | ~200MB for package | Low (columnar format)       |
| DuckDB  | R 3.5+            | ~100MB for package | Moderate (depends on query) |

**Note**: Both backends are optional. The core `biblioIntegrator`
functionality works without them, but you’ll be limited to in-memory
data frames.

## Understanding the Architecture

### Data Flow in biblioIntegrator

The package follows a modular architecture where data can flow through
different storage backends:

    ┌─────────────────────────────────────────────────────────────┐
    │                     biblio_project                          │
    │  ┌─────────┐ ┌──────────┐ ┌─────────────┐ ┌─────────────┐ │
    │  │  works   │ │ authors  │ │ authorships │ │  keywords   │ │
    │  └─────────┘ └──────────┘ └─────────────┘ └─────────────┘ │
    │  ┌─────────────┐ ┌─────────────┐                           │
    │  │ references  │ │ provenance  │                           │
    │  └─────────────┘ └─────────────┘                           │
    └─────────────────────────────────────────────────────────────┘
                                │
                  ┌─────────────┼─────────────┐
                  ▼             ▼             ▼
            ┌──────────┐  ┌──────────┐  ┌──────────┐
            │ Memory   │  │  Arrow   │  │  DuckDB  │
            │ (default)│  │ (columnar)│  │  (SQL)   │
            └──────────┘  └──────────┘  └──────────┘
                  │             │             │
                  └─────────────┼─────────────┘
                                ▼
                        ┌──────────────┐
                        │  Analysis    │
                        │   Workflow   │
                        └──────────────┘

### The biblio_project Structure

A `biblio_project` is a list containing six standardized data frames:

| Table         | Description           | Key Columns                     |
|---------------|-----------------------|---------------------------------|
| `works`       | Bibliographic records | work_id, title, year, journal   |
| `authors`     | Author information    | author_id, name, affiliation    |
| `authorships` | Work-author links     | work_id, author_id, position    |
| `keywords`    | Keywords/subjects     | work_id, keyword, type          |
| `references`  | Citation links        | citing_id, cited_id             |
| `provenance`  | Data origin tracking  | table, field, source, timestamp |

This structure is preserved across all backends, ensuring consistency
whether you use in-memory data frames, Arrow, or DuckDB.

## Apache Arrow Backend

### What is Apache Arrow?

Apache Arrow is a cross-language development platform for in-memory
columnar data. It specifies a standardized language-independent columnar
memory format for flat and hierarchical data, organized for efficient
analytic operations on modern hardware.

#### Key Features

- **Columnar Storage**: Data is stored by column, not by row. This is
  optimal for analytical queries that typically access a subset of
  columns.
- **Zero-Copy Reads**: Arrow’s memory mapping allows reading data
  without copying, reducing memory overhead.
- **Compression**: Built-in support for efficient compression algorithms
  (Snappy, Zstd, LZ4, GZIP)
- **Cross-Language**: Arrow format is readable by R, Python, Julia, and
  many other languages
- **Parquet Support**: Arrow reads and writes Apache Parquet files, the
  de facto standard for columnar storage

#### Columnar vs. Row-Based Storage

Understanding the difference is crucial for choosing the right backend:

    Row-Based Storage (Traditional R data frames):
    ┌────────────────────────────────────────────────────────┐
    │ Row 1: work_id | title | year | journal | doi | ...   │
    │ Row 2: work_id | title | year | journal | doi | ...   │
    │ Row 3: work_id | title | year | journal | doi | ...   │
    └────────────────────────────────────────────────────────┘
    Access pattern: Load entire row even if you only need 'year'

    Columnar Storage (Apache Arrow/Parquet):
    ┌────────────────────────────────────────────────────────┐
    │ work_id: [id1, id2, id3, ...]                          │
    │ title:   [title1, title2, title3, ...]                 │
    │ year:    [2020, 2021, 2022, ...]                       │
    │ journal: [journal1, journal2, journal3, ...]           │
    └────────────────────────────────────────────────────────┘
    Access pattern: Load only the columns you need

**Benefits for Bibliometric Data**: - Queries like “count works by year”
only read the `year` column - Aggregations are faster due to better CPU
cache utilization - Compression is more effective on homogeneous column
data

### Installing Arrow

``` r

# Install from CRAN
install.packages("arrow")

# Verify installation
library(arrow)
arrow::arrow_info()
```

#### Platform-Specific Notes

| Platform | Notes                                                     |
|----------|-----------------------------------------------------------|
| Windows  | Works out of the box with pre-built binaries              |
| macOS    | Requires Xcode command line tools for source installation |
| Linux    | May need `libarrow-dev` on Ubuntu/Debian                  |

### Storing Data with Arrow

#### Basic Storage

The
[`biblio_store()`](https://wep69.github.io/biblioIntegrator/reference/biblio_store.md)
function stores a `biblio_project` in Arrow format:

``` r

library(biblioIntegrator)

# Create a project
x <- as_biblio_project(example_biblio())

# Create a temporary directory for storage
arrow_path <- file.path(tempdir(), "biblio_arrow")

# Store in Arrow format
biblio_store(x, path = arrow_path, engine = "arrow")

# Check what was created
list.files(arrow_path)
```

**Output Structure**:

    biblio_arrow/
    ├── works.parquet
    ├── authors.parquet
    ├── authorships.parquet
    ├── keywords.parquet
    ├── references.parquet
    └── provenance.parquet

#### Understanding Parquet Files

Each table in your `biblio_project` becomes a separate Parquet file:

``` r

if (requireNamespace("arrow", quietly = TRUE)) {
  library(arrow)

  # Read Parquet metadata without loading data
  meta <- read_parquet_schema(file.path(arrow_path, "works.parquet"))
  print(meta)

  # Check file size
  file_info <- file.info(file.path(arrow_path, "works.parquet"))
  cat(sprintf("File size: %.2f KB\n", file_info$size / 1024))
}
```

#### Storage with Overwrite

If the directory already exists, you can choose to overwrite:

``` r

# First store
biblio_store(x, path = arrow_path, engine = "arrow")

# Overwrite existing storage
biblio_store(x, path = arrow_path, engine = "arrow", overwrite = TRUE)
```

**Warning**: Overwriting deletes all existing files in the directory.
Use with caution.

#### Compression Options

Arrow uses Snappy compression by default. For larger datasets, you can
use more aggressive compression:

``` r

if (requireNamespace("arrow", quietly = TRUE)) {
  library(arrow)

  # Store with Zstd compression (better ratio, slightly slower)
  write_parquet(x$works,
                sink = file.path(arrow_path, "works_zstd.parquet"),
                compression = "zstd",
                compression_level = 3)
}
```

| Compression      | Ratio    | Speed     | Best For          |
|------------------|----------|-----------|-------------------|
| Snappy (default) | Moderate | Fastest   | General use       |
| Zstd             | High     | Fast      | Large datasets    |
| GZIP             | Highest  | Slow      | Archival storage  |
| LZ4              | Low      | Very fast | Temporary storage |

### Loading Data from Arrow

#### Basic Loading

``` r

# Load project from Arrow storage
project_loaded <- biblio_load(path = arrow_path, engine = "arrow")

# Verify structure
str(project_loaded, max.level = 1)

# Check dimensions
cat(sprintf("Works: %d rows\n", nrow(project_loaded$works)))
cat(sprintf("Authors: %d rows\n", nrow(project_loaded$authors)))
```

#### Lazy Loading with Arrow

Arrow supports lazy evaluation - you can read metadata without loading
data:

``` r

if (requireNamespace("arrow", quietly = TRUE)) {
  library(arrow)

  # Open Parquet file as Arrow Table (memory-mapped, no data loaded yet)
  works_arrow <- read_parquet(file.path(arrow_path, "works.parquet"))

  # Only loads 'year' column when accessed
  years <- works_arrow$year

  # Or filter without loading full dataset
  recent <- dplyr::filter(works_arrow, year >= 2020)
}
```

#### Selective Column Loading

One of Arrow’s strengths is loading only needed columns:

``` r

if (requireNamespace("arrow", quietly = TRUE)) {
  library(arrow)

  # Load only specific columns
  works_subset <- read_parquet(
    file.path(arrow_path, "works.parquet"),
    col_select = c("work_id", "title", "year")
  )

  cat(sprintf("Full dataset: %d columns\n",
              ncol(read_parquet(file.path(arrow_path, "works.parquet")))))
  cat(sprintf("Subset: %d columns\n", ncol(works_subset)))
}
```

### Arrow Use Cases

#### Large-Scale Descriptive Statistics

Arrow excels at computing statistics across large datasets:

``` r

if (requireNamespace("arrow", quietly = TRUE) &&
    requireNamespace("dplyr", quietly = TRUE)) {
  library(arrow)
  library(dplyr)

  # Open Arrow dataset
  works <- read_parquet(file.path(arrow_path, "works.parquet"))

  # Compute statistics efficiently
  year_stats <- works %>%
    group_by(year) %>%
    summarise(
      n_works = n(),
      n_journals = n_distinct(journal),
      .groups = "drop"
    )

  print(head(year_stats))
}
```

#### Combining Multiple Tables

``` r

if (requireNamespace("arrow", quietly = TRUE) &&
    requireNamespace("dplyr", quietly = TRUE)) {
  library(arrow)
  library(dplyr)

  # Load tables
  works <- read_parquet(file.path(arrow_path, "works.parquet"))
  authorships <- read_parquet(file.path(arrow_path, "authorships.parquet"))
  authors <- read_parquet(file.path(arrow_path, "authors.parquet"))

  # Join to get author information per work
  author_works <- works %>%
    inner_join(authorships, by = "work_id") %>%
    inner_join(authors, by = "author_id") %>%
    select(work_id, title, year, author_name = name, affiliation)

  print(head(author_works))
}
```

## DuckDB Backend

### What is DuckDB?

DuckDB is an in-process SQL OLAP database management system. It is
designed for analytical query processing and can run entirely within
your R process without requiring a separate server.

#### Key Features

- **Embedded Database**: No server setup, no configuration, no
  administration
- **Full SQL Support**: Complete SQL syntax including window functions,
  CTEs, and complex joins
- **Fast Analytics**: Optimized for analytical queries (OLAP) rather
  than transactional workloads (OLTP)
- **Zero Configuration**: Works out of the box with sensible defaults
- **Portable**: Database is a single file that can be moved between
  systems

#### DuckDB vs. Traditional Databases

| Feature           | DuckDB    | PostgreSQL/MySQL | SQLite         |
|-------------------|-----------|------------------|----------------|
| Server Required   | No        | Yes              | No             |
| Setup Complexity  | None      | High             | Low            |
| SQL Completeness  | Full      | Full             | Partial        |
| Analytical Speed  | Fast      | Moderate         | Slow           |
| Concurrent Writes | Single    | Multiple         | Single         |
| Best For          | Analytics | Production apps  | Simple storage |

#### Why DuckDB for Bibliometrics?

Bibliometric analysis involves: - **Aggregation queries**: Count
publications by year, author, journal - **Text matching**: Find
keywords, filter by title patterns - **Network queries**: Traverse
citation networks - **Complex joins**: Link works, authors, keywords,
and references

DuckDB’s SQL interface handles all these operations efficiently without
requiring you to learn new APIs.

### Installing DuckDB

``` r

# Install required packages
install.packages("duckdb")
install.packages("DBI")

# Verify installation
library(duckdb)
library(DBI)

# Check DuckDB version
cat("DuckDB version:", as.character(packageVersion("duckdb")), "\n")
```

### Storing Data with DuckDB

#### Basic Storage

``` r

library(biblioIntegrator)

# Create a project
x <- as_biblio_project(example_biblio())

# Create a DuckDB database file
duckdb_path <- file.path(tempdir(), "biblio.duckdb")

# Store in DuckDB
biblio_store(x, path = duckdb_path, engine = "duckdb")

# Check file size
file_info <- file.info(duckdb_path)
cat(sprintf("Database size: %.2f KB\n", file_info$size / 1024))
```

#### Understanding DuckDB Storage

When you store a `biblio_project` in DuckDB:

1.  A `.duckdb` file is created at the specified path
2.  Six tables are created (works, authors, authorships, keywords,
    references, provenance)
3.  Each table mirrors its R data frame counterpart
4.  Indexes are automatically created on primary keys

#### Storage with Overwrite

``` r

# Store (creates new database)
biblio_store(x, path = duckdb_path, engine = "duckdb")

# Overwrite existing database
biblio_store(x, path = duckdb_path, engine = "duckdb", overwrite = TRUE)
```

**Note**: DuckDB files are single files, so overwriting replaces the
entire database.

### Querying DuckDB with biblio_query()

#### Basic SQL Queries

The
[`biblio_query()`](https://wep69.github.io/biblioIntegrator/reference/biblio_query.md)
function executes SQL queries on a DuckDB database:

``` r

if (requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("DBI", quietly = TRUE)) {
  library(biblioIntegrator)

  # Store example data first
  x <- as_biblio_project(example_biblio())
  duckdb_path <- file.path(tempdir(), "biblio_query.duckdb")
  biblio_store(x, path = duckdb_path, engine = "duckdb")

  # Query: Count works by year
  year_counts <- biblio_query(
    duckdb_path,
    "SELECT year, COUNT(*) AS n_works FROM works GROUP BY year ORDER BY year"
  )
  print(year_counts)
}
```

#### Common Query Patterns

##### Counting and Aggregation

``` r

if (requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("DBI", quietly = TRUE)) {
  # Top 10 journals by publication count
  top_journals <- biblio_query(
    duckdb_path,
    "SELECT journal, COUNT(*) AS n_publications
     FROM works
     WHERE journal IS NOT NULL
     GROUP BY journal
     ORDER BY n_publications DESC
     LIMIT 10"
  )
  print(top_journals)

  # Author productivity
  author_productivity <- biblio_query(
    duckdb_path,
    "SELECT a.name, COUNT(DISTINCT aw.work_id) AS n_works
     FROM authors a
     INNER JOIN authorships aw ON a.author_id = aw.author_id
     GROUP BY a.author_id, a.name
     ORDER BY n_works DESC
     LIMIT 10"
  )
  print(author_productivity)
}
```

##### Filtering and Subsetting

``` r

if (requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("DBI", quietly = TRUE)) {
  # Works from 2020 onwards
  recent_works <- biblio_query(
    duckdb_path,
    "SELECT work_id, title, year, journal
     FROM works
     WHERE year >= 2020
     ORDER BY year DESC"
  )
  cat(sprintf("Recent works: %d\n", nrow(recent_works)))

  # Works with specific keywords
  keyword_works <- biblio_query(
    duckdb_path,
    "SELECT DISTINCT w.work_id, w.title, w.year
     FROM works w
     INNER JOIN keywords k ON w.work_id = k.work_id
     WHERE k.keyword ILIKE '%bibliometric%'"
  )
  cat(sprintf("Works with 'bibliometric' keyword: %d\n", nrow(keyword_works)))
}
```

##### Complex Joins

``` r

if (requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("DBI", quietly = TRUE)) {
  # Top cited works with author information
  top_cited <- biblio_query(
    duckdb_path,
    "SELECT w.title, w.year, w.journal,
            COUNT(DISTINCT r.citing_id) AS citation_count,
            GROUP_CONCAT(DISTINCT a.name) AS authors
     FROM works w
     LEFT JOIN references r ON w.work_id = r.cited_id
     LEFT JOIN authorships aw ON w.work_id = aw.work_id
     LEFT JOIN authors a ON aw.author_id = a.author_id
     WHERE w.title IS NOT NULL
     GROUP BY w.work_id, w.title, w.year, w.journal
     ORDER BY citation_count DESC
     LIMIT 10"
  )
  print(top_cited)
}
```

##### Window Functions

``` r

if (requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("DBI", quietly = TRUE)) {
  # Rank works by citations within each year
  ranked_works <- biblio_query(
    duckdb_path,
    "WITH citation_counts AS (
       SELECT w.work_id, w.title, w.year,
              COUNT(r.citing_id) AS n_citations
       FROM works w
       LEFT JOIN references r ON w.work_id = r.cited_id
       GROUP BY w.work_id, w.title, w.year
     )
     SELECT title, year, n_citations,
            RANK() OVER (PARTITION BY year ORDER BY n_citations DESC) AS rank_in_year
     FROM citation_counts
     WHERE n_citations > 0
     ORDER BY year, rank_in_year"
  )
  print(head(ranked_works, 15))
}
```

##### Common Table Expressions (CTEs)

``` r

if (requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("DBI", quietly = TRUE)) {
  # Author collaboration network analysis
  collaboration_stats <- biblio_query(
    duckdb_path,
    "WITH author_works AS (
       SELECT a.author_id, a.name, COUNT(DISTINCT aw.work_id) AS n_works
       FROM authors a
       INNER JOIN authorships aw ON a.author_id = aw.author_id
       GROUP BY a.author_id, a.name
     ),
     collaborations AS (
       SELECT aw1.author_id AS author1, aw2.author_id AS author2,
              COUNT(DISTINCT aw1.work_id) AS n_shared_works
       FROM authorships aw1
       INNER JOIN authorships aw2 ON aw1.work_id = aw2.work_id
                                 AND aw1.author_id < aw2.author_id
       GROUP BY aw1.author_id, aw2.author_id
     )
     SELECT a1.name AS author1_name, a2.name AS author2_name,
            c.n_shared_works, a1.n_works AS author1_total, a2.n_works AS author2_total
     FROM collaborations c
     INNER JOIN author_works a1 ON c.author1 = a1.author_id
     INNER JOIN author_works a2 ON c.author2 = a2.author_id
     ORDER BY c.n_shared_works DESC
     LIMIT 10"
  )
  print(collaboration_stats)
}
```

#### Parameterized Queries

For security and flexibility, use parameterized queries when possible:

``` r

if (requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("DBI", quietly = TRUE)) {
  # Connect directly for parameterized queries
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = duckdb_path, read_only = TRUE)

  # Parameterized query
  year_param <- 2021
  result <- DBI::dbGetQuery(
    con,
    "SELECT * FROM works WHERE year = ?",
    params = list(year_param)
  )
  print(head(result))

  DBI::dbDisconnect(con, shutdown = TRUE)
}
```

### Loading Data from DuckDB

#### Basic Loading

``` r

if (requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("DBI", quietly = TRUE)) {
  # Load project from DuckDB
  project_loaded <- biblio_load(path = duckdb_path, engine = "duckdb")

  # Verify structure
  cat("Loaded tables:\n")
  for (name in names(project_loaded)) {
    cat(sprintf("  %s: %d rows, %d columns\n",
                name, nrow(project_loaded[[name]]), ncol(project_loaded[[name]])))
  }
}
```

#### Loading vs. Querying

Choose between
[`biblio_load()`](https://wep69.github.io/biblioIntegrator/reference/biblio_load.md)
and
[`biblio_query()`](https://wep69.github.io/biblioIntegrator/reference/biblio_query.md)
based on your needs:

| Operation | Use [`biblio_load()`](https://wep69.github.io/biblioIntegrator/reference/biblio_load.md) | Use [`biblio_query()`](https://wep69.github.io/biblioIntegrator/reference/biblio_query.md) |
|----|----|----|
| Get entire table | ✓ | ✓ (but slower) |
| Filter rows | ✗ | ✓ |
| Aggregate data | ✗ | ✓ |
| Join tables | ✗ | ✓ |
| Load full project | ✓ | ✗ |
| Memory usage | High (loads all) | Low (loads result) |

**Best Practice**: Use
[`biblio_query()`](https://wep69.github.io/biblioIntegrator/reference/biblio_query.md)
for exploration and analysis; use
[`biblio_load()`](https://wep69.github.io/biblioIntegrator/reference/biblio_load.md)
when you need the complete dataset in R memory.

### DuckDB Use Cases

#### Exploratory Data Analysis

``` r

if (requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("DBI", quietly = TRUE)) {
  # Database summary statistics
  summary_stats <- biblio_query(
    duckdb_path,
    "SELECT
       'works' AS table_name, COUNT(*) AS n_rows FROM works
     UNION ALL
     SELECT 'authors', COUNT(*) FROM authors
     UNION ALL
     SELECT 'authorships', COUNT(*) FROM authorships
     UNION ALL
     SELECT 'keywords', COUNT(*) FROM keywords
     UNION ALL
     SELECT 'references', COUNT(*) FROM references"
  )
  print(summary_stats)
}
```

#### Temporal Analysis

``` r

if (requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("DBI", quietly = TRUE)) {
  # Publication growth over time
  growth <- biblio_query(
    duckdb_path,
    "WITH yearly_counts AS (
       SELECT year, COUNT(*) AS n_publications
       FROM works
       WHERE year IS NOT NULL
       GROUP BY year
     )
     SELECT year, n_publications,
            SUM(n_publications) OVER (ORDER BY year) AS cumulative,
            LAG(n_publications) OVER (ORDER BY year) AS prev_year,
            ROUND(
              (n_publications - LAG(n_publications) OVER (ORDER BY year)) * 100.0 /
              LAG(n_publications) OVER (ORDER BY year), 2
            ) AS growth_pct
     FROM yearly_counts
     ORDER BY year"
  )
  print(growth)
}
```

#### Network Preparation

``` r

if (requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("DBI", quietly = TRUE)) {
  # Co-authorship edge list for network analysis
  coauthor_edges <- biblio_query(
    duckdb_path,
    "SELECT aw1.author_id AS source, aw2.author_id AS target,
            COUNT(DISTINCT aw1.work_id) AS weight
     FROM authorships aw1
     INNER JOIN authorships aw2 ON aw1.work_id = aw2.work_id
                               AND aw1.author_id < aw2.author_id
     GROUP BY aw1.author_id, aw2.author_id
     HAVING COUNT(DISTINCT aw1.work_id) >= 2
     ORDER BY weight DESC"
  )
  cat(sprintf("Co-authorship edges (weight >= 2): %d\n", nrow(coauthor_edges)))
  print(head(coauthor_edges))
}
```

## Step-by-Step Workflow

### Complete Example: From Raw Data to Query

This section demonstrates a complete workflow from data creation to
advanced queries:

#### Step 1: Check Backend Availability

``` r

library(biblioIntegrator)

# Always start by checking what's available
status <- backend_status()
print(status)

# Determine which backends to use
can_use_arrow <- status$available[status$backend == "arrow"]
can_use_duckdb <- status$available[status$backend == "duckdb"] &&
                  status$available[status$backend == "DBI"]

cat("\nWorkflow plan:\n")
cat(sprintf("  Arrow storage: %s\n", ifelse(can_use_arrow, "ENABLED", "DISABLED")))
cat(sprintf("  DuckDB storage: %s\n", ifelse(can_use_duckdb, "ENABLED", "DISABLED")))
```

#### Step 2: Prepare Example Data

``` r

# Load example bibliometric data
raw_data <- example_biblio()

# Inspect structure
str(raw_data, max.level = 1)
cat(sprintf("\nRaw data contains %d fields\n", length(raw_data)))

# Convert to biblio_project
x <- as_biblio_project(raw_data, source = "example_data")

# Verify project structure
cat("\nbiblio_project structure:\n")
for (name in names(x)) {
  cat(sprintf("  %s: %d rows, %d columns\n",
              name, nrow(x[[name]]), ncol(x[[name]])))
}
```

#### Step 3: Store in Arrow Format

``` r

if (can_use_arrow) {
  # Create output directory
  arrow_dir <- file.path(tempdir(), "workflow_arrow")

  # Store project
  cat("Storing in Arrow format...\n")
  biblio_store(x, path = arrow_dir, engine = "arrow")

  # Verify storage
  parquet_files <- list.files(arrow_dir, pattern = "\\.parquet$")
  cat(sprintf("Created %d Parquet files:\n", length(parquet_files)))
  for (f in parquet_files) {
    fsize <- file.info(file.path(arrow_dir, f))$size
    cat(sprintf("  %s (%.1f KB)\n", f, fsize / 1024))
  }
} else {
  cat("Arrow not available, skipping...\n")
}
```

#### Step 4: Store in DuckDB Format

``` r

if (can_use_duckdb) {
  # Create DuckDB file
  duckdb_file <- file.path(tempdir(), "workflow.duckdb")

  # Store project
  cat("Storing in DuckDB format...\n")
  biblio_store(x, path = duckdb_file, engine = "duckdb")

  # Verify storage
  fsize <- file.info(duckdb_file)$size
  cat(sprintf("Created DuckDB file: %s (%.1f KB)\n", basename(duckdb_file), fsize / 1024))

  # List tables
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = duckdb_file, read_only = TRUE)
  tables <- DBI::dbListTables(con)
  DBI::dbDisconnect(con, shutdown = TRUE)
  cat(sprintf("Tables in database: %s\n", paste(tables, collapse = ", ")))
} else {
  cat("DuckDB not available, skipping...\n")
}
```

#### Step 5: Run SQL Queries

``` r

if (can_use_duckdb) {
  cat("Running exploration queries...\n\n")

  # Query 1: Publication count by year
  cat("=== Publication Count by Year ===\n")
  q1 <- biblio_query(duckdb_file, "SELECT year, COUNT(*) AS n FROM works WHERE year IS NOT NULL GROUP BY year ORDER BY year")
  print(q1)

  # Query 2: Top journals
  cat("\n=== Top 5 Journals ===\n")
  q2 <- biblio_query(duckdb_file, "SELECT journal, COUNT(*) AS n FROM works WHERE journal IS NOT NULL GROUP BY journal ORDER BY n DESC LIMIT 5")
  print(q2)

  # Query 3: Author productivity
  cat("\n=== Top 5 Authors by Productivity ===\n")
  q3 <- biblio_query(duckdb_file,
    "SELECT a.name, COUNT(DISTINCT aw.work_id) AS n_works
     FROM authors a
     INNER JOIN authorships aw ON a.author_id = aw.author_id
     GROUP BY a.author_id, a.name
     ORDER BY n_works DESC
     LIMIT 5")
  print(q3)

  # Query 4: Keyword frequency
  cat("\n=== Top 5 Keywords ===\n")
  q4 <- biblio_query(duckdb_file,
    "SELECT keyword, COUNT(*) AS n
     FROM keywords
     GROUP BY keyword
     ORDER BY n DESC
     LIMIT 5")
  print(q4)
} else {
  cat("DuckDB not available, skipping queries...\n")
}
```

#### Step 6: Load and Verify

``` r

# Load from Arrow
if (can_use_arrow) {
  cat("Loading from Arrow...\n")
  x_arrow <- biblio_load(path = arrow_dir, engine = "arrow")

  cat("\nVerification:\n")
  cat(sprintf("  Original works: %d\n", nrow(x$works)))
  cat(sprintf("  Loaded works: %d\n", nrow(x_arrow$works)))
  cat(sprintf("  Match: %s\n", ifelse(identical(nrow(x$works), nrow(x_arrow$works)), "✓ YES", "✗ NO")))
}

# Load from DuckDB
if (can_use_duckdb) {
  cat("\nLoading from DuckDB...\n")
  x_duckdb <- biblio_load(path = duckdb_file, engine = "duckdb")

  cat("\nVerification:\n")
  cat(sprintf("  Original works: %d\n", nrow(x$works)))
  cat(sprintf("  Loaded works: %d\n", nrow(x_duckdb$works)))
  cat(sprintf("  Match: %s\n", ifelse(identical(nrow(x$works), nrow(x_duckdb$works)), "✓ YES", "✗ NO")))
}
```

#### Step 7: Compare Results

``` r

cat("=== Comparison Summary ===\n\n")

# Compare storage formats
if (can_use_arrow && can_use_duckdb) {
  arrow_size <- sum(file.info(list.files(arrow_dir, full.names = TRUE))$size)
  duckdb_size <- file.info(duckdb_file)$size

  cat("Storage size comparison:\n")
  cat(sprintf("  Arrow: %.2f KB (%d files)\n", arrow_size / 1024, length(list.files(arrow_dir))))
  cat(sprintf("  DuckDB: %.2f KB (1 file)\n", duckdb_size / 1024))
  cat(sprintf("  Ratio: Arrow is %.1fx %s than DuckDB\n",
              abs(arrow_size / duckdb_size),
              ifelse(arrow_size > duckdb_size, "larger", "smaller")))

  # Compare data integrity
  cat("\nData integrity check:\n")
  for (table_name in c("works", "authors", "authorships", "keywords", "references")) {
    arrow_rows <- nrow(x_arrow[[table_name]])
    duckdb_rows <- nrow(x_duckdb[[table_name]])
    original_rows <- nrow(x[[table_name]])
    match <- arrow_rows == duckdb_rows && duckdb_rows == original_rows
    cat(sprintf("  %s: %s (%d rows)\n",
                table_name,
                ifelse(match, "✓", "✗ MISMATCH"),
                original_rows))
  }
}
```

## Performance Considerations

### Arrow vs. DuckDB: When to Use Which

#### Decision Framework

                          ┌─────────────────────────────────────┐
                          │      What is your primary need?     │
                          └─────────────────┬───────────────────┘
                                            │
                        ┌───────────────────┼───────────────────┐
                        ▼                   ▼                   ▼
                ┌───────────────┐   ┌───────────────┐   ┌───────────────┐
                │ Fast column   │   │ Complex SQL   │   │ Full project  │
                │ aggregations  │   │ queries       │   │ loading       │
                └───────┬───────┘   └───────┬───────┘   └───────┬───────┘
                        │                   │                   │
                        ▼                   ▼                   ▼
                ┌───────────────┐   ┌───────────────┐   ┌───────────────┐
                │   Use Arrow   │   │  Use DuckDB   │   │ Either works  │
                │   (faster)    │   │  (more power) │   │ (preference)  │
                └───────────────┘   └───────────────┘   └───────────────┘

#### Detailed Comparison

| Criterion | Arrow | DuckDB | Recommendation |
|----|----|----|----|
| **Column aggregations** | ★★★★★ | ★★★★ | Arrow for simple stats |
| **Complex joins** | ★★★ | ★★★★★ | DuckDB for multi-table |
| **SQL support** | Limited | Full | DuckDB for SQL users |
| **Memory efficiency** | ★★★★★ | ★★★★ | Arrow for larger datasets |
| **File size** | Larger (columnar) | Compact | DuckDB for disk space |
| **Portability** | ★★★★★ | ★★★★ | Arrow for cross-language |
| **Setup complexity** | Low | Very low | Both are easy |
| **Read speed** | ★★★★★ | ★★★★ | Arrow for sequential reads |
| **Write speed** | ★★★ | ★★★★ | DuckDB for frequent updates |

#### Use Case Scenarios

##### Scenario 1: Quick Descriptive Statistics

**Best Choice: Arrow**

``` r

# Arrow: Load only needed columns
if (requireNamespace("arrow", quietly = TRUE)) {
  works <- arrow::read_parquet(file.path(arrow_dir, "works.parquet"),
                               col_select = c("year", "journal"))
  year_counts <- table(works$year)
  journal_counts <- sort(table(works$journal), decreasing = TRUE)[1:10]
}
```

##### Scenario 2: Complex Analytical Query

**Best Choice: DuckDB**

``` r

# DuckDB: Execute complex SQL directly
if (requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("DBI", quietly = TRUE)) {
  result <- biblio_query(duckdb_file,
    "WITH author_metrics AS (
       SELECT a.author_id, a.name,
              COUNT(DISTINCT aw.work_id) AS n_works,
              COUNT(DISTINCT k.keyword) AS n_keywords
       FROM authors a
       INNER JOIN authorships aw ON a.author_id = aw.author_id
       LEFT JOIN keywords k ON aw.work_id = k.work_id
       GROUP BY a.author_id, a.name
     )
     SELECT name, n_works, n_keywords,
            n_keywords * 1.0 / n_works AS keywords_per_work
     FROM author_metrics
     WHERE n_works >= 2
     ORDER BY keywords_per_work DESC
     LIMIT 10")
}
```

##### Scenario 3: Long-Term Archival

**Best Choice: Arrow**

Arrow’s Parquet format is: - Self-describing (schema embedded) - Widely
supported (Python, Spark, etc.) - Efficient for archival (columnar
compression) - Future-proof (industry standard)

##### Scenario 4: Interactive Exploration

**Best Choice: DuckDB**

DuckDB’s SQL interface allows: - Rapid iteration with different
queries - No need to reload data between queries - Complex subqueries
and CTEs - Window functions for running calculations

### Memory vs. Disk Tradeoffs

#### Memory Usage Patterns

``` r

# Monitor memory usage com base R, sem dependencia externa: gc() informa o uso
# corrente em megabytes na coluna "used".
monitor_memory <- function(expr, label = "Operation") {
  gc(reset = TRUE)
  before <- sum(gc()[, "used"])
  result <- force(expr)
  after <- sum(gc()[, "used"])
  cat(sprintf("%s: %.2f MB\n", label, after - before))
  invisible(result)
}

# Example: Compare loading strategies
if (requireNamespace("arrow", quietly = TRUE) &&
    requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("DBI", quietly = TRUE)) {
  cat("Memory usage comparison:\n")

  # Arrow: Load specific columns
  monitor_memory(
    arrow::read_parquet(file.path(arrow_dir, "works.parquet"),
                        col_select = c("work_id", "year")),
    "Arrow (2 columns)"
  )

  # Arrow: Load all columns
  monitor_memory(
    arrow::read_parquet(file.path(arrow_dir, "works.parquet")),
    "Arrow (all columns)"
  )

  # DuckDB: Load entire table
  monitor_memory(
    biblio_load(duckdb_file, "duckdb"),
    "DuckDB (full project)"
  )
}
```

#### Disk Space Optimization

| Strategy         | Arrow Impact      | DuckDB Impact        |
|------------------|-------------------|----------------------|
| Compression      | Reduce 60-80%     | Built-in compression |
| Column selection | N/A (columnar)    | N/A (row-based)      |
| Partitioning     | Supported         | Not applicable       |
| Data types       | Use smaller types | Use smaller types    |

#### Query Complexity Considerations

**Simple Queries** (1-2 operations): - Arrow: Faster with columnar
access - DuckDB: Slightly slower due to SQL parsing

**Complex Queries** (joins, subqueries, CTEs): - Arrow: Requires R-level
joins, slower - DuckDB: Optimized query planner, faster

**Recommendation**: For queries involving more than 2 tables or complex
filtering, prefer DuckDB.

### Benchmarking Your Workflow

``` r

benchmark_backends <- function(x, n_reps = 3) {
  results <- data.frame(
    operation = character(),
    backend = character(),
    time_seconds = numeric(),
    stringsAsFactors = FALSE
  )

  arrow_dir <- file.path(tempdir(), "bench_arrow")
  duckdb_file <- file.path(tempdir(), "bench.duckdb")

  # Setup
  biblio_store(x, arrow_dir, "arrow")
  biblio_store(x, duckdb_file, "duckdb")

  # Benchmark 1: Store operation
  for (i in seq_len(n_reps)) {
    t1 <- system.time(biblio_store(x, tempfile(), "arrow"))
    results <- rbind(results, data.frame(operation = "store", backend = "arrow",
                                         time_seconds = t1["elapsed"]))

    t2 <- system.time(biblio_store(x, tempfile(fileext = ".duckdb"), "duckdb"))
    results <- rbind(results, data.frame(operation = "store", backend = "duckdb",
                                         time_seconds = t2["elapsed"]))
  }

  # Benchmark 2: Load operation
  for (i in seq_len(n_reps)) {
    t1 <- system.time(biblio_load(arrow_dir, "arrow"))
    results <- rbind(results, data.frame(operation = "load", backend = "arrow",
                                         time_seconds = t1["elapsed"]))

    t2 <- system.time(biblio_load(duckdb_file, "duckdb"))
    results <- rbind(results, data.frame(operation = "load", backend = "duckdb",
                                         time_seconds = t2["elapsed"]))
  }

  # Benchmark 3: Simple query
  for (i in seq_len(n_reps)) {
    t1 <- system.time({
      works <- arrow::read_parquet(file.path(arrow_dir, "works.parquet"))
      table(works$year)
    })
    results <- rbind(results, data.frame(operation = "query_simple", backend = "arrow",
                                         time_seconds = t1["elapsed"]))

    t2 <- system.time(biblio_query(duckdb_file,
      "SELECT year, COUNT(*) FROM works GROUP BY year"))
    results <- rbind(results, data.frame(operation = "query_simple", backend = "duckdb",
                                         time_seconds = t2["elapsed"]))
  }

  # Calculate averages
  aggregate(time_seconds ~ operation + backend, data = results, FUN = mean)
}

# Run benchmark (requires both backends)
if (requireNamespace("arrow", quietly = TRUE) &&
    requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("DBI", quietly = TRUE)) {
  bench_results <- benchmark_backends(x)
  print(bench_results)
}
```

## Common Mistakes

### Mistake 1: Not Checking Backend Availability

**Problem**: Code fails with cryptic error messages.

**Wrong Approach**:

``` r

# This will fail if arrow is not installed
biblio_store(x, path = "data/arrow", engine = "arrow")
```

**Correct Approach**:

``` r

# Always check first
if (requireNamespace("arrow", quietly = TRUE)) {
  biblio_store(x, path = "data/arrow", engine = "arrow")
} else {
  message("Arrow not installed. Install with: install.packages('arrow')")
}
```

**Best Practice**: Use
[`backend_status()`](https://wep69.github.io/biblioIntegrator/reference/backend_status.md)
at the start of your script:

``` r

status <- backend_status()
if (!status$available[status$backend == "arrow"]) {
  stop("Arrow is required for this workflow. Install with: install.packages('arrow')")
}
```

### Mistake 2: Confusing Arrow and DuckDB Use Cases

**Problem**: Using the wrong backend for your task.

**Wrong Approach**:

``` r

# Using Arrow for complex SQL queries - inefficient
if (requireNamespace("arrow", quietly = TRUE)) {
  works <- arrow::read_parquet("data/arrow/works.parquet")
  authorships <- arrow::read_parquet("data/arrow/authorships.parquet")
  authors <- arrow::read_parquet("data/arrow/authors.parquet")

  # Complex join in R - slow for large datasets
  result <- merge(merge(works, authorships, by = "work_id"),
                  authors, by = "author_id")
}
```

**Correct Approach**:

``` r

# Use DuckDB for complex queries
if (requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("DBI", quietly = TRUE)) {
  # Single SQL query does all the work
  result <- biblio_query("biblio.duckdb",
    "SELECT w.*, a.name, a.affiliation
     FROM works w
     INNER JOIN authorships aw ON w.work_id = aw.work_id
     INNER JOIN authors a ON aw.author_id = a.author_id")
}
```

**Decision Guide**: - **Arrow**: Column aggregations, statistics, data
export - **DuckDB**: Complex joins, filtering, SQL-based analysis

### Mistake 3: Not Closing DuckDB Connections

**Problem**: Database file becomes locked or corrupted.

**Wrong Approach**:

``` r

# Don't do this - connection not properly closed
con <- DBI::dbConnect(duckdb::duckdb(), dbdir = "biblio.duckdb")
result <- DBI::dbGetQuery(con, "SELECT * FROM works")
# Connection still open!
```

**Correct Approach**:

``` r

# Use on.exit for guaranteed cleanup
con <- DBI::dbConnect(duckdb::duckdb(), dbdir = "biblio.duckdb")
on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

result <- DBI::dbGetQuery(con, "SELECT * FROM works")
# Connection automatically closed when function exits
```

**Note**:
[`biblio_query()`](https://wep69.github.io/biblioIntegrator/reference/biblio_query.md)
and
[`biblio_load()`](https://wep69.github.io/biblioIntegrator/reference/biblio_load.md)
handle connection lifecycle automatically. You only need to manage
connections when using DBI directly.

### Mistake 4: Storing Small Datasets Unnecessarily

**Problem**: Overhead of storage backends exceeds benefits.

**Wrong Approach**:

``` r

# Small dataset - DuckDB overhead not worth it
small_data <- data.frame(
  year = c(2020, 2021, 2022),
  count = c(10, 15, 20)
)

# Unnecessary - just use a data frame
biblio_store(small_data, "small.duckdb", "duckdb")
```

**Correct Approach**:

``` r

# For small datasets, keep in memory
small_data <- data.frame(
  year = c(2020, 2021, 2022),
  count = c(10, 15, 20)
)

# Use directly - no storage backend needed
mean(small_data$count)
```

**Rule of Thumb**: Use scalable backends when: - Dataset exceeds 100MB -
You need SQL queries - Long-term storage is required - Multiple users
access the data

### Mistake 5: Ignoring Data Type Implications

**Problem**: Unexpected behavior due to type conversions between R and
storage backends.

**Example**:

``` r

# R factors become strings in storage
df <- data.frame(
  category = factor(c("A", "B", "A")),
  value = c(1, 2, 3)
)

# After storage and retrieval, 'category' is character, not factor
# This may affect downstream analysis
```

**Best Practice**:

``` r

# Convert factors explicitly after loading
project <- biblio_load(path, engine = "duckdb")
project$works$journal <- as.factor(project$works$journal)
```

### Mistake 6: Using read_only = FALSE Unnecessarily

**Problem**: Exclusive locks prevent concurrent access.

**Wrong Approach**:

``` r

# Opens with write lock even for queries
con <- DBI::dbConnect(duckdb::duckdb(), dbdir = "biblio.duckdb", read_only = FALSE)
result <- DBI::dbGetQuery(con, "SELECT COUNT(*) FROM works")
```

**Correct Approach**:

``` r

# Use read_only for queries
con <- DBI::dbConnect(duckdb::duckdb(), dbdir = "biblio.duckdb", read_only = TRUE)
result <- DBI::dbGetQuery(con, "SELECT COUNT(*) FROM works")
```

### Mistake 7: Not Using Column Selection with Arrow

**Problem**: Loading entire datasets when only a few columns are needed.

**Wrong Approach**:

``` r

# Loads ALL columns - wasteful
if (requireNamespace("arrow", quietly = TRUE)) {
  works <- arrow::read_parquet("data/arrow/works.parquet")
  year_counts <- table(works$year)
}
```

**Correct Approach**:

``` r

# Load only needed columns
if (requireNamespace("arrow", quietly = TRUE)) {
  works <- arrow::read_parquet("data/arrow/works.parquet",
                               col_select = c("work_id", "year"))
  year_counts <- table(works$year)
}
```

**Impact**: For a dataset with 50 columns, loading only 2 columns
reduces memory usage by ~96%.

### Mistake 8: Forgetting to Handle NULLs in SQL

**Problem**: Unexpected results due to NULL handling in SQL.

**Wrong Approach**:

``` r

# NULL comparison doesn't work as expected
biblio_query("biblio.duckdb",
  "SELECT COUNT(*) FROM works WHERE journal != 'Unknown'")
# This excludes rows where journal IS NULL
```

**Correct Approach**:

``` r

# Explicitly handle NULLs
biblio_query("biblio.duckdb",
  "SELECT COUNT(*) FROM works
   WHERE journal IS NOT NULL AND journal != 'Unknown'")

# Or use COALESCE for default values
biblio_query("biblio.duckdb",
  "SELECT COALESCE(journal, 'No Journal') AS journal, COUNT(*)
   FROM works
   GROUP BY journal")
```

## Advanced Topics

### Custom Parquet Writer Settings

For fine-grained control over Arrow storage:

``` r

if (requireNamespace("arrow", quietly = TRUE)) {
  library(arrow)

  # Advanced Parquet writing
  write_parquet(
    x$works,
    sink = file.path(arrow_dir, "works_advanced.parquet"),
    compression = "zstd",
    compression_level = 3,
    use_dictionary = TRUE,
    write_statistics = TRUE,
    data_page_size = 1048576  # 1MB pages
  )

  # Read Parquet metadata
  pq <- ParquetFileReader$create(file.path(arrow_dir, "works_advanced.parquet"))
  metadata <- pq$GetMetadata()
  cat("Schema:\n")
  print(metadata$schema)
  cat("\nRow groups:", metadata$num_rows, "\n")
}
```

### DuckDB Extensions

DuckDB supports extensions for additional functionality:

``` r

if (requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("DBI", quietly = TRUE)) {
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = duckdb_file)

  # Install and load extensions
  DBI::dbExecute(con, "INSTALL httpfs;")  # For reading remote files
  DBI::dbExecute(con, "LOAD httpfs;")

  # Use JSON extension
  DBI::dbExecute(con, "INSTALL json;")
  DBI::dbExecute(con, "LOAD json;")

  # Query JSON data
  DBI::dbGetQuery(con,
    "SELECT * FROM read_json_auto('https://example.com/data.json') LIMIT 5")

  DBI::dbDisconnect(con, shutdown = TRUE)
}
```

### Partitioning Large Datasets

For very large datasets, partition data across multiple files:

``` r

if (requireNamespace("arrow", quietly = TRUE)) {
  library(arrow)

  # Partition by year
  works_partitioned <- x$works
  works_partitioned$year <- as.integer(works_partitioned$year)

  # Write partitioned dataset
  write_dataset(
    works_partitioned,
    path = file.path(tempdir(), "partitioned"),
    format = "parquet",
    partitioning = c("year")
  )

  # Read with partition pruning (only reads needed partitions)
  ds <- open_dataset(file.path(tempdir(), "partitioned"), format = "parquet")
  recent <- ds %>% filter(year >= 2020) %>% collect()
  cat(sprintf("Recent works: %d\n", nrow(recent)))
}
```

### Creating Database Views

Views provide virtual tables for common queries:

``` r

if (requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("DBI", quietly = TRUE)) {
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = duckdb_file)

  # Create a view for author productivity
  DBI::dbExecute(con,
    "CREATE VIEW IF NOT EXISTS author_productivity AS
     SELECT a.author_id, a.name,
            COUNT(DISTINCT aw.work_id) AS n_works,
            MIN(w.year) AS first_publication,
            MAX(w.year) AS last_publication,
            COUNT(DISTINCT k.keyword) AS n_keywords
     FROM authors a
     INNER JOIN authorships aw ON a.author_id = aw.author_id
     INNER JOIN works w ON aw.work_id = w.work_id
     LEFT JOIN keywords k ON w.work_id = k.work_id
     GROUP BY a.author_id, a.name")

  # Query the view
  top_authors <- DBI::dbGetQuery(con,
    "SELECT * FROM author_productivity ORDER BY n_works DESC LIMIT 10")
  print(top_authors)

  DBI::dbDisconnect(con, shutdown = TRUE)
}
```

### Database Maintenance

Regular maintenance keeps your DuckDB database healthy:

``` r

if (requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("DBI", quietly = TRUE)) {
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = duckdb_file)

  # Check database size
  size_info <- DBI::dbGetQuery(con, "PRAGMA database_size")
  print(size_info)

  # Analyze tables for query optimization
  DBI::dbExecute(con, "ANALYZE")

  # Vacuum to reclaim space
  DBI::dbExecute(con, "VACUUM")

  DBI::dbDisconnect(con, shutdown = TRUE)
}
```

## Integration with biblioIntegrator Workflows

### Using Backends with Descriptive Analysis

``` r

if (requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("DBI", quietly = TRUE)) {
  # Load from DuckDB
  project <- biblio_load(duckdb_file, engine = "duckdb")

  # Use with standard biblioIntegrator functions
  health <- biblio_health(project)
  print(health)

  # Descriptive analysis
  desc <- describe_biblio(project)
  print(desc)
}
```

### Using Backends with Network Analysis

``` r

if (requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("DBI", quietly = TRUE)) {
  # Prepare co-authorship edges with SQL
  edges <- biblio_query(duckdb_file,
    "SELECT aw1.author_id AS source, aw2.author_id AS target,
            COUNT(DISTINCT aw1.work_id) AS weight
     FROM authorships aw1
     INNER JOIN authorships aw2 ON aw1.work_id = aw2.work_id
                               AND aw1.author_id < aw2.author_id
     GROUP BY aw1.author_id, aw2.author_id
     HAVING COUNT(DISTINCT aw1.work_id) >= 2")

  # Build network with igraph
  library(igraph)
  g <- graph_from_data_frame(edges, directed = FALSE)

  # Compute centrality
  centrality <- data.frame(
    node = V(g)$name,
    degree = degree(g),
    betweenness = betweenness(g)
  )

  cat("Top 5 central authors:\n")
  print(head(centrality[order(-centrality$degree), ], 5))
}
```

### Exporting Query Results

``` r

if (requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("DBI", quietly = TRUE)) {
  # Query and export to CSV
  top_works <- biblio_query(duckdb_file,
    "SELECT w.title, w.year, w.journal,
            COUNT(DISTINCT r.citing_id) AS citations
     FROM works w
     LEFT JOIN references r ON w.work_id = r.cited_id
     GROUP BY w.work_id, w.title, w.year, w.journal
     ORDER BY citations DESC
     LIMIT 20")

  # Write to CSV
  write.csv(top_works, "top_cited_works.csv", row.names = FALSE)
  cat("Exported top cited works to CSV\n")
}
```

## Troubleshooting

### Common Error Messages

#### “Install ‘arrow’”

**Cause**: Arrow package not installed.

**Solution**:

``` r

install.packages("arrow")
# If installation fails, try:
# - Update R to latest version
# - Install system dependencies (Linux)
# - Use binary packages (Windows/macOS)
```

#### “Install ‘duckdb’ and ‘DBI’”

**Cause**: DuckDB or DBI not installed.

**Solution**:

``` r

install.packages(c("duckdb", "DBI"))
```

#### “Unsupported network type”

**Cause**: Invalid `type` argument in
[`bibliographic_network()`](https://wep69.github.io/biblioIntegrator/reference/bibliographic_network.md).

**Solution**:

``` r

# Valid types: "coauthor", "keyword", "citation"
g <- bibliographic_network(x, type = "coauthor")
```

#### Database Locked

**Cause**: Another process or R session has the database open.

**Solution**:

``` r

# Ensure all connections are closed
# Option 1: Close in current session
DBI::dbDisconnect(con, shutdown = TRUE)

# Option 2: Restart R session
# Option 3: Use read_only = TRUE for queries
con <- DBI::dbConnect(duckdb::duckdb(), dbdir = path, read_only = TRUE)
```

#### File Not Found

**Cause**: Path to database/directory doesn’t exist.

**Solution**:

``` r

# Check if path exists
if (!file.exists(duckdb_path)) {
  # Create parent directory
  dir.create(dirname(duckdb_path), recursive = TRUE)
  # Store data
  biblio_store(x, duckdb_path, "duckdb")
}
```

### Debugging Tips

#### 1. Check Backend Status

``` r

status <- backend_status()
print(status)
cat("\nMissing backends:\n")
missing <- status$backend[!status$available]
if (length(missing) > 0) {
  cat(paste(" -", missing, collapse = "\n"), "\n")
  cat("\nInstall with: install.packages(c('",
      paste(missing, collapse = "', '"), "'))\n")
}
```

#### 2. Verify Data Integrity

``` r

verify_storage <- function(path, engine) {
  tryCatch({
    project <- biblio_load(path, engine)
    cat("✓ Storage valid\n")
    cat(sprintf("  Works: %d\n", nrow(project$works)))
    cat(sprintf("  Authors: %d\n", nrow(project$authors)))
    return(TRUE)
  }, error = function(e) {
    cat("✗ Storage error:", conditionMessage(e), "\n")
    return(FALSE)
  })
}

# Test both backends
if (requireNamespace("arrow", quietly = TRUE))
  verify_storage(arrow_dir, "arrow")
if (requireNamespace("duckdb", quietly = TRUE) &&
    requireNamespace("DBI", quietly = TRUE))
  verify_storage(duckdb_file, "duckdb")
```

#### 3. Log Query Performance

``` r

# Add timing to queries
timed_query <- function(path, sql) {
  t1 <- system.time({
    result <- biblio_query(path, sql)
  })
  cat(sprintf("Query time: %.3f seconds\n", t1["elapsed"]))
  cat(sprintf("Rows returned: %d\n", nrow(result)))
  return(result)
}
```

## References

### Official Documentation

- **Apache Arrow**: <https://arrow.apache.org/>
  - R package documentation: <https://arrow.apache.org/docs/r/>
  - Parquet format: <https://parquet.apache.org/>
- **DuckDB**: <https://duckdb.org/>
  - R API: <https://duckdb.org/docs/api/r>
  - SQL syntax: <https://duckdb.org/docs/sql/introduction>
- **DBI**: <https://dbi.r-dbi.org/>
  - Database interface definition for R

### Academic References

- **Arrow specification**: The Apache Arrow Project. (2024). *Apache
  Arrow: Columnar In-Memory Format*. Apache Software Foundation.

- **DuckDB**: Raasveldt, M., & Mühleisen, H. (2019). DuckDB: an
  Embeddable Analytical Database. *SIGMOD ’19: Proceedings of the 2019
  International Conference on Management of Data*, 1981-1984.

- **Parquet**: The Apache Parquet Project. (2024). *Apache Parquet:
  Columnar Storage Format*. Apache Software Foundation.

### Related vignettes

- `v01-import-harmonize.Rmd`: Data import and harmonization workflows
- `v07-foundations-to-advanced-tutorial.Rmd`: Complete workflow overview
- `v09-python-report-ui.Rmd`: Python integration and reporting

### Session Info

``` r

# Document your environment for reproducibility
sessionInfo()
```

## Appendix: Quick Reference

### Function Reference

| Function | Backend | Purpose | Example |
|----|----|----|----|
| [`backend_status()`](https://wep69.github.io/biblioIntegrator/reference/backend_status.md) | Both | Check availability | [`backend_status()`](https://wep69.github.io/biblioIntegrator/reference/backend_status.md) |
| [`biblio_store()`](https://wep69.github.io/biblioIntegrator/reference/biblio_store.md) | Both | Store project | `biblio_store(x, path, "arrow")` |
| [`biblio_load()`](https://wep69.github.io/biblioIntegrator/reference/biblio_load.md) | Both | Load project | `biblio_load(path, "duckdb")` |
| [`biblio_query()`](https://wep69.github.io/biblioIntegrator/reference/biblio_query.md) | DuckDB | SQL query | `biblio_query(path, "SELECT ...")` |

### Common SQL Queries for Bibliometrics

``` r

# Count by year
"SELECT year, COUNT(*) AS n FROM works GROUP BY year ORDER BY year"

# Top journals
"SELECT journal, COUNT(*) AS n FROM works
 WHERE journal IS NOT NULL GROUP BY journal ORDER BY n DESC LIMIT 10"

# Author productivity
"SELECT a.name, COUNT(DISTINCT aw.work_id) AS n_works
 FROM authors a INNER JOIN authorships aw ON a.author_id = aw.author_id
 GROUP BY a.author_id, a.name ORDER BY n_works DESC"

# Keyword co-occurrence
"SELECT k1.keyword AS keyword1, k2.keyword AS keyword2,
        COUNT(DISTINCT k1.work_id) AS n_co_occurrences
 FROM keywords k1
 INNER JOIN keywords k2 ON k1.work_id = k2.work_id
                       AND k1.keyword < k2.keyword
 GROUP BY k1.keyword, k2.keyword
 ORDER BY n_co_occurrences DESC"

# Citation counts
"SELECT w.title, COUNT(r.citing_id) AS n_citations
 FROM works w LEFT JOIN references r ON w.work_id = r.cited_id
 GROUP BY w.work_id, w.title ORDER BY n_citations DESC"
```

### Environment Setup Script

``` r

# Complete setup script
setup_backends <- function() {
  # Install required packages
  required <- c("biblioIntegrator", "arrow", "duckdb", "DBI")
  missing <- required[!sapply(required, requireNamespace, quietly = TRUE)]

  if (length(missing) > 0) {
    cat("Installing missing packages:\n")
    cat(paste(" -", missing, collapse = "\n"), "\n")
    install.packages(missing)
  }

  # Verify installation
  status <- backend_status()
  cat("\nBackend status:\n")
  print(status)

  # Return status
  invisible(status)
}

# Run setup
# setup_backends()
```

## Conclusion

Scalable backends transform how you work with bibliometric data. By
choosing the right backend for your use case:

- **Arrow** when you need fast columnar access and cross-language
  compatibility
- **DuckDB** when you need SQL power and complex analytical queries

You can analyze datasets that would otherwise exceed memory limits,
share data efficiently, and build reproducible analytical pipelines.

Remember to:

1.  **Always check backend availability** before using them
2.  **Choose the right tool** for your specific task
3.  **Close connections** properly with DuckDB
4.  **Use column selection** with Arrow for memory efficiency
5.  **Test with small datasets** before scaling to production

For questions or issues, please refer to the package documentation or
open an issue on the project’s repository.
