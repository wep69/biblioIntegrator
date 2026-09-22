# Import and Harmonization

## 1. Why this vignette exists

Bibliometric research nearly always begins with data that lives in more
than one place. A Scopus export uses one column schema, Web of Science
uses another, Dimensions yet another. Even two CSV dumps from the same
service can disagree on field names, delimiter conventions, encoding and
the treatment of missing values. If you treat each export as the
canonical shape you will spend most of your time wrangling columns
instead of answering research questions.

The **biblioIntegrator** package takes a different approach. It defines
a **common relational structure** — the `biblio_project` — and provides
functions that normalise every incoming source into that structure.
Import and harmonization are deliberately separated:

- **Import** reads raw data from disk (CSV, TSV, JSON, RIS, BibTeX) or
  from an API (OpenAlex, OpenCitations) and produces a single data
  frame.
- **Harmonization**
  ([`as_biblio_project()`](https://wep69.github.io/biblioIntegrator/reference/as_biblio_project.md))
  converts that data frame into the relational `biblio_project`,
  splitting authors, keywords and references into their own tables,
  normalising DOIs, and logging every step in a provenance ledger.

This two-phase design means you can inspect, filter or repair the data
frame *before* it enters the relational model. It also means the
harmonization step is deterministic and reproducible: the same data
frame will always produce the same `biblio_project`, regardless of how
it was originally created.

This vignette walks through every supported import path, explains what
each step of the harmonization pipeline does, and shows how to export
results into formats that downstream tools (bibliometrix, Biblium,
VOSviewer) expect. By the end you will be able to import a corpus from
any source, inspect the harmonized tables, validate integrity, and hand
clean data to the analytical vignettes that follow.

**Companion vignettes.** After reading this one, continue with
`v02-quality-dedup.Rmd` for deduplication, `v03-descriptive-impact.Rmd`
for descriptive metrics, and `v05-networks.Rmd` for co-authorship and
keyword networks.

## 2. Learning objectives

After working through this vignette you will be able to:

1.  Load the built-in teaching corpus with
    [`example_biblio()`](https://wep69.github.io/biblioIntegrator/reference/example_biblio.md)
    and understand what it contains.
2.  Convert any flat data frame into a relational `biblio_project` with
    [`as_biblio_project()`](https://wep69.github.io/biblioIntegrator/reference/as_biblio_project.md).
3.  Import bibliographic data from **CSV**, **TSV** and **JSON** files
    using
    [`biblio_import()`](https://wep69.github.io/biblioIntegrator/reference/biblio_import.md).
4.  Delegate **RIS**, **BibTeX** and database-specific exports (Scopus,
    WoS, Dimensions, PubMed) to
    [`bibliometrix::convert2df()`](https://rdrr.io/pkg/bibliometrix/man/convert2df.html)
    via
    [`biblio_import()`](https://wep69.github.io/biblioIntegrator/reference/biblio_import.md)
    when the **bibliometrix** package is installed.
5.  Fetch records directly from the **OpenAlex** API with
    [`fetch_openalex()`](https://wep69.github.io/biblioIntegrator/reference/fetch_openalex.md).
6.  Understand the harmonization pipeline: DOI normalization, author
    name splitting, keyword tokenisation and work-ID generation.
7.  Inspect every table inside a `biblio_project` (works, authorships,
    authors, keywords, references, provenance) and interpret its
    structure.
8.  Export a `biblio_project` back to **bibliometrix** format
    ([`to_bibliometrix()`](https://wep69.github.io/biblioIntegrator/reference/to_bibliometrix.md)),
    **Biblium** format
    ([`to_biblium()`](https://wep69.github.io/biblioIntegrator/reference/to_biblium.md)),
    generic file formats
    ([`export_biblio()`](https://wep69.github.io/biblioIntegrator/reference/export_biblio.md)),
    and **VOSviewer** network files
    ([`export_vosviewer()`](https://wep69.github.io/biblioIntegrator/reference/export_vosviewer.md)).
9.  Validate referential integrity, detect orphan records and verify
    provenance after import and merge operations.
10. Avoid the most common mistakes that lead to data loss or silent
    corruption during import.

## 3. Supported data sources

biblioIntegrator’s import layer distinguishes between **native** formats
(handled without optional dependencies) and **delegated** formats
(handled through
[`bibliometrix::convert2df()`](https://rdrr.io/pkg/bibliometrix/man/convert2df.html)
when that package is installed).

| Source / Database | Export format(s) | Native support | Via bibliometrix |
|:---|:---|:---|:---|
| Any CSV / TSV table | `.csv`, `.tsv` | [`biblio_import()`](https://wep69.github.io/biblioIntegrator/reference/biblio_import.md) | — |
| Any JSON export | `.json` | [`biblio_import()`](https://wep69.github.io/biblioIntegrator/reference/biblio_import.md) | — |
| Web of Science (WoS) | `.txt` (field-tag) | — | `dbsource="wos"` |
| Scopus | `.csv` (Scopus export) | Partial (as CSV) | `dbsource="scopus"` |
| Dimensions | `.csv` (Dimensions) | — | `dbsource="dimensions"` |
| PubMed / MEDLINE | `.xml`, `.nbib` | — | `dbsource="pubmed"` |
| Cochrane Library | `.ciw` | — | `dbsource="cochrane"` |
| Lens.org | `.csv` | Partial (as CSV) | — |
| OpenAlex (API) | JSON via REST | [`fetch_openalex()`](https://wep69.github.io/biblioIntegrator/reference/fetch_openalex.md) | — |
| OpenAlex (CSV dump) | `.csv` | [`biblio_import()`](https://wep69.github.io/biblioIntegrator/reference/biblio_import.md) | — |
| OpenCitations (API) | JSON via REST | [`fetch_opencitations()`](https://wep69.github.io/biblioIntegrator/reference/fetch_opencitations.md) | — |
| RIS | `.ris` | — | `format="ris"` |
| BibTeX | `.bib` | — | `format="bibtex"` |
| EndNote | `.enw`, `.xml` | — | `format="endnote"` |

**Key points:**

- If your file is a flat CSV/TSV/JSON with columns like `title`,
  `authors`, `year`, `doi`, keywords`, citations`, `source` — or common
  abbreviations `TI`, `AU`, `PY`, `DI`, `DE`, `TC`, `SO` — then
  [`biblio_import()`](https://wep69.github.io/biblioIntegrator/reference/biblio_import.md)
  will handle it natively.
- For RIS, BibTeX, EndNote, or database-specific field-tag exports
  (`.txt` from WoS, `.nbib` from PubMed), install **bibliometrix** and
  pass either `dbsource` or `format` to
  [`biblio_import()`](https://wep69.github.io/biblioIntegrator/reference/biblio_import.md).
  If neither is given, the function attempts `dbsource="wos"` as the
  default.
- [`fetch_openalex()`](https://wep69.github.io/biblioIntegrator/reference/fetch_openalex.md)
  and
  [`fetch_opencitations()`](https://wep69.github.io/biblioIntegrator/reference/fetch_opencitations.md)
  are synchronous REST calls built on `httr2` and `jsonlite`. They
  return a `biblio_project` directly, bypassing the need for a local
  file.

## 4. The harmonization pipeline

Before diving into code, it is worth understanding what
[`as_biblio_project()`](https://wep69.github.io/biblioIntegrator/reference/as_biblio_project.md)
does under the hood. Harmonization is **not** a black box — each step is
deterministic and can be traced through the provenance table.

### 4.1 Column resolution

biblioIntegrator accepts a wide variety of column names because
different databases insist on different conventions. The resolution
table below shows what
[`as_biblio_project()`](https://wep69.github.io/biblioIntegrator/reference/as_biblio_project.md)
looks for (case-insensitive, first match wins):

| Logical field | Accepted column names | Default if missing |
|:---|:---|:---|
| Title | `title`, `ti` | `""` |
| Year | `year`, `py` | `NA_integer_` |
| DOI | `doi`, `di` | `""` |
| Work ID | `work_id`, `id`, `eid` | auto-generated |
| Authors | `authors`, `author`, `au` | `""` |
| Keywords | `keywords`, `de`, `author_keywords` | `""` |
| Source/Journal | `source`, `journal`, `so`, `source_title` | `""` |
| Citations | `cited_by_count`, `citations`, `tc` | `0` |
| Abstract | `abstract`, `ab` | `""` |

This means a Scopus CSV that uses `Authors`, a WoS field-tag file that
uses `AU`, and a Dimensions export that uses `authors` will all resolve
to the same logical field. You rarely need to rename columns before
import.

### 4.2 DOI normalization

DOIs are the primary key for cross-database matching, but they arrive in
many guises. The internal function `.bi_norm_doi()` applies these rules
in order:

1.  Convert to lowercase and trim whitespace.
2.  Strip a leading `https://doi.org/`, `http://doi.org/`, or
    `http://dx.doi.org/` prefix.
3.  Strip a leading `doi:` prefix (with optional whitespace).

After normalization, `10.1016/j.soilbio.2020.107900`,
`https://doi.org/10.1016/j.soilbio.2020.107900`, and
`DOI: 10.1016/j.soilbio.2020.107900` all become the same string.

### 4.3 Author name splitting

Author strings come in at least four separator conventions:

- `;` — Scopus, Dimensions
- `|` — some OpenAlex exports
- `,` — dangerous because surnames contain commas (but handled by
  `.bi_split()` when no semicolons or pipes are present)
- `and` / `&` — BibTeX

`.bi_split()` splits on `;` or `|`, trims whitespace, and deduplicates
within the same row. If neither separator is found it returns the full
string as a single author.

Each author produces two records:

- A row in the **authorships** table linking `work_id` to a stable
  `author_id`.
- A row in the **authors** table linking `author_id` to the display
  name.

The `author_id` is generated deterministically from the full name string
using a simple hash (`"A"` prefix + 8-digit hex), so the same author
name across different works will map to the same `author_id`. This is
not full name-disambiguation (that is the subject of
`v02-quality-dedup.Rmd`) but it is a reproducible first pass.

### 4.4 Keyword tokenisation

Keywords follow the same `.bi_split()` logic as authors — split on `;`
or `|`, trim, deduplicate, lowercase. The result is a many-to-many table
linking `work_id` to `keyword`.

### 4.5 Work-ID generation

If the incoming data already has a `work_id`, `id` or `eid` column, it
is used as-is. Otherwise a deterministic hash (`"W"` prefix + title +
year + DOI) is generated. This means the same work imported twice will
get the same ID, which simplifies later deduplication.

### 4.6 Provenance ledger

Every transformation step appends a timestamped row to the `$provenance`
table. The row records:

- `timestamp` — ISO 8601 string of when the operation ran.
- `operation` — the function name (e.g., `as_biblio_project`,
  `deduplicate_biblio`).
- `details` — key parameters (e.g., `source=scopus.csv; n=4523`).

This ledger is cumulative — it is never overwritten, only appended to.
It travels with the `biblio_project` through every downstream analysis
and is written to disk by
[`biblio_report()`](https://wep69.github.io/biblioIntegrator/reference/biblio_report.md)
and
[`export_biblio()`](https://wep69.github.io/biblioIntegrator/reference/export_biblio.md).

### 4.7 Pipeline diagram

    ┌─────────────────────────────────────────────────────────────────────────┐
    │                      BIBLIOGRAPHIC DATA SOURCE                         │
    │  (CSV / TSV / JSON / RIS / BibTeX / API / bibliometrix delegation)     │
    └──────────────────────────────┬──────────────────────────────────────────┘
                                   │
                                   ▼
    ┌─────────────────────────────────────────────────────────────────────────┐
    │                         biblio_import()                                │
    │  Read file ──► detect extension ──► native parser or bibliometrix ──►   │
    │  raw data frame                                                       │
    └──────────────────────────────┬──────────────────────────────────────────┘
                                   │
                                   ▼
    ┌─────────────────────────────────────────────────────────────────────────┐
    │                       as_biblio_project()                              │
    │                                                                        │
    │  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐  ┌────────────┐ │
    │  │ Column       │  │ DOI          │  │ Author        │  │ Keyword    │ │
    │  │ resolution   │  │ normalization│  │ splitting     │  │ tokenisation│ │
    │  │              │  │              │  │               │  │            │ │
    │  │ title, TI    │  │ lowercase    │  │ split on ; |  │  │ split on; │ │
    │  │ year, PY     │  │ strip prefix │  │ trim, dedup   │  │ lowercase │ │
    │  │ doi, DI      │  │              │  │ generate IDs  │  │ dedup     │ │
    │  │ authors, AU  │  │              │  │               │  │            │ │
    │  │ keywords, DE │  │              │  │               │  │            │ │
    │  └──────┬───────┘  └──────┬───────┘  └───────┬───────┘  └─────┬──────┘ │
    │         └──────────────────┴──────────────────┴───────────────┘       │
    │                               │                                       │
    │  ┌────────────────────────────┴────────────────────────────────────┐  │
    │  │                    RELATIONAL biblio_project                    │  │
    │  │  $works         ── one row per unique work                     │  │
    │  │  $authorships   ── work ↔ author links                         │  │
    │  │  $authors       ── author ID ↔ display name                    │  │
    │  │  $keywords      ── work ↔ keyword links                        │  │
    │  │  $references    ── citing ↔ cited links (when available)       │  │
    │  │  $provenance    ── timestamped operation ledger                 │  │
    │  └────────────────────────────────────────────────────────────────┘  │
    └─────────────────────────────────────────────────────────────────────────┘

## 5. Step-by-step import workflow

This section walks through every import path with runnable examples.

### 5.1 The built-in teaching corpus

The fastest way to explore biblioIntegrator is
[`example_biblio()`](https://wep69.github.io/biblioIntegrator/reference/example_biblio.md).
It returns a small (12-record) agronomy-oriented data frame with
realistic author names, DOIs, keywords and citation counts. No internet
connection or external file is needed.

``` r

library(biblioIntegrator)

# Load the teaching corpus
raw <- example_biblio()

# Basic shape
dim(raw)
#> [1] 12  7
names(raw)
#> [1] "title"     "year"      "doi"       "authors"   "keywords"  "citations"
#> [7] "source"
```

``` r

# First few records
head(raw[, c("title", "year", "authors", "doi")], 4)
#>                                    title year            authors            doi
#> 1 Silicon and salinity tolerance in rice 2018 Silva A; Pereira W 10.1000/agri.1
#> 2          Soil carbon under cover crops 2019 Martins B; Costa C 10.1000/agri.2
#> 3     Remote sensing of soybean nitrogen 2020  Lima D; Pereira W 10.1000/agri.3
#> 4     Silicon nutrition in maize drought 2021   Silva A; Gomez E 10.1000/agri.4
```

The teaching corpus has all the fields that
[`as_biblio_project()`](https://wep69.github.io/biblioIntegrator/reference/as_biblio_project.md)
expects: `title`, `year`, `doi`, `authors`, `keywords`, `citations`,
`source`. This makes it an ideal test bed for exploring every function
in the package.

``` r

# How many distinct keywords?
sort(table(unlist(strsplit(raw$keywords, ";"))), decreasing = TRUE)[1:8]
#> 
#>      silicon        maize         soil      soybean  aggregation  cover crops 
#>            3            2            2            2            1            1 
#>      drought   efficiency 
#>            1            1
```

``` r

# Publication year distribution
table(raw$year)
#> 
#> 2017 2018 2019 2020 2021 2022 2023 2024 2025 
#>    1    1    1    2    1    2    1    2    1
```

### 5.2 Converting a data frame to a `biblio_project`

[`as_biblio_project()`](https://wep69.github.io/biblioIntegrator/reference/as_biblio_project.md)
is the central harmonization entry point. It accepts any data frame that
has (or can be mapped to) the logical fields listed in Section 4.1.

``` r

x <- as_biblio_project(raw, source = "teaching corpus")
x
#> <biblio_project> 12 works; 7 authors; 32 work-keyword links
```

The printed summary tells you how many works, authors and keyword links
are in the project. Let us inspect each table.

#### 5.2.1 The `$works` table

``` r

str(x$works)
#> 'data.frame':    12 obs. of  7 variables:
#>  $ work_id       : chr  "W0001f7e3" "W000160f5" "W0001b6e0" "W0001b6e2" ...
#>  $ title         : chr  "Silicon and salinity tolerance in rice" "Soil carbon under cover crops" "Remote sensing of soybean nitrogen" "Silicon nutrition in maize drought" ...
#>  $ year          : int  2018 2019 2020 2021 2022 2023 2017 2020 2024 2025 ...
#>  $ doi           : chr  "10.1000/agri.1" "10.1000/agri.2" "10.1000/agri.3" "10.1000/agri.4" ...
#>  $ source        : chr  "Field Crops" "Soil Science" "Remote Sensing" "Plant Nutrition" ...
#>  $ cited_by_count: num  42 35 28 31 22 18 55 26 12 9 ...
#>  $ abstract      : chr  "" "" "" "" ...
head(x$works[, c("work_id", "title", "year", "doi", "source", "cited_by_count")], 4)
#>     work_id                                  title year            doi
#> 1 W0001f7e3 Silicon and salinity tolerance in rice 2018 10.1000/agri.1
#> 2 W000160f5          Soil carbon under cover crops 2019 10.1000/agri.2
#> 3 W0001b6e0     Remote sensing of soybean nitrogen 2020 10.1000/agri.3
#> 4 W0001b6e2     Silicon nutrition in maize drought 2021 10.1000/agri.4
#>            source cited_by_count
#> 1     Field Crops             42
#> 2    Soil Science             35
#> 3  Remote Sensing             28
#> 4 Plant Nutrition             31
```

Each row is a unique work. The `work_id` is a deterministic hash derived
from title, year and DOI. `cited_by_count` defaults to 0 when the source
column is missing or contains non-numeric values.

#### 5.2.2 The `$authorships` table

``` r

head(x$authorships, 8)
#>              work_id author_id
#> Silva A    W0001f7e3 A000008ad
#> Pereira W  W0001f7e3 A00000f73
#> Martins B  W000160f5 A00000f4d
#> Costa C    W000160f5 A000008c4
#> Lima D     W0001b6e0 A00000621
#> Pereira W1 W0001b6e0 A00000f73
#> Silva A1   W0001b6e2 A000008ad
#> Gomez E    W0001b6e2 A00000905
```

This is a many-to-many linking table. A work with three authors produces
three rows. The `author_id` is a hash of the display name.

#### 5.2.3 The `$authors` table

``` r

x$authors
#>           author_id display_name
#> Silva A   A000008ad      Silva A
#> Pereira W A00000f73    Pereira W
#> Martins B A00000f4d    Martins B
#> Costa C   A000008c4      Costa C
#> Lima D    A00000621       Lima D
#> Gomez E   A00000905      Gomez E
#> Rao F     A0000043f        Rao F
```

One row per unique author name across the entire corpus. The same person
spelled differently (e.g., “Silva A” vs “Silva, A”) will get different
IDs. Name disambiguation is the subject of the quality vignette.

#### 5.2.4 The `$keywords` table

``` r

head(x$keywords, 10)
#>      work_id        keyword
#> 1  W0001f7e3        silicon
#> 2  W0001f7e3       salinity
#> 3  W0001f7e3           rice
#> 4  W000160f5    soil carbon
#> 5  W000160f5    cover crops
#> 6  W0001b6e0 remote sensing
#> 7  W0001b6e0        soybean
#> 8  W0001b6e0       nitrogen
#> 9  W0001b6e2        silicon
#> 10 W0001b6e2        drought
```

Keywords are lowercased during harmonization. Stop-word removal and
stemming are left to the user because they are domain-specific.

#### 5.2.5 The `$references` table

``` r

x$references
#> [1] citing_id cited_id 
#> <0 rows> (or 0-length row.names)
```

The teaching corpus does not include a references column, so this table
is empty. When you import from Scopus or WoS (which include cited
references), this table will be populated with `citing_id` and
`cited_id` pairs.

#### 5.2.6 The `$provenance` table

``` r

x$provenance
#>                    timestamp         operation                      details
#> 1 2026-09-22 03:17:47.558147 as_biblio_project source=teaching corpus; n=12
```

Every operation that touches the `biblio_project` appends a row here.
You can always trace the full life history of your data by reading this
table.

### 5.3 Importing from CSV

CSV is the most common exchange format.
[`biblio_import()`](https://wep69.github.io/biblioIntegrator/reference/biblio_import.md)
reads the file, detects the delimiter and quote character, and passes
the result to
[`as_biblio_project()`](https://wep69.github.io/biblioIntegrator/reference/as_biblio_project.md).

``` r

# Write the teaching corpus to a temporary CSV
csv_path <- tempfile(fileext = ".csv")
utils::write.csv(raw, csv_path, row.names = FALSE)

# Import it back
x_csv <- biblio_import(csv_path)
x_csv
#> <biblio_project> 12 works; 7 authors; 32 work-keyword links
```

``` r

# Verify the round-trip preserved all works
stopifnot(nrow(x_csv$works) == nrow(raw))
cat("CSV round-trip: all", nrow(raw), "works preserved.\n")
#> CSV round-trip: all 12 works preserved.
```

#### 5.3.1 CSV field-name mapping

You can test how the column-resolution logic handles alternative names.

``` r

# Rename columns to Scopus-style abbreviations
raw_alt <- raw
names(raw_alt) <- c("TI", "PY", "DI", "AU", "DE", "TC", "SO")
csv_alt <- tempfile(fileext = ".csv")
utils::write.csv(raw_alt, csv_alt, row.names = FALSE)

x_alt <- biblio_import(csv_alt)
head(x_alt$works[, c("title", "year", "doi")], 3)
#>                                    title year            doi
#> 1 Silicon and salinity tolerance in rice 2018 10.1000/agri.1
#> 2          Soil carbon under cover crops 2019 10.1000/agri.2
#> 3     Remote sensing of soybean nitrogen 2020 10.1000/agri.3
```

The harmonized result is identical regardless of column naming
convention.

#### 5.3.2 Working with TSV files

``` r

tsv_path <- tempfile(fileext = ".tsv")
utils::write.table(raw, tsv_path, sep = "\t", row.names = FALSE, quote = TRUE)

x_tsv <- biblio_import(tsv_path)
cat("TSV import works:", nrow(x_tsv$works), "\n")
#> TSV import works: 12
```

### 5.4 Importing from JSON

JSON imports are handled natively via
[`jsonlite::read_json()`](https://jeroen.r-universe.dev/jsonlite/reference/read_json.html).
The function expects a JSON array of objects (one object per record).

``` r

json_path <- tempfile(fileext = ".json")
jsonlite::write_json(raw, json_path, pretty = TRUE, auto_unbox = TRUE)

x_json <- biblio_import(json_path)
cat("JSON import works:", nrow(x_json$works), "\n")
#> JSON import works: 12
```

#### 5.4.1 Inspecting the JSON round-trip

``` r

head(x_json$works[, c("title", "year", "source")], 4)
#>                                    title year          source
#> 1 Silicon and salinity tolerance in rice 2018     Field Crops
#> 2          Soil carbon under cover crops 2019    Soil Science
#> 3     Remote sensing of soybean nitrogen 2020  Remote Sensing
#> 4     Silicon nutrition in maize drought 2021 Plant Nutrition
```

#### 5.4.2 Deeper JSON inspection

``` r

# Check DOI normalization survived the round-trip
all(nzchar(x_json$works$doi))
#> [1] TRUE
cat("All DOIs preserved:", all(nzchar(x_json$works$doi)), "\n")
#> All DOIs preserved: TRUE
```

### 5.5 Importing via bibliometrix (RIS, BibTeX, Scopus, WoS, etc.)

When the **bibliometrix** package is installed,
[`biblio_import()`](https://wep69.github.io/biblioIntegrator/reference/biblio_import.md)
delegates non-native file types to
[`bibliometrix::convert2df()`](https://rdrr.io/pkg/bibliometrix/man/convert2df.html).
You control the source database with `dbsource` and the file format with
`format`.

``` r

# Scopus CSV export — bibliometrix knows the Scopus column layout
# x_scopus <- biblio_import("scopus_export.csv", dbsource = "scopus")
# x_scopus

# Web of Science plain-text export
# x_wos <- biblio_import("savedrecs.txt", dbsource = "wos")
# x_wos

# RIS file
# x_ris <- biblio_import("references.ris", format = "ris")
# x_ris

# BibTeX file
# x_bib <- biblio_import("references.bib", format = "bibtex")
# x_bib
```

#### 5.5.1 How bibliometrix delegation works

When
[`biblio_import()`](https://wep69.github.io/biblioIntegrator/reference/biblio_import.md)
receives a file with an extension it does not handle natively (`.txt`,
`.ris`, `.bib`, `.nbib`, `.enw`, etc.), it checks whether `bibliometrix`
is available via
[`requireNamespace()`](https://rdrr.io/r/base/ns-load.html):

``` r

# Pseudocode of the delegation logic inside biblio_import():
#
#   ext <- tools::file_ext(path)
#   if (ext %in% c("csv", "tsv")) {
#     # native parser
#   } else if (ext == "json") {
#     # native JSON parser
#   } else if (requireNamespace("bibliometrix", quietly = TRUE)) {
#     ds <- if (is.null(dbsource) || dbsource == "auto") "wos" else dbsource
#     fm <- if (is.null(format)) ext else format
#     d <- bibliometrix::convert2df(path, dbsource = ds, format = fm)
#   } else {
#     stop("For this file type install 'bibliometrix'.")
#   }
```

If `bibliometrix` is not installed, the function raises an informative
error suggesting either installing the package or converting the file to
CSV/TSV/JSON first. This design means biblioIntegrator never forces
`bibliometrix` as a hard dependency.

#### 5.5.2 round-tripping through bibliometrix

After import you can always convert a `biblio_project` back to
bibliometrix format for workflows that require it:

``` r

mx <- to_bibliometrix(x)
head(mx[, c("TI", "PY", "DI", "SO", "TC")], 4)
#>                                       TI   PY             DI              SO TC
#> 1 Silicon and salinity tolerance in rice 2018 10.1000/agri.1     Field Crops 42
#> 2          Soil carbon under cover crops 2019 10.1000/agri.2    Soil Science 35
#> 3     Remote sensing of soybean nitrogen 2020 10.1000/agri.3  Remote Sensing 28
#> 4     Silicon nutrition in maize drought 2021 10.1000/agri.4 Plant Nutrition 31
```

This is useful when a colleague’s script expects a bibliometrix data
frame but you want to keep your canonical data in the relational model.

### 5.6 Fetching from OpenAlex via API

The **OpenAlex** API provides open access to over 200 million scholarly
works.
[`fetch_openalex()`](https://wep69.github.io/biblioIntegrator/reference/fetch_openalex.md)
sends a search query and returns a ready-made `biblio_project`.

``` r

# Requires internet access
# x_oa <- fetch_openalex("silicon salinity plants", n = 10)
# x_oa
# x_oa$works[, c("title", "year", "doi")]

# With a polite mailto header
# x_oa2 <- fetch_openalex("cover crops soil", n = 5, mailto = "user@example.org")
# x_oa2$works
```

#### 5.6.1 Understanding OpenAlex return structure

[`fetch_openalex()`](https://wep69.github.io/biblioIntegrator/reference/fetch_openalex.md)
maps the OpenAlex JSON response directly into the `biblio_project`
tables. The mapping is:

| OpenAlex field | biblioIntegrator table | Column |
|:---|:---|:---|
| `id` | `$works` | `work_id` |
| `title` | `$works` | `title` |
| `publication_year` | `$works` | `year` |
| `doi` | `$works` | `doi` (normalised) |
| `cited_by_count` | `$works` | `cited_by_count` |
| `authorships[]` | `$authorships` | work ↔︎ author links |
| `authorships[].author.display_name` | `$authors` | `display_name` |
| `keywords[]` | `$keywords` | `keyword` |
| `referenced_works[]` | `$references` | `citing_id` / `cited_id` |

#### 5.6.2 Fetching reference links from OpenCitations

For citation-network analysis you often need the reference list of a
specific work.
[`fetch_opencitations()`](https://wep69.github.io/biblioIntegrator/reference/fetch_opencitations.md)
retrieves those links from the OpenCitations API.

``` r

# Requires internet access
# cit_df <- fetch_opencitations("10.1038/nature12373")
# head(cit_df)
#
# Or in the references direction:
# ref_df <- fetch_opencitations("10.1038/nature12373", direction = "references")
# head(ref_df)
```

### 5.7 Importing from openalexR (if installed)

If you already have the **openalexR** package, you can use its richer
filtering capabilities and then pass the result to
[`as_biblio_project()`](https://wep69.github.io/biblioIntegrator/reference/as_biblio_project.md):

``` r

# Requires openalexR installation
# if (requireNamespace("openalexR", quietly = TRUE)) {
#   oa_df <- openalexR::oa_fetch(
#     entity = "works",
#     search = "silicon rice salinity",
#     count = 20
#   )
#   x_oar <- as_biblio_project(oa_df, source = "openalexR")
#   x_oar
# }
```

This pattern — fetching with a specialized package, harmonizing with
[`as_biblio_project()`](https://wep69.github.io/biblioIntegrator/reference/as_biblio_project.md)
— works with any package that returns a data frame. You are never locked
into a single import path.

## 6. Inspecting the harmonized project

Once you have a `biblio_project`, the first thing to do is look inside
it. The [`print()`](https://rdrr.io/r/base/print.html) method gives you
a quick summary, but you will often want to explore the individual
tables.

### 6.1 The print method

``` r

print(x)
#> <biblio_project> 12 works; 7 authors; 32 work-keyword links
```

The summary shows the three most-referenced entity counts: works,
authors and keyword links. If you see `0 authors` but many works, it
means the source file had no recognizable author column.

### 6.2 Exploring the works table

``` r

# Total citations across the corpus
sum(x$works$cited_by_count)
#> [1] 309
```

``` r

# Most-cited work
x$works[which.max(x$works$cited_by_count), c("title", "year", "cited_by_count")]
#>                         title year cited_by_count
#> 7 Salinity responses of wheat 2017             55
```

``` r

# Year range
range(x$works$year, na.rm = TRUE)
#> [1] 2017 2025
```

``` r

# How many works have a DOI?
sum(nzchar(x$works$doi))
#> [1] 12
```

### 6.3 Exploring authorships and authors

``` r

# Number of authors per work — a classic bibliometric indicator
auth_per_work <- table(table(x$authorships$work_id))
names(auth_per_work) <- paste(names(auth_per_work), "author(s)")
auth_per_work
#> 2 author(s) 
#>          12
```

``` r

# Authors with the most works in this corpus
sort(table(x$authorships$author_id), decreasing = TRUE)[1:5]
#> 
#> A000008ad A00000f4d A00000f73 A0000043f A00000621 
#>         4         4         4         3         3
```

``` r

# Map author_ids back to display names
top_ids <- names(sort(table(x$authorships$author_id), decreasing = TRUE)[1:5])
merge(data.frame(author_id = top_ids), x$authors, by = "author_id")
#>   author_id display_name
#> 1 A0000043f        Rao F
#> 2 A00000621       Lima D
#> 3 A000008ad      Silva A
#> 4 A00000f4d    Martins B
#> 5 A00000f73    Pereira W
```

### 6.4 Exploring keywords

``` r

# Top 10 keywords
sort(table(x$keywords$keyword), decreasing = TRUE)[1:10]
#> 
#>       silicon   cover crops         maize      nitrogen      salinity 
#>             3             2             2             2             2 
#>          soil       soybean   aggregation climate-smart       drought 
#>             2             2             1             1             1
```

``` r

# Average number of keywords per work
nrow(x$keywords) / nrow(x$works)
#> [1] 2.666667
```

``` r

# Works with the most keywords — possibly review papers
kw_counts <- table(x$keywords$work_id)
top_kw_work <- names(which.max(kw_counts))
x$works[x$works$work_id == top_kw_work, c("title", "year")]
#>                        title year
#> 9 UAV phenotyping of soybean 2024
x$keywords[x$keywords$work_id == top_kw_work, "keyword"]
#> [1] "uav"         "soybean"     "phenotyping"
```

### 6.5 Exploring references

``` r

# The teaching corpus has no references
nrow(x$references)
#> [1] 0
```

References are populated when you import from a source that includes
cited-reference data (e.g., Scopus CSV with the `"References"` column,
or
[`fetch_openalex()`](https://wep69.github.io/biblioIntegrator/reference/fetch_openalex.md)).
After a merge of multiple sources, the references table becomes the
richest part of the project.

### 6.6 Exploring provenance

``` r

audit_biblio(x)
#>                    timestamp         operation                      details
#> 1 2026-09-22 03:17:47.558147 as_biblio_project source=teaching corpus; n=12
```

``` r

# Adding an operation changes provenance
# Health check — see v02-quality-dedup.Rmd for full coverage
x_h <- biblio_health(x)
x_h
#>                  check n
#> 1        missing_title 0
#> 2         missing_year 0
#> 3          missing_doi 0
#> 4        duplicate_doi 0
#> 5 duplicate_title_year 0
#> 6   negative_citations 0
```

``` r

# The health check is a read-only diagnostic; provenance is unchanged
nrow(audit_biblio(x))
#> [1] 1
```

``` r

# Deduplication DOES add provenance
x_dup <- rbind(raw, raw[1, ])  # duplicate first row
x_dup_p <- as_biblio_project(x_dup, source = "duplicated")
x_dedup <- deduplicate_biblio(x_dup_p)
audit_biblio(x_dedup)
#>                    timestamp          operation                 details
#> 1 2026-09-22 03:17:49.638036  as_biblio_project source=duplicated; n=13
#> 2 2026-09-22 03:17:49.639707 deduplicate_biblio               removed=1
```

### 6.7 The health diagnostic

``` r

biblio_health(x)
#>                  check n
#> 1        missing_title 0
#> 2         missing_year 0
#> 3          missing_doi 0
#> 4        duplicate_doi 0
#> 5 duplicate_title_year 0
#> 6   negative_citations 0
```

A healthy corpus shows 0 for every check. Non-zero values indicate:

- `missing_title` — rows that will break title-based deduplication.
- `missing_year` — rows that cannot participate in temporal analysis.
- `missing_doi` — rows that cannot be cross-matched against other
  databases.
- `duplicate_doi` — data-entry errors or un-merged duplicates.
- `duplicate_title_year` — likely duplicates even when DOIs are missing.
- `negative_citations` — impossible values, usually a parsing error.

These diagnostics are the entry point for `v02-quality-dedup.Rmd`.

### 6.8 The descriptive summary

``` r

desc <- describe_biblio(x)
desc$n_documents
#> [1] 12
desc$years
#> [1] 2017 2025
desc$total_citations
#> [1] 309
```

``` r

desc$annual
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
```

``` r

desc$top_sources
#> 
#>            Soil Science    Agricultural Systems        Agronomy Reviews 
#>                       2                       1                       1 
#>            Crop Science             Field Crops         Plant Nutrition 
#>                       1                       1                       1 
#>            Plant Stress   Precision Agriculture          Remote Sensing 
#>                       1                       1                       1 
#>            Soil Biology Sustainable Agriculture 
#>                       1                       1
```

``` r

desc$top_keywords
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

## 7. Working with the teaching corpus

Before moving to real data, let us develop a few more exploratory
queries on the built-in corpus. These exercises build fluency with the
table structure.

### 7.1 Cross-tabulating authors and keywords

Which author–keyword pairs co-occur most often?

``` r

merged <- merge(x$authorships, x$keywords, by = "work_id")
merged <- merge(merged, x$authors, by = "author_id")
head(sort(table(paste(merged$display_name, "|", merged$keyword)),
          decreasing = TRUE), 10)
#> 
#>          Silva A | silicon            Gomez E | maize 
#>                          3                          2 
#>           Lima D | soybean    Martins B | cover crops 
#>                          2                          2 
#>           Martins B | soil        Pereira W | silicon 
#>                          2                          2 
#>         Silva A | salinity      Costa C | cover crops 
#>                          2                          1 
#> Costa C | machine learning      Costa C | phenotyping 
#>                          1                          1
```

### 7.2 Year–keyword evolution

How has the keyword profile changed over time?

``` r

# Only works 2020 and later
recent_works <- x$works$work_id[x$works$year >= 2020]
recent_kw <- x$keywords[x$keywords$work_id %in% recent_works, ]
sort(table(recent_kw$keyword), decreasing = TRUE)[1:8]
#> 
#>         maize      nitrogen       silicon          soil       soybean 
#>             2             2             2             2             2 
#>   aggregation climate-smart   cover crops 
#>             1             1             1
```

### 7.3 Citation distribution by source

``` r

stats::aggregate(
  cited_by_count ~ source,
  data = x$works,
  FUN = function(v) c(mean = mean(v), median = median(v), max = max(v))
)
#>                     source cited_by_count.mean cited_by_count.median
#> 1     Agricultural Systems                18.0                  18.0
#> 2         Agronomy Reviews                 9.0                   9.0
#> 3             Crop Science                17.0                  17.0
#> 4              Field Crops                42.0                  42.0
#> 5          Plant Nutrition                31.0                  31.0
#> 6             Plant Stress                55.0                  55.0
#> 7    Precision Agriculture                12.0                  12.0
#> 8           Remote Sensing                28.0                  28.0
#> 9             Soil Biology                26.0                  26.0
#> 10            Soil Science                28.5                  28.5
#> 11 Sustainable Agriculture                14.0                  14.0
#>    cited_by_count.max
#> 1                18.0
#> 2                 9.0
#> 3                17.0
#> 4                42.0
#> 5                31.0
#> 6                55.0
#> 7                12.0
#> 8                28.0
#> 9                26.0
#> 10               35.0
#> 11               14.0
```

### 7.4 The `biblio_metrics()` overview

``` r

m <- biblio_metrics(x)
head(m, 6)
#>              author documents citations h_index g_index   m_index
#> A0000043f     Rao F         3        61       3       3 0.7500000
#> A00000621    Lima D         3        62       3       3 0.6000000
#> A000008ad   Silva A         4       137       4       4 0.4444444
#> A000008c4   Costa C         3        65       3       3 0.5000000
#> A00000905   Gomez E         3       103       3       3 0.5000000
#> A00000f4d Martins B         4        97       4       4 0.6666667
```

Each author gets publication count, total citations, h-index, g-index
and m-index. These are computed from the relational tables, not from a
flat file — so they automatically reflect any deduplication or
enrichment you have already applied.

## 8. Export formats

Once your data is harmonized, you may need to hand it to a colleague, a
visualization tool, or a downstream analysis pipeline. biblioIntegrator
provides four export functions.

### 8.1 `to_bibliometrix()` — bibliometrix compatibility

``` r

mx <- to_bibliometrix(x)
dim(mx)
#> [1] 12  7
names(mx)
#> [1] "TI" "PY" "DI" "SO" "TC" "AU" "DE"
```

``` r

head(mx[, c("TI", "PY", "DI", "SO", "TC")], 4)
#>                                       TI   PY             DI              SO TC
#> 1 Silicon and salinity tolerance in rice 2018 10.1000/agri.1     Field Crops 42
#> 2          Soil carbon under cover crops 2019 10.1000/agri.2    Soil Science 35
#> 3     Remote sensing of soybean nitrogen 2020 10.1000/agri.3  Remote Sensing 28
#> 4     Silicon nutrition in maize drought 2021 10.1000/agri.4 Plant Nutrition 31
```

The output is a flat data frame with the field tags that
**bibliometrix** expects (`TI`, `PY`, `DI`, `SO`, `TC`, `AU`, `DE`). You
can pass it directly to
[`bibliometrix::biblioAnalysis()`](https://rdrr.io/pkg/bibliometrix/man/biblioAnalysis.html)
or any other bibliometrix function.

``` r

# Authors are semicolon-separated, matching bibliometrix convention
head(mx$AU, 4)
#> [1] "Silva A;Pereira W" "Martins B;Costa C" "Lima D;Pereira W" 
#> [4] "Silva A;Gomez E"
```

``` r

# Keywords are semicolon-separated
head(mx$DE, 4)
#> [1] "silicon;salinity;rice"           "soil carbon;cover crops"        
#> [3] "remote sensing;soybean;nitrogen" "silicon;drought;maize"
```

**When to use:** Your collaborator sends you a script that starts with
`bibliometrix::biblioAnalysis(M)`. Convert your `biblio_project` to
bibliometrix format and pass it as `M`. No data is lost — the relational
model stays in your R session.

### 8.2 `to_biblium()` — Biblium compatibility

**Biblium** is a Python-based bibliometric analysis tool (Umek, 2026).
Its canonical column names differ from bibliometrix.

``` r

bu <- to_biblium(x)
dim(bu)
#> [1] 12  4
names(bu)
#> [1] "Title"           "Year"            "Authors"         "Author Keywords"
```

``` r

head(bu, 4)
#>                                    Title Year            Authors
#> 1 Silicon and salinity tolerance in rice 2018 Silva A; Pereira W
#> 2          Soil carbon under cover crops 2019 Martins B; Costa C
#> 3     Remote sensing of soybean nitrogen 2020  Lima D; Pereira W
#> 4     Silicon nutrition in maize drought 2021   Silva A; Gomez E
#>                     Author Keywords
#> 1           silicon; salinity; rice
#> 2          soil carbon; cover crops
#> 3 remote sensing; soybean; nitrogen
#> 4           silicon; drought; maize
```

#### 8.2.1 Validating against Biblium schema

When the **reticulate** and **Biblium** Python packages are installed,
you can cross-validate your data against Biblium’s own schema:

``` r

# Requires reticulate + Biblium Python package
# validate_biblium(x, groups = rep(c("A", "B"), 6))
```

This is primarily useful in comparative-group workflows (see
`v04-comparative-inference.Rmd`).

### 8.3 `export_biblio()` — generic file export

[`export_biblio()`](https://wep69.github.io/biblioIntegrator/reference/export_biblio.md)
writes every table in the `biblio_project` to a directory as separate
files. Three formats are supported: CSV, JSON and Parquet.

#### 8.3.1 CSV export

``` r

out_dir <- tempfile(pattern = "biblio_export_")
export_biblio(x, out_dir, format = "csv")
list.files(out_dir)
#> [1] "authors.csv"     "authorships.csv" "keywords.csv"    "provenance.csv" 
#> [5] "references.csv"  "works.csv"
```

``` r

# Read one table back
head(utils::read.csv(file.path(out_dir, "works.csv")), 3)
#>     work_id                                  title year            doi
#> 1 W0001f7e3 Silicon and salinity tolerance in rice 2018 10.1000/agri.1
#> 2 W000160f5          Soil carbon under cover crops 2019 10.1000/agri.2
#> 3 W0001b6e0     Remote sensing of soybean nitrogen 2020 10.1000/agri.3
#>           source cited_by_count abstract
#> 1    Field Crops             42       NA
#> 2   Soil Science             35       NA
#> 3 Remote Sensing             28       NA
```

#### 8.3.2 JSON export

``` r

out_json <- tempfile(pattern = "biblio_json_")
export_biblio(x, out_json, format = "json")
list.files(out_json)
#> [1] "authors.json"     "authorships.json" "keywords.json"    "provenance.json" 
#> [5] "references.json"  "works.json"
```

#### 8.3.3 Parquet export (requires arrow)

``` r

# Requires the arrow package
if (requireNamespace("arrow", quietly = TRUE)) {
  out_parq <- tempfile(pattern = "biblio_parq_")
  export_biblio(x, out_parq, format = "parquet")
  list.files(out_parq)
}
```

**Why Parquet?** Column-oriented, compressed, self-describing. For
corpora above 50 000 works, Parquet files are typically 3–5× smaller
than CSV and load 10× faster into R or Python. The `arrow` package
provides transparent reading.

#### 8.3.4 Exporting multiple formats in a loop

``` r

# Export the same project in all three formats
for (fmt in c("csv", "json")) {
  d <- file.path(tempdir(), paste0("export_", fmt))
  export_biblio(x, d, format = fmt)
  cat(fmt, ":", length(list.files(d)), "files in", d, "\n")
}
#> csv : 6 files in C:\Users\wep69\AppData\Local\Temp\RtmpUxp3uM/export_csv 
#> json : 6 files in C:\Users\wep69\AppData\Local\Temp\RtmpUxp3uM/export_json
```

### 8.4 `export_vosviewer()` — VOSviewer network files

**VOSviewer** (van Eck & Waltman, 2010) is a widely-used tool for
bibliometric network visualization. It reads a specific text-based
network format.
[`export_vosviewer()`](https://wep69.github.io/biblioIntegrator/reference/export_vosviewer.md)
converts an igraph object to that format.

``` r

# Build a simple keyword co-occurrence network and export it
# (bibliographic_network() is covered in v05-networks.Rmd)
g <- bibliographic_network(x, "keyword")
```

``` r

vos_path <- tempfile(fileext = ".txt")
export_vosviewer(g, vos_path)
readLines(vos_path, n = 5)
#> [1] "from\tto\tweight"            "cover crops\taggregation\t1"
#> [3] "cover crops\tsoil carbon\t1" "silicon\tdrought\t1"        
#> [5] "maize\tefficiency\t1"
```

#### 8.4.1 Exporting a co-authorship network for VOSviewer

``` r

g_coauth <- bibliographic_network(x, "coauthor")
vos_coauth <- tempfile(fileext = ".txt")
export_vosviewer(g_coauth, vos_coauth)
readLines(vos_coauth, n = 5)
#> [1] "from\tto\tweight"        "A000008c4\tA00000621\t1"
#> [3] "A00000905\tA000008ad\t2" "A000008c4\tA00000f4d\t1"
#> [5] "A00000f4d\tA00000f73\t1"
```

**Workflow:** Build networks in R with
[`bibliographic_network()`](https://wep69.github.io/biblioIntegrator/reference/bibliographic_network.md),
export with
[`export_vosviewer()`](https://wep69.github.io/biblioIntegrator/reference/export_vosviewer.md),
open the `.txt` file in VOSviewer’s “Create map from network file”
dialog. VOSviewer handles the layout.

## 9. Data integrity validation

After importing, merging, or enriching data, you should verify that the
relational structure is still consistent. biblioIntegrator provides
several tools for this.

### 9.1 Referential integrity

Every foreign key in the `biblio_project` should point to an existing
primary key. In a well-formed project:

- Every `work_id` in `$authorships` exists in `$works`.
- Every `author_id` in `$authorships` exists in `$authors`.
- Every `work_id` in `$keywords` exists in `$works`.
- Every `citing_id` and `cited_id` in `$references` exists in `$works`.

``` r

# Check authorship-work integrity
orphan_auth <- x$authorships$work_id[!x$authorships$work_id %in% x$works$work_id]
cat("Orphan authorship records (no matching work):", length(orphan_auth), "\n")
#> Orphan authorship records (no matching work): 0
```

``` r

# Check authorship-author integrity
orphan_au <- x$authorships$author_id[!x$authorships$author_id %in% x$authors$author_id]
cat("Orphan authorship records (no matching author):", length(orphan_au), "\n")
#> Orphan authorship records (no matching author): 0
```

``` r

# Check keyword-work integrity
orphan_kw <- x$keywords$work_id[!x$keywords$work_id %in% x$works$work_id]
cat("Orphan keyword records (no matching work):", length(orphan_kw), "\n")
#> Orphan keyword records (no matching work): 0
```

``` r

# Check reference integrity (only when references are present)
if (nrow(x$references) > 0) {
  orphan_ref_cit <- x$references$citing_id[
    !x$references$citing_id %in% x$works$work_id]
  orphan_ref_ced <- x$references$cited_id[
    !x$references$cited_id %in% x$works$work_id]
  cat("Orphan citing refs:", length(orphan_ref_cit), "\n")
  cat("Orphan cited refs:", length(orphan_ref_ced), "\n")
} else {
  cat("No references table entries to check.\n")
}
#> No references table entries to check.
```

A clean project will show 0 orphans everywhere. Non-zero values mean
something went wrong during merge, deduplication, or subsetting.

### 9.2 Full integrity check

You can wrap all the checks above in a single validator:

``` r

validate_integrity <- function(p) {
  checks <- data.frame(
    check = c(
      "authorship_work_orphans",
      "authorship_author_orphans",
      "keyword_work_orphans",
      "reference_citing_orphans",
      "reference_cited_orphans"
    ),
    n = c(
      sum(!p$authorships$work_id %in% p$works$work_id),
      sum(!p$authorships$author_id %in% p$authors$author_id),
      sum(!p$keywords$work_id %in% p$works$work_id),
      if (nrow(p$references) > 0)
        sum(!p$references$citing_id %in% p$works$work_id) else 0L,
      if (nrow(p$references) > 0)
        sum(!p$references$cited_id %in% p$works$work_id) else 0L
    ),
    stringsAsFactors = FALSE
  )
  checks
}

validate_integrity(x)
#>                       check n
#> 1   authorship_work_orphans 0
#> 2 authorship_author_orphans 0
#> 3      keyword_work_orphans 0
#> 4  reference_citing_orphans 0
#> 5   reference_cited_orphans 0
```

### 9.3 Provenance verification

After any operation, provenance should be monotonically growing. You
should never see fewer rows in `$provenance` than before the operation.

``` r

prov_before <- nrow(x$provenance)

# Simulate a merge: combine two projects
x2 <- as_biblio_project(
  rbind(raw, utils::tail(raw, 4)),
  source = "additional records"
)

# Provenance should have at least as many rows as before
prov_after <- nrow(x2$provenance)
cat("Provenance rows: before =", prov_before, ", after =", prov_after, "\n")
#> Provenance rows: before = 1 , after = 1
stopifnot(prov_after >= prov_before)
```

### 9.4 Detecting duplicate DOIs after merge

A common integrity issue after merging two sources: a work appears in
both with the same DOI but slightly different metadata.
[`biblio_health()`](https://wep69.github.io/biblioIntegrator/reference/biblio_health.md)
catches this.

``` r

# Merge two copies of the same corpus
merged_raw <- rbind(raw, raw)
merged_proj <- as_biblio_project(merged_raw, source = "merged")
health <- biblio_health(merged_proj)
health
#>                  check  n
#> 1        missing_title  0
#> 2         missing_year  0
#> 3          missing_doi  0
#> 4        duplicate_doi 12
#> 5 duplicate_title_year 12
#> 6   negative_citations  0
```

``` r

# The duplicate_doi check should catch the duplicates
subset(health, n > 0)
#>                  check  n
#> 4        duplicate_doi 12
#> 5 duplicate_title_year 12
```

The solution is
[`deduplicate_biblio()`](https://wep69.github.io/biblioIntegrator/reference/deduplicate_biblio.md),
covered in `v02-quality-dedup.Rmd`.

### 9.5 Checking for missing DOIs

Missing DOIs make cross-database matching unreliable.

``` r

# Percentage of works with a DOI
pct_with_doi <- 100 * sum(nzchar(x$works$doi)) / nrow(x$works)
cat(sprintf("%.1f%% of works have a DOI.\n", pct_with_doi))
#> 100.0% of works have a DOI.
```

``` r

# If any DOIs are missing, identify those works
missing_doi_works <- x$works[!nzchar(x$works$doi), ]
if (nrow(missing_doi_works) > 0) {
  cat("Works without DOI:\n")
  print(missing_doi_works[, c("title", "year", "source")])
} else {
  cat("All works have a DOI.\n")
}
#> All works have a DOI.
```

### 9.6 Checking abstract coverage

For text analysis (covered in `v06-temporal-text.Rmd`), you need
abstracts.

``` r

pct_with_abs <- 100 * sum(nzchar(trimws(x$works$abstract))) / nrow(x$works)
cat(sprintf("%.1f%% of works have an abstract.\n", pct_with_abs))
#> 0.0% of works have an abstract.
```

### 9.7 Year sanity checks

``` r

current_year <- as.integer(format(Sys.Date(), "%Y"))
future_works <- x$works$year > current_year
na_year <- is.na(x$works$year)
cat("Works with year in the future:", sum(future_works, na.rm = TRUE), "\n")
#> Works with year in the future: 0
cat("Works with missing year:", sum(na_year), "\n")
#> Works with missing year: 0
```

## 10. Merging multiple sources

Real bibliometric projects almost always draw from more than one
database. biblioIntegrator handles this through a simple workflow:
import each source as a `biblio_project`, then combine their data frames
and re-harmonize.

### 10.1 The merge pattern

``` r

# Simulate two sources: Scopus-style and WoS-style
scopus_raw <- raw[1:8, ]
wos_raw <- raw[5:12, ]

# Import each
x_scopus <- as_biblio_project(scopus_raw, source = "scopus")
x_wos <- as_biblio_project(wos_raw, source = "wos")
```

``` r

# Combine and re-harmonize
combined_raw <- rbind(scopus_raw, wos_raw)
x_combined <- as_biblio_project(combined_raw, source = "merged_scopus_wos")

cat("Scopus alone:", nrow(x_scopus$works), "works\n")
#> Scopus alone: 8 works
cat("WoS alone:", nrow(x_wos$works), "works\n")
#> WoS alone: 8 works
cat("Combined (before dedup):", nrow(x_combined$works), "works\n")
#> Combined (before dedup): 16 works
```

``` r

# Deduplicate
x_dedup <- deduplicate_biblio(x_combined)
cat("After dedup:", nrow(x_dedup$works), "works\n")
#> After dedup: 12 works
```

### 10.2 Tracking merge provenance

``` r

audit_biblio(x_dedup)
#>                    timestamp          operation                        details
#> 1 2026-09-22 03:17:52.128248  as_biblio_project source=merged_scopus_wos; n=16
#> 2 2026-09-22 03:17:52.191304 deduplicate_biblio                      removed=4
```

The provenance table tells you the full story: which sources were
merged, when, and how many duplicates were removed.

### 10.3 Cross-source coverage analysis

``` r

compare_sources(x_scopus, x_wos)
#> $coverage
#>          source records unique
#> source1 source1       8      8
#> source2 source2       8      8
#> 
#> $overlap
#>   source1 source2 intersection
#> 1 source1 source2            4
```

The `$coverage` table shows per-source record counts and unique-record
counts. The `$overlap` table shows how many works appear in both sources
(matched by DOI or normalized title+year).

### 10.4 Multi-source merge best practices

1.  **Import each source separately.** This preserves the original
    `source` label and makes error diagnosis easier.
2.  **Inspect
    [`biblio_health()`](https://wep69.github.io/biblioIntegrator/reference/biblio_health.md)
    on each source before merging.** Fix obvious errors (missing DOIs,
    wrong years) before they propagate.
3.  **Combine raw data frames, then re-harmonize.** Do not try to merge
    two `biblio_project` objects directly — their work IDs may conflict.
4.  **Deduplicate after merge.** The same work may appear in both
    sources with different metadata. Let
    [`deduplicate_biblio()`](https://wep69.github.io/biblioIntegrator/reference/deduplicate_biblio.md)
    find the overlaps.
5.  **Verify integrity after merge.** Run `validate_integrity()`,
    [`biblio_health()`](https://wep69.github.io/biblioIntegrator/reference/biblio_health.md)
    and check
    [`audit_biblio()`](https://wep69.github.io/biblioIntegrator/reference/audit_biblio.md)
    provenance.

## 11. Common mistakes and how to avoid them

### 11.1 Assuming all databases use the same field names

**Problem:** You import a Scopus CSV and a Dimensions CSV into the same
data frame. The `Authors` column in Scopus conflicts with the `authors`
column in Dimensions.

**Solution:** Import each source separately via
[`biblio_import()`](https://wep69.github.io/biblioIntegrator/reference/biblio_import.md)
or
[`as_biblio_project()`](https://wep69.github.io/biblioIntegrator/reference/as_biblio_project.md).
The column-resolution logic (Section 4.1) handles name variants
automatically. Only merge the raw data frames *after* understanding
which fields each has.

### 11.2 Ignoring missing DOIs

**Problem:** 30% of your records have no DOI. Deduplication on DOI alone
misses those overlaps. You end up double-counting works.

**Solution:** Before deduplication, check
[`biblio_health()`](https://wep69.github.io/biblioIntegrator/reference/biblio_health.md).
For DOI-less records,
[`deduplicate_biblio()`](https://wep69.github.io/biblioIntegrator/reference/deduplicate_biblio.md)
falls back to title+year matching — but only if titles are consistent.
Enrich missing DOIs via OpenAlex
([`fetch_openalex()`](https://wep69.github.io/biblioIntegrator/reference/fetch_openalex.md))
or Crossref when possible.

### 11.3 Not normalizing author names

**Problem:** “Pereira, W.E.” and “Pereira W” and “Pereira, Walter
Esfrain” are all the same person but get different `author_id` values.

**Solution:** biblioIntegrator generates deterministic IDs from the raw
name string. It does not perform fuzzy name matching. For author
disambiguation, either:

- Standardize names in the source data before import.
- Use `openalexR` or Semantic Scholar to retrieve canonical author IDs.
- Apply a post-processing step that merges author IDs based on known
  identities.

### 11.4 Losing provenance during merge

**Problem:** You manually [`rbind()`](https://rdrr.io/r/base/cbind.html)
two `biblio_project` objects. The provenance table from one source is
lost.

**Solution:** Always work with data frames, not `biblio_project`
objects, when merging. Use `rbind(works1, works2)` on the raw data, then
pass the combined frame to
[`as_biblio_project()`](https://wep69.github.io/biblioIntegrator/reference/as_biblio_project.md).
This ensures fresh provenance is recorded.

### 11.5 Treating import as a one-time event

**Problem:** You import once, build your analysis, then want to add new
records six months later. You have forgotten how the original import was
done.

**Solution:** Save `audit_biblio(x)` to disk after every import. The
provenance table records the source label and record count. Save the
import script alongside the data so re-imports are reproducible.

### 11.6 Not checking year ranges

**Problem:** A Web of Science export includes “Early Access” records
assigned to the current year. When merged with Scopus data, some works
suddenly have year=2027 – a year that has not happened yet.

**Solution:** After import, run
[`biblio_health()`](https://wep69.github.io/biblioIntegrator/reference/biblio_health.md)
and check `max(x$works$year)`. If future years appear, investigate the
source data. Some databases assign projected publication years to
preprints.

### 11.7 Losing keywords during harmonization

**Problem:** Your source data has both `author_keywords` and a
`keywords_plus` column. Only one is picked up.

**Solution:** The column-resolution logic picks the first match from the
list `keywords`, `de`, `author_keywords`. If your data has a second
keyword column, either rename it to `author_keywords` before import or
manually append it to the `$keywords` table after harmonization:

``` r

# If your data had a "keywords_plus" column:
# extra_kw <- raw[, c("work_id", "keywords_plus")]
# extra_kw_split <- strsplit(extra_kw$keywords_plus, ";")
# ... convert to data.frame and rbind with x$keywords
```

### 11.8 Ignoring abstract encoding issues

**Problem:** Abstracts from PubMed contain special Unicode characters
(μ, ±, →) that cause downstream text-analysis functions to fail.

**Solution:** Check abstract encoding after import:

``` r

# Count non-ASCII characters in abstracts
non_ascii <- grep("[^\x01-\x7F]", x$works$abstract)
cat("Works with non-ASCII chars in abstract:", length(non_ascii), "\n")
#> Works with non-ASCII chars in abstract: 0
```

If encoding issues arise, normalise with
[`stringi::stri_trans_general()`](https://rdrr.io/pkg/stringi/man/stri_trans_general.html)
or [`iconv()`](https://rdrr.io/r/base/iconv.html) before proceeding to
text analysis.

## 12. Extending the import layer

biblioIntegrator’s import functions are simple enough that adding a new
source is straightforward.

### 12.1 Adding a custom CSV importer

``` r

# Suppose your institution exports bibliographic data with custom column names
my_import <- function(path) {
  d <- utils::read.csv(path, stringsAsFactors = FALSE)
  # Map your columns to standard names
  names(d)[names(d) == "Document.Title"] <- "title"
  names(d)[names(d) == "Pub.Year"]      <- "year"
  names(d)[names(d) == "Authors.List"]  <- "authors"
  names(d)[names(d) == "DOI.Number"]    <- "doi"
  names(d)[names(d) == "Ref.Source"]    <- "source"
  names(d)[names(d) == "Patent.Cites"]  <- "citations"
  names(d)[names(d) == "Abstract.Text"] <- "abstract"
  as_biblio_project(d, source = basename(path))
}
```

### 12.2 Adding a custom API importer

``` r

# Generic pattern for any JSON API
# my_api_import <- function(query, n = 10) {
#   resp <- httr2::request("https://api.example.org/works") |>
#     httr2::req_url_query(q = query, limit = n) |>
#     httr2::req_perform()
#   items <- httr2::resp_body_json(resp, simplifyVector = TRUE)$results
#   d <- data.frame(
#     title   = items$title,
#     year    = items$publication_year,
#     doi     = items$doi,
#     authors = vapply(items$authors, paste, "", collapse = "; "),
#     stringsAsFactors = FALSE
#   )
#   as_biblio_project(d, source = "my_api")
# }
```

### 12.3 Round-trip verification template

Whenever you add a new import path, verify the round-trip:

``` r

# Template: write data, import, compare
verify_roundtrip <- function(original_df, imported_project) {
  cat("Original rows:  ", nrow(original_df), "\n")
  cat("Imported works: ", nrow(imported_project$works), "\n")
  cat("Authors found:  ", nrow(imported_project$authors), "\n")
  cat("Keywords found: ", nrow(imported_project$keywords), "\n")
  # Basic sanity checks
  stopifnot(nrow(imported_project$works) == nrow(original_df))
  stopifnot(nrow(imported_project$provenance) > 0)
  cat("Round-trip verified.\n")
}

verify_roundtrip(raw, x)
#> Original rows:   12 
#> Imported works:  12 
#> Authors found:   7 
#> Keywords found:  32 
#> Round-trip verified.
```

## 13. Putting it all together

This section demonstrates a complete import-and-harmonize workflow that
mirrors what you would do in a real research project.

### 13.1 A full reproducible pipeline

``` r

# Step 1: Load or import data
raw_data <- example_biblio()

# Step 2: Harmonize into relational structure
proj <- as_biblio_project(raw_data, source = "thesis-chapter-2")

# Step 3: Diagnose
biblio_health(proj)
#>                  check n
#> 1        missing_title 0
#> 2         missing_year 0
#> 3          missing_doi 0
#> 4        duplicate_doi 0
#> 5 duplicate_title_year 0
#> 6   negative_citations 0
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

# Step 4: Validate integrity
validate_integrity(proj)
#>                       check n
#> 1   authorship_work_orphans 0
#> 2 authorship_author_orphans 0
#> 3      keyword_work_orphans 0
#> 4  reference_citing_orphans 0
#> 5   reference_cited_orphans 0
audit_biblio(proj)
#>                    timestamp         operation                       details
#> 1 2026-09-22 03:17:52.667844 as_biblio_project source=thesis-chapter-2; n=12

# Step 5: Export for downstream tools
# 5a: bibliometrix for a colleague
mx <- to_bibliometrix(proj)

# 5b: Biblium for Python analysis
bu <- to_biblium(proj)

# 5c: Flat files for archiving
archive_dir <- tempfile(pattern = "thesis_archive_")
export_biblio(proj, archive_dir, format = "csv")

# Step 6: Quick network for exploratory visualization
g <- bibliographic_network(proj, "keyword")
vos_file <- tempfile(fileext = ".txt")
export_vosviewer(g, vos_file)

cat("Pipeline complete.\n")
#> Pipeline complete.
cat("Works:       ", nrow(proj$works), "\n")
#> Works:        12
cat("Authors:     ", nrow(proj$authors), "\n")
#> Authors:      7
cat("Keywords:    ", nrow(proj$keywords), "\n")
#> Keywords:     32
cat("Archive files:", list.files(archive_dir), "\n")
#> Archive files: authors.csv authorships.csv keywords.csv provenance.csv references.csv works.csv
```

### 13.2 Pipeline with bibliometrix delegation

``` r

# When your data is in RIS format and bibliometrix is installed:
if (requireNamespace("bibliometrix", quietly = TRUE)) {
  # proj_ris <- biblio_import("my_corpus.ris", format = "ris")
  # biblio_health(proj_ris)
  # describe_biblio(proj_ris)
  # to_bibliometrix(proj_ris)  # round-trip check
}
```

### 13.3 Pipeline with OpenAlex enrichment

``` r

# Enrich a DOI-less corpus via OpenAlex
# miising_doi_works <- proj$works[!nzchar(proj$works$doi), ]
# for (i in seq_len(nrow(missing_doi_works))) {
#   oa <- fetch_openalex(missing_doi_works$title[i], n = 1)
#   if (nrow(oa$works) > 0 && nzchar(oa$works$doi[1])) {
#     proj$works$doi[proj$work_id == missing_doi_works$work_id[i]] <-
#       oa$works$doi[1]
#   }
# }
```

## 14. Performance considerations

### 14.1 Import speed by format

As a rough guide:

| Format | ~10k works | ~100k works | Notes |
|:---|:---|:---|:---|
| CSV | \< 1 s | ~ 5 s | Base R [`read.table()`](https://rdrr.io/r/utils/read.table.html) |
| TSV | \< 1 s | ~ 5 s | Same engine, tab separator |
| JSON | ~ 2 s | ~ 15 s | [`jsonlite::read_json()`](https://jeroen.r-universe.dev/jsonlite/reference/read_json.html) |
| RIS | ~ 3 s | ~ 20 s | Via bibliometrix |
| BibTeX | ~ 2 s | ~ 15 s | Via bibliometrix |
| Parquet | \< 1 s | ~ 2 s | Via arrow (column-oriented) |

Harmonization (splitting authors, keywords, generating IDs) adds roughly
50% to the CSV/TSV import time for corpora under 100k works.

### 14.2 Memory usage

A `biblio_project` with 100k works typically occupies 50–80 MB in
memory. The bulk of the memory is in the `$keywords` table (which can
have 5–10× as many rows as `$works` if each work has many keywords). If
memory is tight, consider working with subsets or Parquet-backed tables
(see `v08-scalable-backends.Rmd`).

### 14.3 API rate limits

[`fetch_openalex()`](https://wep69.github.io/biblioIntegrator/reference/fetch_openalex.md)
respects the OpenAlex polite pool policy. A default `mailto` parameter
lets the API know who is making requests. Without it, you are limited to
approximately 10 requests per second. With `mailto`, the limit rises to
approximately 100 requests per second.

``` r

# Always provide mailto for production use
# x <- fetch_openalex("silicon rice", n = 50, mailto = "researcher@uni.edu")
```

## 15. Troubleshooting

### 15.1 “Cannot open file” error

**Cause:** The path contains backslashes, spaces, or non-ASCII
characters.

**Fix:** Use forward slashes or
[`normalizePath()`](https://rdrr.io/r/base/normalizePath.html):

``` r

# path <- normalizePath("C:/My Data/scopus.csv", mustWork = TRUE)
# biblio_import(path)
```

### 15.2 “For this file type install ‘bibliometrix’” error

**Cause:** You passed a `.txt`, `.ris`, `.bib`, or `.nbib` file but
`bibliometrix` is not installed.

**Fix:**

``` r

# install.packages("bibliometrix")
# Then re-run: biblio_import("myfile.ris", format = "ris")
```

### 15.3 “Columns not found” warning

**Cause:** Your CSV does not have any of the recognized column names.

**Fix:** Rename your columns to one of the standard names listed in
Section 4.1 before import, or use the custom importer pattern from
Section 12.1.

### 15.4 Empty author table

**Cause:** The source data has an `AU` column but the separator is not
`;` or `|`.

**Fix:** Pre-process the column before import:

``` r

# df$AU <- gsub(" and ", "; ", df$AU)
# df$AU <- gsub(", ", "; ", df$AU)  # careful with "Last, First" names
```

### 15.5 All works have `citations = 0`

**Cause:** The source data uses a non-standard citation-column name that
is not in the resolution list.

**Fix:** Check your data frame’s column names with `names(raw)`. If the
citation column is called something like `"Times.Cited"`, rename it to
`citations` or `cited_by_count` (or the abbreviated `TC`) before passing
to
[`as_biblio_project()`](https://wep69.github.io/biblioIntegrator/reference/as_biblio_project.md).

### 15.6 `to_bibliometrix()` returns wrong citation counts

**Cause:** The citation field was mapped to the wrong column during
import.

**Fix:** Inspect `x$works$cited_by_count` directly. If the values look
wrong, trace back to the source data and verify the column mapping.

### 15.7 “Could not convert” from bibliometrix

**Cause:**
[`bibliometrix::convert2df()`](https://rdrr.io/pkg/bibliometrix/man/convert2df.html)
does not recognize your file format even with the `format` and
`dbsource` arguments.

**Fix:** Open the file in a text editor and confirm its structure.
Common issues:

- The file is actually CSV despite having a `.txt` extension.
- The file contains BOM markers at the start.
- The file is encoded in Latin-1 rather than UTF-8.

Convert to UTF-8 CSV and import natively.

## 16. Session information

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
#> [1] biblioIntegrator_0.3.0
#> 
#> loaded via a namespace (and not attached):
#>  [1] cli_3.6.6           knitr_1.52          rlang_1.3.0        
#>  [4] xfun_0.61           otel_0.2.0          textshaping_1.0.5  
#>  [7] data.table_1.18.6.1 jsonlite_2.0.0      htmltools_0.5.9    
#> [10] ragg_1.5.2          sass_0.4.10         rmarkdown_2.32     
#> [13] evaluate_1.0.5      jquerylib_0.1.4     fastmap_1.2.0      
#> [16] yaml_2.3.12         lifecycle_1.0.5     compiler_4.6.0     
#> [19] igraph_2.3.3        fs_2.1.0            htmlwidgets_1.6.4  
#> [22] pkgconfig_2.0.3     biblionetwork_0.1.0 systemfonts_1.3.2  
#> [25] digest_0.6.39       R6_2.6.1            Rdpack_2.6.6       
#> [28] rbibutils_2.4.1     magrittr_2.0.5      bslib_0.12.0       
#> [31] tools_4.6.0         pkgdown_2.2.1       cachem_1.1.0       
#> [34] desc_1.4.3
```

## 17. References

- Aria, M. & Cuccurullo, C. (2017). bibliometrix: An R-tool for
  comprehensive science mapping analysis. *Journal of Informetrics*,
  11(4), 959–975. <doi:10.1016/j.joi.2017.08.007>

- Umek, L. (2026). Biblium: a Python library for comparative
  bibliometric analysis. *Scientometrics*, 131(5), 3359–3377.
  <doi:10.1007/s11192-026-05636-8>

- Priem, J., Piwowar, H., & Orr, R. (2022). OpenAlex: A fully-open index
  of scholarly works, authors, venues, institutions and concepts. *arXiv
  preprint* arXiv:2205.01833.

- van Eck, N.J. & Waltman, L. (2010). Software survey: VOSviewer, a
  computer program for bibliometric mapping. *Scientometrics*, 84(2),
  523–538. <doi:10.1007/s11192-009-0146-3>

- Peroni, S. & Shotton, D. (2020). OpenCitations, an infrastructure
  organization for open scholarship. *Quantitative Science Studies*,
  1(1), 428–444. <doi:10.1162/qss_a_00023>

## Interpretation

Import and harmonization are **infrastructure steps**. Their purpose is
to get your data into a consistent, auditable shape so that every
downstream analysis — descriptive statistics, group comparisons,
networks, text mining — starts from the same reliable foundation.

Remember these principles:

1.  **Separate import from harmonization.** Inspect your data frame
    before converting it to a `biblio_project`.
2.  **Every operation should leave a trace.** The provenance table is
    your audit log. Read it before publishing any results.
3.  **Validate after every manipulation.**
    [`biblio_health()`](https://wep69.github.io/biblioIntegrator/reference/biblio_health.md)
    and `validate_integrity()` are fast — use them liberally.
4.  **Never assume column names.** Use `names(your_df)` and the
    resolution table to understand what will be mapped.
5.  **Preserve source labels.** The `source` parameter in
    [`as_biblio_project()`](https://wep69.github.io/biblioIntegrator/reference/as_biblio_project.md)
    is recorded in provenance and helps you trace results back to their
    origin.

When you are confident that your data is clean and its provenance is
complete, proceed to `v02-quality-dedup.Rmd` for deduplication and
quality control, or to `v03-descriptive-impact.Rmd` for descriptive and
impact analysis.

## Appendix A: Full function reference

| Function | Category | Description |
|:---|:---|:---|
| [`example_biblio()`](https://wep69.github.io/biblioIntegrator/reference/example_biblio.md) | Import | Built-in 12-record agronomy teaching corpus |
| [`biblio_import()`](https://wep69.github.io/biblioIntegrator/reference/biblio_import.md) | Import | Import CSV, TSV, JSON, or delegate to bibliometrix |
| [`as_biblio_project()`](https://wep69.github.io/biblioIntegrator/reference/as_biblio_project.md) | Harmonize | Convert data frame to relational `biblio_project` |
| [`fetch_openalex()`](https://wep69.github.io/biblioIntegrator/reference/fetch_openalex.md) | Import | Fetch works from the OpenAlex REST API |
| [`fetch_opencitations()`](https://wep69.github.io/biblioIntegrator/reference/fetch_opencitations.md) | Import | Fetch citation links from OpenCitations API |
| [`to_bibliometrix()`](https://wep69.github.io/biblioIntegrator/reference/to_bibliometrix.md) | Export | Convert to bibliometrix field-tag data frame |
| [`to_biblium()`](https://wep69.github.io/biblioIntegrator/reference/to_biblium.md) | Export | Convert to Biblium canonical field names |
| [`export_biblio()`](https://wep69.github.io/biblioIntegrator/reference/export_biblio.md) | Export | Write tables to CSV, JSON, or Parquet files |
| [`export_vosviewer()`](https://wep69.github.io/biblioIntegrator/reference/export_vosviewer.md) | Export | Write igraph network to VOSviewer text format |
| [`audit_biblio()`](https://wep69.github.io/biblioIntegrator/reference/audit_biblio.md) | Inspect | Return the provenance table |
| [`biblio_health()`](https://wep69.github.io/biblioIntegrator/reference/biblio_health.md) | Inspect | Diagnose missing/invalid/duplicate fields |
| [`describe_biblio()`](https://wep69.github.io/biblioIntegrator/reference/describe_biblio.md) | Inspect | Descriptive summary (annual, sources, keywords) |
| [`biblio_metrics()`](https://wep69.github.io/biblioIntegrator/reference/biblio_metrics.md) | Inspect | Author-level h-index, g-index, m-index |
| [`normalized_citations()`](https://wep69.github.io/biblioIntegrator/reference/normalized_citations.md) | Inspect | Field/year normalized citation scores |
| [`citation_velocity()`](https://wep69.github.io/biblioIntegrator/reference/citation_velocity.md) | Inspect | Citations per year since publication |
| [`compare_sources()`](https://wep69.github.io/biblioIntegrator/reference/compare_sources.md) | Inspect | Cross-source coverage and overlap analysis |
| [`deduplicate_biblio()`](https://wep69.github.io/biblioIntegrator/reference/deduplicate_biblio.md) | Clean | Remove duplicates by DOI or title+year |
| [`validate_biblium()`](https://wep69.github.io/biblioIntegrator/reference/validate_biblium.md) | Validate | Cross-validate with Biblium Python engine |

## Appendix B: Typical Data Formats and Column Mappings

### Scopus CSV

Scopus exports come as CSV with columns like:

| Scopus column     | biblioIntegrator logical   |
|:------------------|:---------------------------|
| `Title`           | `title`                    |
| `Year`            | `year`                     |
| `DOI`             | `doi`                      |
| `Authors`         | `authors` (separator: `;`) |
| `Author Keywords` | `keywords`                 |
| `Source title`    | `source`                   |
| `Cited by`        | `cited_by_count`           |
| `Abstract`        | `abstract`                 |

### Web of Science (field-tag)

WoS plain-text exports use two-letter field tags at the start of lines:

| WoS tag | biblioIntegrator logical |
|:--------|:-------------------------|
| `TI`    | `title`                  |
| `PY`    | `year`                   |
| `DI`    | `doi`                    |
| `AU`    | `authors`                |
| `DE`    | `keywords`               |
| `SO`    | `source`                 |
| `TC`    | `cited_by_count`         |
| `AB`    | `abstract`               |

### PubMed / MEDLINE

PubMed exports (`.nbib` or XML) require `bibliometrix` delegation:

``` r

# With bibliometrix installed:
# x_pubmed <- biblio_import("pubmed_result.nbib", dbsource = "pubmed")
```

## Appendix C: Glossary

- **biblio_project**: The central data structure — a named list of six
  data frames (`works`, `authorships`, `authors`, `keywords`,
  `references`, `provenance`) with class `"biblio_project"`.
- **work_id**: A deterministic hash identifying a unique bibliographic
  work.
- **author_id**: A deterministic hash identifying a unique author name
  string.
- **Provenance**: A cumulative, append-only log of every operation
  performed on a `biblio_project`.
- **Harmonization**: The process of converting a flat data frame into
  the relational `biblio_project` structure.
- **Native format**: A file format (CSV, TSV, JSON) handled by
  [`biblio_import()`](https://wep69.github.io/biblioIntegrator/reference/biblio_import.md)
  without optional dependencies.
- **Delegated format**: A file format (RIS, BibTeX, etc.) handled by
  [`bibliometrix::convert2df()`](https://rdrr.io/pkg/bibliometrix/man/convert2df.html)
  when that package is installed.
- **Orphan record**: A row in `authorships`, `keywords` or `references`
  whose foreign key does not exist in the corresponding primary table.
- **DOI normalization**: The process of standardizing DOI strings to a
  canonical lowercase form without URL prefixes.
- **Column resolution**: The case-insensitive, first-match-wins logic
  that maps diverse source column names to logical fields.

## Appendix D: Quick-start checklist

A printable checklist for new users:

Install biblioIntegrator: `install.packages("biblioIntegrator")`

Load the package:
[`library(biblioIntegrator)`](https://rdrr.io/r/base/library.html)

Explore the teaching corpus:
[`example_biblio()`](https://wep69.github.io/biblioIntegrator/reference/example_biblio.md)
— familiarise yourself with the expected column names.

Export your data from Scopus/WoS/Dimensions as CSV (UTF-8).

Inspect column names: `names(your_df)`. Check the resolution table
(Section 6.1) to confirm they will be mapped.

Import: `x <- biblio_import("your_file.csv")` or
`x <- as_biblio_project(your_df, source = "scopus")`

Health check: `biblio_health(x)` — fix any non-zero rows.

Integrity check: `validate_integrity(x)` — verify 0 orphans.

Provenance check: `audit_biblio(x)` — confirm source label and record
count look right.

Export: `export_biblio(x, "output_dir", "csv")` for archiving.

Continue to `v02-quality-dedup.Rmd` for deduplication.

## Appendix E: Reproducibility template

``` r

# Reproducible bibliometric import-and-harmonize template
# Save this script alongside your data for transparent, repeatable analysis.

# --- Configuration ---
SOURCE_NAME  <- "scopus_2025q3"
INPUT_FILE   <- "data/scopus_export.csv"
OUTPUT_DIR   <- "output/harmonized"
FORMAT       <- "csv"

# --- Load ---
library(biblioIntegrator)

# --- Import ---
raw <- utils::read.csv(INPUT_FILE, stringsAsFactors = FALSE,
                       fileEncoding = "UTF-8-BOM")
cat("Raw records:", nrow(raw), "\n")

# --- Harmonize ---
proj <- as_biblio_project(raw, source = SOURCE_NAME)

# --- Validate ---
cat("\n=== Health ===\n")
print(biblio_health(proj))

cat("\n=== Integrity ===\n")
int <- validate_integrity(proj)
print(int)
stopifnot(all(int$n == 0L))

cat("\n=== Provenance ===\n")
print(audit_biblio(proj))

# --- Describe ---
desc <- describe_biblio(proj)
cat("\nDocuments:", desc$n_documents, "\n")
cat("Years:", desc$years[1], "to", desc$years[2], "\n")
cat("Total citations:", desc$total_citations, "\n")

# --- Export ---
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)
export_biblio(proj, OUTPUT_DIR, format = FORMAT)
cat("\nExported to:", OUTPUT_DIR, "\n")
cat("Files:", paste(list.files(OUTPUT_DIR), collapse = ", "), "\n")

# --- Save provenance separately ---
utils::write.csv(
  audit_biblio(proj),
  file.path(OUTPUT_DIR, "provenance.csv"),
  row.names = FALSE
)
cat("Provenance saved.\n")

cat("\n=== Done. Continue with v02-quality-dedup.Rmd ===\n")
```
