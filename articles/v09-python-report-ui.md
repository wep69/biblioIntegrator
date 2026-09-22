# Python Integration, Reports and Interactive Use

## Why This Vignette Exists

### The Three Bridges

Bibliometric analysis in R is powerful, but three complementary
capabilities extend its reach beyond what a single language can offer:

1.  **Python integration** — The
    [Biblium](https://pypi.org/project/biblium/) library implements a
    permutation-based group comparison interface that mirrors the native
    R engine. Running both engines on the same data and comparing their
    outputs provides an independent computational check. When Biblium is
    available, `biblioIntegrator` can call it transparently via
    `reticulate` and convert results back into the same R structure used
    by
    [`compare_groups()`](https://wep69.github.io/biblioIntegrator/reference/compare_groups.md).

2.  **Parametric reports** — A `biblio_project` can be summarised into a
    single Markdown, HTML, Word, or PDF file by
    [`biblio_report()`](https://wep69.github.io/biblioIntegrator/reference/biblio_report.md).
    The report captures corpus health, descriptive metrics, annual
    production, leading terms, network centrality, backend availability,
    and provenance. Reports are self-contained and auditable: every
    number traces to the underlying relational tables.

3.  **Interactive exploration** —
    [`biblio_app()`](https://wep69.github.io/biblioIntegrator/reference/biblio_app.md)
    launches a Shiny workbench with five tabs (Data, Explore, Networks,
    Compare, Report). The app lets non-programmers load data, inspect
    quality, visualise annual production, browse centrality tables, and
    download a report — all without writing a single line of R code.

Together, these three bridges allow a research team to:

- Run comparative inference in **two independent engines** and quantify
  agreement.
- Generate **reproducible reports** that document every analytical
  decision.
- Provide a **point-and-click interface** for collaborators who prefer
  not to use the R console.

### What This Vignette Does *Not* Cover

Python integration and Biblium are **optional**. Every analytical
function discussed in earlier vignettes
([`compare_groups()`](https://wep69.github.io/biblioIntegrator/reference/compare_groups.md),
[`association_residuals()`](https://wep69.github.io/biblioIntegrator/reference/association_residuals.md),
[`group_ca()`](https://wep69.github.io/biblioIntegrator/reference/group_ca.md),
[`sensitivity_analysis()`](https://wep69.github.io/biblioIntegrator/reference/sensitivity_analysis.md)
etc.) works without a Python backend. This vignette should be read as an
*extension*, not a prerequisite.

Package architecture, data model, import, harmonization, quality
filtering, descriptive analysis, comparative inference, networks,
temporal and text analysis, and scalable storage backends are covered in
vignettes `v00` through `v08`.

### Intended Audience

- Researchers who want a **second engine** to validate group
  comparisons.
- Analysts who need **one-command reports** for supervisors, reviewers,
  or grant applications.
- Team leads who want to hand a **Shiny app** to a collaborator
  unfamiliar with R scripting.
- R package developers interested in how `biblioIntegrator` integrates
  optional backends through `reticulate`.

## Learning Objectives

After reading this vignette and running the code, you will be able to:

1.  **Check Python availability** — use
    [`python_backend_status()`](https://wep69.github.io/biblioIntegrator/reference/python_backend_status.md)
    and
    [`biblium_backend_status()`](https://wep69.github.io/biblioIntegrator/reference/biblium_backend_status.md)
    to inspect the current backend configuration.
2.  **Configure a Python executable** — set the Python path with
    [`enable_python_backend()`](https://wep69.github.io/biblioIntegrator/reference/enable_python_backend.md),
    the `BIBLIOINTEGRATOR_PYTHON` environment variable, or the
    `biblioIntegrator.python` option.
3.  **Install Biblium** — create an isolated virtual environment and
    install Biblium 2.16 with
    [`install_biblium_backend()`](https://wep69.github.io/biblioIntegrator/reference/install_biblium_backend.md).
4.  **Convert data to Biblium format** — call
    [`to_biblium()`](https://wep69.github.io/biblioIntegrator/reference/to_biblium.md)
    to produce the canonical data frame that the Python bridge expects.
5.  **Run Biblium group comparison** — call
    [`biblium_compare_groups()`](https://wep69.github.io/biblioIntegrator/reference/biblium_compare_groups.md)
    and interpret the returned `biblio_group_comparison` object.
6.  **Cross-validate engines** — call
    [`validate_biblium()`](https://wep69.github.io/biblioIntegrator/reference/validate_biblium.md)
    to compare native R and Biblium outputs on the same data, groups,
    and seed.
7.  **Generate reports** — use
    [`biblio_report()`](https://wep69.github.io/biblioIntegrator/reference/biblio_report.md)
    to produce Markdown, HTML, Word, or PDF reports with corpus health,
    temporal trends, network centrality, and provenance.
8.  **Customise reports** — modify the title and inspect report
    structure to adapt the template to project-specific needs.
9.  **Launch the Shiny app** — call
    [`biblio_app()`](https://wep69.github.io/biblioIntegrator/reference/biblio_app.md)
    to hand an interactive workbench to collaborators who do not use R.
10. **Create and execute analysis plans** — define reusable plans with
    [`form_plan()`](https://wep69.github.io/biblioIntegrator/reference/form_plan.md),
    validate them with
    [`validate_plan()`](https://wep69.github.io/biblioIntegrator/reference/validate_plan.md),
    and execute them with
    [`run_plan()`](https://wep69.github.io/biblioIntegrator/reference/run_plan.md).

## Setting Up the Environment

### Working Directory and Packages

All code in this vignette assumes:

- `biblioIntegrator` is installed and loaded.
- The built-in teaching dataset
  ([`example_biblio()`](https://wep69.github.io/biblioIntegrator/reference/example_biblio.md))
  is used throughout.
- Optional packages (`reticulate`, `shiny`, `rmarkdown`) are guarded
  with [`requireNamespace()`](https://rdrr.io/r/base/ns-load.html) so
  that vignette compilation succeeds even when those packages are not
  installed.

``` r

library(biblioIntegrator)
```

### The Teaching Dataset

``` r

raw <- example_biblio()
x   <- as_biblio_project(raw, source = "v09 teaching corpus")
x
#> <biblio_project> 12 works; 7 authors; 32 work-keyword links
```

The project contains six relational tables:

``` r

cat("Works:      ", nrow(x$works),       "\n")
#> Works:       12
cat("Authors:    ", nrow(x$authors),     "\n")
#> Authors:     7
cat("Authorships:", nrow(x$authorships), "\n")
#> Authorships: 24
cat("Keywords:   ", nrow(x$keywords),    "\n")
#> Keywords:    32
cat("References: ", nrow(x$references),  "\n")
#> References:  0
cat("Provenance: ", nrow(x$provenance),  "\n")
#> Provenance:  1
```

We will return to this `biblio_project` object in every section that
follows.

## Part I — Python Integration

### Why a Second Engine?

Permutation-based group comparison is the analytical core of
`biblioIntegrator`’s comparative inference module. Running the same test
in two independent implementations — one native R, one powered by
Biblium in Python — provides a computational **cross-check**. Agreement
between engines increases confidence; disagreement signals a bug, a
version mismatch, or a subtle difference in how overlaps are handled.

Biblium exposes a public `BiblioGroup` permutation interface. When
Biblium 2.16 is configured, `biblioIntegrator` can call that interface
from R via `reticulate`, convert the result into the identical
`biblio_group_comparison` structure, and compare it element by element
with the native result.

The benefits are:

- **Reproducibility** — Running the same seed in two languages and
  obtaining the same chi-square, p-value, and Cramér’s V strengthens any
  claim.
- **Portability** — If a co-author works in Python, the Biblium output
  can be compared directly with the R output.
- **Extensibility** — Biblium may contribute additional metrics in the
  future; the bridge lets `biblioIntegrator` access them without
  rewriting R code.

### Checking Python Availability

#### `python_backend_status()`

The simplest way to inspect the current Python configuration:

``` r

st <- python_backend_status()
st
#> $available
#> [1] TRUE
#> 
#> $python
#> [1] "H:/uv/AppDataLocalUv/cache/archive-v0/MfuOKTFtveE-Nd3l_RFiM/Scripts/python.exe"
#> 
#> $version
#> [1] "2.16.0"
#> 
#> $reason
#> [1] "ok"
```

The return value is a list with four fields:

| Field       | Meaning                                          |
|:------------|:-------------------------------------------------|
| `available` | Logical: is Biblium importable right now?        |
| `python`    | Path to the Python executable that was tested    |
| `version`   | Biblium version string, or `NA` if not found     |
| `reason`    | Human-readable status (`"ok"` or an explanation) |

``` r

names(st)
#> [1] "available" "python"    "version"   "reason"
cat("Available:", st$available, "\n")
#> Available: TRUE
cat("Python:   ", st$python,    "\n")
#> Python:    H:/uv/AppDataLocalUv/cache/archive-v0/MfuOKTFtveE-Nd3l_RFiM/Scripts/python.exe
cat("Version:  ", st$version,   "\n")
#> Version:   2.16.0
cat("Reason:   ", st$reason,    "\n")
#> Reason:    ok
```

#### `biblium_backend_status()`

[`python_backend_status()`](https://wep69.github.io/biblioIntegrator/reference/python_backend_status.md)
is a backward-compatible alias for
[`biblium_backend_status()`](https://wep69.github.io/biblioIntegrator/reference/biblium_backend_status.md).
Both functions return the same list:

``` r

identical(python_backend_status(), biblium_backend_status())
#> [1] TRUE
```

Both functions accept an optional `python` argument to override the
default search:

``` r

biblium_backend_status(python = "/usr/bin/python3")
biblium_backend_status(python = Sys.which("python"))
```

#### The Lookup Order

When `python` is `NULL` the package resolves the Python executable
through a three-tier cascade:

1.  **Environment variable** — `BIBLIOINTEGRATOR_PYTHON`.
2.  **R option** — `biblioIntegrator.python` (set by
    [`enable_python_backend()`](https://wep69.github.io/biblioIntegrator/reference/enable_python_backend.md)).
3.  **System PATH** — whatever `reticulate` discovers by default.

``` r

cat("Env var: ",
    Sys.getenv("BIBLIOINTEGRATOR_PYTHON", unset = "<not set>"), "\n")
#> Env var:  H:/uv/AppDataLocalUv/cache/archive-v0/MfuOKTFtveE-Nd3l_RFiM/Scripts/python.exe
cat("Option : ",
    getOption("biblioIntegrator.python",  default = "<not set>"), "\n")
#> Option :  <not set>
```

If none of these lead to a Python with Biblium installed, `available`
will be `FALSE`.

#### Interpreting the Status

``` r

if (isTRUE(st$available)) {
  cat("Biblium is ready.  Version:", st$version, "\n")
} else {
  cat("Biblium is NOT available.\n")
  cat("Reason:", st$reason, "\n")
  cat("Next: install_biblium_backend() or",
      "enable_python_backend(path)\n")
}
#> Biblium is ready.  Version: 2.16.0
```

### Installing Biblium

#### `install_biblium_backend()`

This function creates an isolated Python virtual environment and
installs Biblium and its dependencies (`huggingface_hub`, `plotly`).

``` r

# Default: virtual env called "r-bibliointegrator",
#          Biblium version 2.16.0
install_biblium_backend()

# Specify the Biblium version explicitly
install_biblium_backend(version = "2.16.0")

# Use a custom environment name
install_biblium_backend(envname = "my-biblium-env")
```

The function returns the virtual environment Python path invisibly and
prints the [`options()`](https://rdrr.io/r/base/options.html) command
needed to register it:

``` r

# After installation, the output looks like:
# > Set options(biblioIntegrator.python = "/home/user/.virtualenvs/
#     r-bibliointegrator/bin/python") before initializing Python.
```

Copy-paste that [`options()`](https://rdrr.io/r/base/options.html) call
into your script or `.Rprofile`.

#### Choosing the `envname`

| Scenario                      | Recommended `envname`  |
|:------------------------------|:-----------------------|
| Single-user, default location | `"r-bibliointegrator"` |
| Project-specific isolation    | `"biblio-project-x"`   |
| CI / GitHub Actions           | `"r-bibliointegrator"` |

#### What Gets Installed

[`install_biblium_backend()`](https://wep69.github.io/biblioIntegrator/reference/install_biblium_backend.md)
installs three Python packages into the virtual environment:

1.  `biblium==2.16.0` — the core comparison library.
2.  `huggingface_hub` — dependency of Biblium’s model interface.
3.  `plotly` — for optional interactive figures.

#### Verifying the Installation

``` r

# After install, re-check:
st <- python_backend_status()
st$available   # should be TRUE
st$version     # should be "2.16.0"
```

### Configuring the Bridge

#### `enable_python_backend()`

If Biblium is already installed in an existing environment (system
Python, `conda`, `virtualenv`, or `pipx`), point `biblioIntegrator` to
it:

``` r

enable_python_backend("/usr/local/bin/python3")
enable_python_backend(Sys.which("python"))
enable_python_backend(
  reticulate::virtualenv_python("r-bibliointegrator")
)
```

The function sets `options(biblioIntegrator.python = ...)` and returns
the current backend status. All subsequent calls to
[`python_backend_status()`](https://wep69.github.io/biblioIntegrator/reference/python_backend_status.md),
[`biblium_compare_groups()`](https://wep69.github.io/biblioIntegrator/reference/biblium_compare_groups.md),
and
[`validate_biblium()`](https://wep69.github.io/biblioIntegrator/reference/validate_biblium.md)
will use that Python.

#### Environment Variable

In non-interactive contexts (Makefiles, CI), the environment variable
takes precedence:

``` r

Sys.setenv(BIBLIOINTEGRATOR_PYTHON = "/usr/local/bin/python3")
```

#### R Option Directly

``` r

options(biblioIntegrator.python = "/usr/local/bin/python3")
```

#### Precedence Summary

    [1] BIBLIOINTEGRATOR_PYTHON        (environment variable)
    [2] biblioIntegrator.python        (R option)
    [3] reticulate auto-discovery      (system PATH)

Higher precedence wins. If none resolves to a Python with Biblium,
`available` is `FALSE`.

### Converting Data to Biblium Format

#### `to_biblium()`

The Python bridge expects a simple data frame with canonical column
names.
[`to_biblium()`](https://wep69.github.io/biblioIntegrator/reference/to_biblium.md)
converts a `biblio_project` into that format:

``` r

bm <- to_biblium(x)
class(bm)
#> [1] "data.frame"
names(bm)
#> [1] "Title"           "Year"            "Authors"         "Author Keywords"
head(bm, 3)
#>                                    Title Year            Authors
#> 1 Silicon and salinity tolerance in rice 2018 Silva A; Pereira W
#> 2          Soil carbon under cover crops 2019 Martins B; Costa C
#> 3     Remote sensing of soybean nitrogen 2020  Lima D; Pereira W
#>                     Author Keywords
#> 1           silicon; salinity; rice
#> 2          soil carbon; cover crops
#> 3 remote sensing; soybean; nitrogen
```

The returned columns are:

| Column            | Source                         |
|:------------------|:-------------------------------|
| `Title`           | `x$works$title`                |
| `Year`            | `x$works$year`                 |
| `Authors`         | Collapsed from `x$authorships` |
| `Author Keywords` | Collapsed from `x$keywords`    |

All values are character strings with semicolon separators.

#### When to Use `to_biblium()`

- Before calling
  [`biblium_compare_groups()`](https://wep69.github.io/biblioIntegrator/reference/biblium_compare_groups.md)
  (the bridge calls it internally).
- When exporting data for a co-author who uses the Python `biblium`
  package directly.
- When comparing the R-side and Python-side raw input to rule out
  data-mismatch bugs.

#### Column Details

``` r

cat("Class of Title:         ", class(bm$Title),         "\n")
#> Class of Title:          character
cat("Class of Year:          ", class(bm$Year),          "\n")
#> Class of Year:           integer
cat("Class of Authors:       ", class(bm$Authors),       "\n")
#> Class of Authors:        character
cat("Class of Author Keywords:",
    class(bm$`Author Keywords`), "\n")
#> Class of Author Keywords: character
cat("Rows:                   ", nrow(bm),                "\n")
#> Rows:                    12
```

#### Verifying Round-Trip Fidelity

A well-designed bridge should be lossless. Check that every work
survives the round trip:

``` r

stopifnot(nrow(bm) == nrow(x$works))
stopifnot(all(bm$Year == x$works$year))
cat("Round-trip check passed: ",
    nrow(bm), "==", nrow(x$works), "\n")
#> Round-trip check passed:  12 == 12
```

### The Python Bridge Module

#### Architecture

`biblioIntegrator` ships a Python helper at
`inst/python/biblium_bridge.py`. When
[`biblium_compare_groups()`](https://wep69.github.io/biblioIntegrator/reference/biblium_compare_groups.md)
is called, the package:

1.  Loads the bridge via
    [`reticulate::import_from_path()`](https://rstudio.github.io/reticulate/reference/import.html).
2.  Passes the
    [`to_biblium()`](https://wep69.github.io/biblioIntegrator/reference/to_biblium.md)
    data frame and the group membership matrix to the bridge’s
    [`compare_groups()`](https://wep69.github.io/biblioIntegrator/reference/compare_groups.md)
    function.
3.  Receives a Python dictionary with `observed`, `expected`,
    `residuals`, `chi_square`, `p_value`, `cramers_v`, and
    `permutation_residuals_p_adj`.
4.  Wraps the result in the R `biblio_group_comparison` class.

``` r

bridge_path <- system.file("python", package = "biblioIntegrator")
cat("Bridge location:", bridge_path, "\n")
#> Bridge location: C:/Users/wep69/AppData/Local/Temp/RtmpaiVm2d/libtest/biblioIntegrator/python
dir(bridge_path)
#> [1] "biblium_bridge.py"
```

#### Error Handling

If `reticulate` is not installed,
[`biblium_backend_status()`](https://wep69.github.io/biblioIntegrator/reference/biblium_backend_status.md)
returns:

``` r

cat("If reticulate is absent:\n")
#> If reticulate is absent:
cat("  available: FALSE\n")
#>   available: FALSE
cat("  reason: 'reticulate not installed'\n")
#>   reason: 'reticulate not installed'
```

If `reticulate` is installed but Biblium is not found:

``` r

cat("If Biblium is not in the Python environment:\n")
#> If Biblium is not in the Python environment:
cat("  available: FALSE\n")
#>   available: FALSE
cat("  version:   NA\n")
#>   version:   NA
cat("  reason:    'Biblium could not be imported'\n")
#>   reason:    'Biblium could not be imported'
```

## Part II — Biblium Comparative Analysis

### The Native Engine Recap

Before comparing engines, recall how the native R engine works. The
[`compare_groups()`](https://wep69.github.io/biblioIntegrator/reference/compare_groups.md)
function from vignette `v04` computes:

- A group-entity contingency table (`observed`).
- Expected frequencies under independence.
- Standardised residuals.
- A permutation p-value for the chi-square statistic.
- Cramér’s V (with optional bootstrap confidence interval).

``` r

g <- ifelse(x$works$year < 2022, "early", "recent")
native_cmp <- compare_groups(
  x, g,
  entity      = "keyword",
  permutations = 199,
  seed         = 42
)
native_cmp
#> <biblio_group_comparison> native engine
#> Chi-square: 21.29  p: 0.855  V: 0.816
```

### `biblium_compare_groups()`

#### Calling Biblium Explicitly

``` r

bm_cmp <- biblium_compare_groups(
  x, g,
  entity       = "keyword",
  permutations = 199,
  seed         = 42
)
bm_cmp
```

If Biblium is not available, this call stops with an informative error:

``` r

tryCatch(
  biblium_compare_groups(x, g, permutations = 199, seed = 42),
  error = function(e) message("Expected: ", conditionMessage(e))
)
```

#### Return Structure

The returned `biblio_group_comparison` has the same fields as the native
output:

``` r

names(bm_cmp)
# [1] "engine"        "entity"        "groups"
# [4] "observed"      "expected"      "residuals"
# [7] "chi_square"    "p_value"       "cramers_v"
# [10] "cramers_v_ci"  "overlap"       "permutations"
# [13] "cell_p_adjusted"
```

#### The `engine` Field

The `engine` field distinguishes the two implementations:

``` r

native_cmp$engine   # "native"
bm_cmp$engine       # "biblium"
```

Both objects pass through
[`print.biblio_group_comparison()`](https://wep69.github.io/biblioIntegrator/reference/print.biblio_group_comparison.md),
[`association_residuals()`](https://wep69.github.io/biblioIntegrator/reference/association_residuals.md),
and
[`group_ca()`](https://wep69.github.io/biblioIntegrator/reference/group_ca.md).

#### Overlapping Groups with Biblium

``` r

overlapping <- cbind(
  early  = x$works$year <= 2021,
  recent = x$works$year >= 2021
)
bm_ov <- biblium_compare_groups(
  x, overlapping,
  permutations = 199,
  seed         = 42
)
bm_ov$overlap   # TRUE
```

When groups overlap, Biblium permutes complete membership rows, just as
the native engine does.

#### Author-Level Comparison

``` r

bm_author <- biblium_compare_groups(
  x, g,
  entity       = "author",
  permutations = 199,
  seed         = 42
)
head(association_residuals(bm_author), 10)
```

### `validate_biblium()`

#### Purpose

[`validate_biblium()`](https://wep69.github.io/biblioIntegrator/reference/validate_biblium.md)
runs the same comparison in both engines and returns a data frame of key
metrics side by side, plus both fitted objects. This is the recommended
way to cross-check.

``` r

vb <- validate_biblium(
  x, g,
  entity       = "keyword",
  permutations = 199,
  seed         = 42
)
vb$comparison
```

#### Interpreting the Comparison Table

        metric        native    biblium   difference
    1 chi_square   12.340000  12.340000   0.0000000
    2 p_value       0.041000   0.041000   0.0000000
    3 cramers_v     0.312000   0.312000   0.0000000

- **difference = 0** — perfect agreement after rounding.
- **difference ≈ 1e-10** — floating-point noise; harmless.
- **difference \> 0.001** — investigate; may indicate a version mismatch
  or a bug.

#### Fitted Objects

``` r

vb$native    # native biblio_group_comparison
vb$biblium   # Biblium biblio_group_comparison
```

#### Author-Level Validation

``` r

vb_author <- validate_biblium(
  x, g,
  entity       = "author",
  permutations = 199,
  seed         = 42
)
vb_author$comparison
```

#### Overlapping Groups Validation

``` r

vb_ov <- validate_biblium(
  x, cbind(
    early  = x$works$year <= 2021,
    recent = x$works$year >= 2021
  ),
  permutations = 199,
  seed         = 42
)
vb_ov$comparison
```

### Automating Engine Comparison

A practical workflow runs both engines whenever a group comparison is
performed and logs a warning when they disagree:

``` r

safe_validate <- function(x, g, tol = 0.001, ...) {
  if (!isTRUE(biblium_backend_status()$available)) {
    message("Biblium unavailable; running native only.")
    return(compare_groups(x, g, ...))
  }
  vb <- validate_biblium(x, g, ...)
  diffs <- abs(vb$comparison$difference)
  if (any(diffs > tol, na.rm = TRUE)) {
    warning("Engine disagreement detected:\n",
            paste(capture.output(print(vb$comparison)),
                  collapse = "\n"))
  }
  vb$native
}
```

### Decision Guide

| Question | Recommendation |
|:---|:---|
| Just need one engine? | [`compare_groups()`](https://wep69.github.io/biblioIntegrator/reference/compare_groups.md) (native) |
| Need a second-opinion check? | [`validate_biblium()`](https://wep69.github.io/biblioIntegrator/reference/validate_biblium.md) |
| Co-author uses Python? | [`biblium_compare_groups()`](https://wep69.github.io/biblioIntegrator/reference/biblium_compare_groups.md) |
| Must log agreement for audit trail? | [`validate_biblium()`](https://wep69.github.io/biblioIntegrator/reference/validate_biblium.md) |

## Part III — Report Generation

### `biblio_report()` Overview

[`biblio_report()`](https://wep69.github.io/biblioIntegrator/reference/biblio_report.md)
produces a self-contained document summarising a `biblio_project`. The
report includes:

- **Corpus summary** — document count, total citations, year range.
- **Data quality** — results of
  [`biblio_health()`](https://wep69.github.io/biblioIntegrator/reference/biblio_health.md).
- **Annual production** — output of
  [`temporal_growth()`](https://wep69.github.io/biblioIntegrator/reference/temporal_growth.md).
- **Leading terms** — output of
  [`term_frequency()`](https://wep69.github.io/biblioIntegrator/reference/term_frequency.md).
- **Coauthorship centrality** — output of
  [`network_centrality()`](https://wep69.github.io/biblioIntegrator/reference/network_centrality.md).
- **Optional backends** — output of
  [`backend_status()`](https://wep69.github.io/biblioIntegrator/reference/backend_status.md).
- **Provenance** — output of
  [`audit_biblio()`](https://wep69.github.io/biblioIntegrator/reference/audit_biblio.md).
- **Interpretation notes** — standard caveats.

### Markdown Reports

#### Basic Usage

``` r

f_md <- tempfile(fileext = ".md")
biblio_report(x, f_md)
#> [1] "C:/Users/wep69/AppData/Local/Temp/RtmpK2KHgj/file70c04c867c4c.md"
file.exists(f_md)
#> [1] TRUE
cat("Path:", normalizePath(f_md, winslash = "/"), "\n")
#> Path: C:/Users/wep69/AppData/Local/Temp/RtmpK2KHgj/file70c04c867c4c.md
```

#### Inspecting the Output

``` r

lines <- readLines(f_md, warn = FALSE)
cat("Total lines:", length(lines), "\n")
#> Total lines: 84
cat("First 30 lines:\n")
#> First 30 lines:
writeLines(lines[seq_len(min(30, length(lines)))])
#> # Bibliometric Analysis Report
#> 
#> Generated: 2026-09-22 03:20:10.309072
#> 
#> ## Corpus summary
#> Documents: **12**  
#> Total citations: **309**  
#> Years: **2017-2025**
#> 
#> ## Data quality
#> | check | n |
#> | --- | --- |
#> | missing_title | 0 |
#> | missing_year | 0 |
#> | missing_doi | 0 |
#> | duplicate_doi | 0 |
#> | duplicate_title_year | 0 |
#> | negative_citations | 0 |
#> 
#> ## Annual production
#> | year | documents | citations | growth_pct |
#> | --- | --- | --- | --- |
#> | 2017 | 1 | 55 | NA |
#> | 2018 | 1 | 42 | 0 |
#> | 2019 | 1 | 35 | 0 |
#> | 2020 | 2 | 54 | 100 |
#> | 2021 | 1 | 31 | -50 |
#> | 2022 | 2 | 39 | 100 |
#> | 2023 | 1 | 18 | -50 |
#> | 2024 | 2 | 26 | 100 |
```

#### Structure of the Markdown File

    # <title>

    Generated: <timestamp>

    ## Corpus summary
    Documents: **<n>**
    Total citations: **<total>**
    Years: **<first>-<last>**

    ## Data quality
    | ... |
    | ... |

    ## Annual production
    | year | documents | citations | cumulative |
    | ...  | ...       | ...       | ...        |

    ## Leading terms
    | keyword | n |
    | ...     | ... |

    ## Coauthorship centrality
    | name | degree | betweenness | ... |
    | ...  | ...    | ...         | ... |

    ## Optional backends
    | ... |

    ## Provenance
    | ... |

    ## Interpretation notes
    ...

#### Custom Title

``` r

f_title <- tempfile(fileext = ".md")
biblio_report(
  x, f_title,
  title = "Agronomic Bibliometric Map — Nutrition Studies"
)
#> [1] "C:/Users/wep69/AppData/Local/Temp/RtmpK2KHgj/file70c065e42a5a.md"
readLines(f_title, n = 3, warn = FALSE)
#> [1] "# Agronomic Bibliometric Map — Nutrition Studies"
#> [2] ""                                                
#> [3] "Generated: 2026-09-22 03:20:10.451634"
```

### HTML Reports

HTML reports require `rmarkdown`. The function creates a temporary
`.Rmd` wrapper and renders it:

``` r

f_html <- tempfile(fileext = ".html")
biblio_report(x, f_html, format = "html")
file.exists(f_html)
```

If `rmarkdown` is not installed,
[`biblio_report()`](https://wep69.github.io/biblioIntegrator/reference/biblio_report.md)
will stop with an error when `format` is not `"markdown"`:

``` r

# The internal check is:
if (!requireNamespace("rmarkdown", quietly = TRUE))
  stop("Install 'rmarkdown' for rendered reports.", call. = FALSE)
```

### Word Reports (DOCX)

``` r

f_docx <- tempfile(fileext = ".docx")
biblio_report(x, f_docx, format = "docx")
file.exists(f_docx)
```

Word reports use
[`rmarkdown::render()`](https://pkgs.rstudio.com/rmarkdown/reference/render.html)
with the `word_document` output format. The resulting `.docx` file can
be opened in Microsoft Word or LibreOffice Writer.

### PDF Reports

``` r

f_pdf <- tempfile(fileext = ".pdf")
biblio_report(x, f_pdf, format = "pdf")
file.exists(f_pdf)
```

PDF reports require a LaTeX distribution. On systems where LaTeX is not
available, use the HTML or DOCX format.

### Report Format Summary

| Format     | Extension | Requires            | Use Case                     |
|:-----------|:----------|:--------------------|:-----------------------------|
| `markdown` | `.md`     | (none)              | Quick check, version control |
| `html`     | `.html`   | `rmarkdown`         | Sharing, presenting          |
| `docx`     | `.docx`   | `rmarkdown`         | Word-based workflows         |
| `pdf`      | `.pdf`    | `rmarkdown` + LaTeX | Formal submission, archival  |

### Report from Any Data Frame

[`biblio_report()`](https://wep69.github.io/biblioIntegrator/reference/biblio_report.md)
accepts a plain data frame if it matches the schema of
[`example_biblio()`](https://wep69.github.io/biblioIntegrator/reference/example_biblio.md):

``` r

f_df <- tempfile(fileext = ".md")
biblio_report(example_biblio(), f_df,
              title = "Report from raw data frame")
#> [1] "C:/Users/wep69/AppData/Local/Temp/RtmpK2KHgj/file70c0516846f3.md"
file.exists(f_df)
#> [1] TRUE
```

### Report Provenance

The Provenance section of every report is generated by
`audit_biblio(x)`, which lists every transformation that has been
logged:

``` r

audit_biblio(x)
#>                    timestamp         operation                          details
#> 1 2026-09-22 03:20:01.984475 as_biblio_project source=v09 teaching corpus; n=12
```

This is what makes reports **auditable**: a reviewer can trace every
number back to a named transformation step.

### Report in a Scripted Workflow

``` r

# Typical scripted pipeline:
x2 <- as_biblio_project(example_biblio(), source = "grant review")
f_report <- file.path(tempdir(), "grant-review-report.md")
biblio_report(x2, f_report, title = "Grant literature mapping")
#> [1] "C:/Users/wep69/AppData/Local/Temp/RtmpK2KHgj/grant-review-report.md"
cat("Report saved to:", f_report, "\n")
#> Report saved to: C:\Users\wep69\AppData\Local\Temp\RtmpK2KHgj/grant-review-report.md
```

### Multi-Format Export

``` r

# Generate all four formats from the same project:
formats <- c("markdown", "html", "docx", "pdf")
for (fmt in formats) {
  f <- tempfile(fileext = paste0(".", substr(fmt, 1, 3)))
  if (fmt == "markdown") f <- tempfile(fileext = ".md")
  tryCatch({
    biblio_report(x, f, format = fmt, title = paste("Report -", fmt))
    cat(fmt, ": ", f, "\n")
  }, error = function(e)
    message(fmt, " failed: ", conditionMessage(e)))
}
```

## Part IV — Shiny Application

### `biblio_app()` Overview

[`biblio_app()`](https://wep69.github.io/biblioIntegrator/reference/biblio_app.md)
launches a full Shiny application with five tabs:

1.  **Data** — load a CSV/TSV/JSON file or the teaching demo.
2.  **Explore** — annual production plot and top keywords table.
3.  **Networks** — choose network type and minimum weight, inspect
    centrality.
4.  **Compare** — backend status and a note directing to
    [`compare_groups()`](https://wep69.github.io/biblioIntegrator/reference/compare_groups.md)
    for formal inference.
5.  **Report** — download an HTML report; inspect provenance.

``` r

# Launch with teaching data pre-loaded:
biblio_app(x)

# Launch empty (user loads data via file input):
biblio_app()

# Launch with any biblio_project:
biblio_app(as_biblio_project(example_biblio()))
```

### Loading the App

#### Prerequisites

``` r

if (requireNamespace("shiny", quietly = TRUE)) {
  cat("Shiny is available.\n")
} else {
  cat("Install 'shiny' to use biblio_app().\n")
}
```

#### Basic Launch

``` r

# In an interactive R session:
shiny::runApp(biblio_app())
```

#### Passing Data Directly

``` r

shiny::runApp(biblio_app(x))
```

### Tab 1: Data

The Data tab provides:

- A **file input** to upload a CSV, TSV, or JSON file.
- An **“Load agronomy demo”** button that loads
  [`example_biblio()`](https://wep69.github.io/biblioIntegrator/reference/example_biblio.md).
- A **text output** showing project dimensions (the
  `print.biblio_project` method).
- A **table output** showing
  [`biblio_health()`](https://wep69.github.io/biblioIntegrator/reference/biblio_health.md)
  results.

``` r

# Conceptual server logic for the Data tab:
# rv <- shiny::reactiveVal(NULL)
# shiny::observeEvent(input$demo, {
#   rv(as_biblio_project(example_biblio()))
# })
# shiny::observeEvent(input$file, {
#   shiny::req(input$file)
#   rv(biblio_import(input$file$datapath))
# })
# output$summary <- shiny::renderPrint({
#   shiny::req(rv())
#   print(rv())
#   print(describe_biblio(rv()))
# })
# output$health <- shiny::renderTable({
#   shiny::req(rv())
#   biblio_health(rv())
# })
```

#### Acceptable Input Formats

The
[`biblio_import()`](https://wep69.github.io/biblioIntegrator/reference/biblio_import.md)
function called by the Shiny server supports:

- CSV with bibliographic columns.
- TSV with bibliographic columns.
- JSON arrays of bibliographic records.

#### The `biblio_import()` Path Inside the App

``` r

# The server calls:
# rv(biblio_import(input$file$datapath))
# which returns a biblio_project ready for downstream analysis.
```

### Tab 2: Explore

The Explore tab provides:

- An **annual production plot** built with base R
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html).
- A **top terms table** showing the 15 most frequent keywords.

``` r

# Conceptual server logic:
# output$annual <- shiny::renderPlot({
#   shiny::req(rv())
#   a <- temporal_growth(rv())
#   plot(a$year, a$documents,
#        type = "b",
#        xlab = "Year",
#        ylab = "Documents")
# })
# output$terms <- shiny::renderTable({
#   shiny::req(rv())
#   head(term_frequency(rv()), 15)
# })
```

#### Annual Production Plot

``` r

a <- temporal_growth(x)
head(a)
#>   year documents citations growth_pct
#> 1 2017         1        55         NA
#> 2 2018         1        42          0
#> 3 2019         1        35          0
#> 4 2020         2        54        100
#> 5 2021         1        31        -50
#> 6 2022         2        39        100
```

#### Leading Terms

``` r

head(term_frequency(x), 15)
#>             term n
#> 1           soil 4
#> 2        silicon 3
#> 3          cover 2
#> 4          crops 2
#> 5          maize 2
#> 6       nitrogen 2
#> 7       salinity 2
#> 8        soybean 2
#> 9    aggregation 1
#> 10        carbon 1
#> 11 climate-smart 1
#> 12          crop 1
#> 13       drought 1
#> 14    efficiency 1
#> 15      learning 1
```

### Tab 3: Networks

The Networks tab provides:

- A **select input** to choose between `"coauthor"` and `"keyword"`
  networks.
- A **numeric input** for minimum edge weight.
- A **centrality table** built from
  [`network_centrality()`](https://wep69.github.io/biblioIntegrator/reference/network_centrality.md).

``` r

# Conceptual server logic:
# output$centrality <- shiny::renderTable({
#   shiny::req(rv())
#   g <- bibliographic_network(rv(),
#                              input$ntype,
#                              min_weight = input$minw)
#   head(network_centrality(g), 20)
# })
```

#### Coauthorship Centrality

``` r

g_ca <- bibliographic_network(x, "coauthor")
cent <- network_centrality(g_ca)
head(cent, 15)
#>                node degree strength betweenness  pagerank
#> A000008c4 A000008c4      3        3  0.03333333 0.1290688
#> A00000905 A00000905      2        3  0.12222222 0.1267212
#> A00000f4d A00000f4d      4        4  0.12222222 0.1648773
#> A00000f73 A00000f73      3        4  0.27777778 0.1612960
#> A00000621 A00000621      3        3  0.05555556 0.1273099
#> A000008ad A000008ad      2        4  0.20000000 0.1617880
#> A0000043f A0000043f      3        3  0.12222222 0.1289388
```

#### Keyword Network Centrality

``` r

g_kw <- bibliographic_network(x, "keyword")
head(network_centrality(g_kw), 15)
#>                            node degree strength betweenness   pagerank
#> cover crops         cover crops      3        3  0.01581028 0.05408732
#> soil carbon         soil carbon      1        1  0.00000000 0.02157474
#> silicon                 silicon      6        6  0.18181818 0.08640333
#> maize                     maize      4        4  0.16600791 0.05643655
#> nitrogen               nitrogen      4        4  0.14229249 0.05692476
#> drought                 drought      2        2  0.00000000 0.03048324
#> climate-smart     climate-smart      2        2  0.00000000 0.03568058
#> soil                       soil      4        4  0.02371542 0.06713569
#> remote sensing   remote sensing      2        2  0.00000000 0.03097144
#> soybean                 soybean      4        4  0.08695652 0.05941145
#> uav                         uav      2        2  0.00000000 0.03282597
#> salinity               salinity      3        3  0.04743083 0.04956778
#> soil microbiome soil microbiome      1        1  0.00000000 0.04166667
#> aggregation         aggregation      2        2  0.00000000 0.03584108
#> meta-analysis     meta-analysis      2        2  0.00000000 0.03215734
```

#### Adjusting Minimum Weight

Higher minimum weights prune weak edges:

``` r

g_filtered <- bibliographic_network(x, "coauthor",
                                     min_weight = 2)
cat("Vertices (min=1):", igraph::vcount(g_ca),       "\n")
#> Vertices (min=1): 7
cat("Edges    (min=1):", igraph::ecount(g_ca),       "\n")
#> Edges    (min=1): 10
cat("Vertices (min=2):", igraph::vcount(g_filtered),  "\n")
#> Vertices (min=2): 3
cat("Edges    (min=2):", igraph::ecount(g_filtered),  "\n")
#> Edges    (min=2): 2
```

### Tab 4: Compare

The Compare tab displays:

- A `print(backend_status())` call showing the availability of optional
  backends.
- A text note directing users to
  [`compare_groups()`](https://wep69.github.io/biblioIntegrator/reference/compare_groups.md)
  for formal permutation inference.

The Shiny app deliberately does **not** run permutation inference
automatically: that is a CPU-intensive operation best controlled by a
script.

``` r

# Conceptual server logic:
# output$backends <- shiny::renderPrint({
#   backend_status()
# })
```

#### Backend Status

``` r

backend_status()
#>                     backend available
#> biblionetwork biblionetwork      TRUE
#> arrow                 arrow      TRUE
#> duckdb               duckdb      TRUE
#> DBI                     DBI      TRUE
#> bibliometrix   bibliometrix      TRUE
#> openalexR         openalexR      TRUE
```

#### Why Comparison Is Not Automated in the App

Permutation inference can require hundreds to thousands of random
shuffles. In a reactive Shiny context this may block the interface. For
formal comparison, use
[`compare_groups()`](https://wep69.github.io/biblioIntegrator/reference/compare_groups.md)
or
[`validate_biblium()`](https://wep69.github.io/biblioIntegrator/reference/validate_biblium.md)
in a script and import the result.

### Tab 5: Report

The Report tab provides:

- A **download button** that generates an HTML report via
  [`biblio_report()`](https://wep69.github.io/biblioIntegrator/reference/biblio_report.md).
- A **provenance table** built from
  [`audit_biblio()`](https://wep69.github.io/biblioIntegrator/reference/audit_biblio.md).

``` r

# Conceptual server logic:
# output$report <- shiny::downloadHandler(
#   filename = function() "biblio-report.html",
#   content  = function(file) {
#     shiny::req(rv())
#     biblio_report(rv(), file, "html")
#   }
# )
# output$provenance <- shiny::renderTable({
#   shiny::req(rv())
#   audit_biblio(rv())
# })
```

#### What the Downloaded Report Contains

The HTML report is the same document produced by
`biblio_report(x, format = "html")` — the full structure described in
Section [Part III](#sec-reports).

#### Customising the Shiny App

[`biblio_app()`](https://wep69.github.io/biblioIntegrator/reference/biblio_app.md)
returns a `shinyApp` object. You can modify the UI or server before
launching:

``` r

app <- biblio_app(x)
# app$ui     — the UI object
# app$server — the server function
# Modify as needed, then:
# shiny::runApp(app)
```

#### Embedding the App in a Package

If you are building a companion package and want a one-button launch:

``` r

launch_bibliometrics <- function(data = NULL) {
  if (!requireNamespace("shiny", quietly = TRUE))
    stop("Install 'shiny' first.", call. = FALSE)
  shiny::runApp(biblio_app(data))
}
```

### Shiny App Architecture Summary

    UI (navbarPage)
    ├── Data tab
    │   ├── fileInput
    │   ├── actionButton("demo")
    │   ├── verbatimTextOutput("summary")
    │   └── tableOutput("health")
    ├── Explore tab
    │   ├── plotOutput("annual")
    │   └── tableOutput("terms")
    ├── Networks tab
    │   ├── selectInput("ntype")
    │   ├── numericInput("minw")
    │   └── tableOutput("centrality")
    ├── Compare tab
    │   ├── p() note
    │   └── verbatimTextOutput("backends")
    └── Report tab
        ├── downloadButton("report")
        └── tableOutput("provenance")

    Server
    ├── reactiveVal(rv): the biblio_project
    ├── observeEvent: demo → example_biblio()
    ├── observeEvent: file → biblio_import()
    ├── renderPrint, renderPlot, renderTable, renderTable
    ├── renderPrint (backends)
    └── downloadHandler → biblio_report(format = "html")

## Part V — Analysis Plans

### Why Analysis Plans?

When a bibliometric study is repeated over multiple corpora — for
example, one dataset per grant application, one per country, or one per
time window — it is useful to define the analytical steps once and
execute them identically on every dataset. Analysis plans serve this
purpose.

An analysis plan is a **declarative specification** of:

- The analysis blocks to run.
- The network type.
- The group definition.
- The report format.
- The reproducibility seed.

Plans are created by
[`form_plan()`](https://wep69.github.io/biblioIntegrator/reference/form_plan.md),
validated by
[`validate_plan()`](https://wep69.github.io/biblioIntegrator/reference/validate_plan.md),
and executed by
[`run_plan()`](https://wep69.github.io/biblioIntegrator/reference/run_plan.md).

### `form_plan()`

#### Basic Usage

``` r

plan <- form_plan()
plan
#> $source
#> NULL
#> 
#> $analyses
#> [1] "health"      "descriptive" "temporal"    "network"     "text"       
#> 
#> $network
#> [1] "coauthor"
#> 
#> $group
#> NULL
#> 
#> $report
#> [1] "markdown"
#> 
#> $seed
#> [1] 123
#> 
#> attr(,"class")
#> [1] "biblio_plan"
class(plan)
#> [1] "biblio_plan"
```

The default plan requests all five analysis blocks:

``` r

plan$analyses
#> [1] "health"      "descriptive" "temporal"    "network"     "text"
```

#### Customising the Plan

``` r

plan_net <- form_plan(
  analyses = c("health", "descriptive", "network"),
  network  = "keyword",
  report   = "html",
  seed     = 42
)
plan_net
#> $source
#> NULL
#> 
#> $analyses
#> [1] "health"      "descriptive" "network"    
#> 
#> $network
#> [1] "keyword"
#> 
#> $group
#> NULL
#> 
#> $report
#> [1] "html"
#> 
#> $seed
#> [1] 42
#> 
#> attr(,"class")
#> [1] "biblio_plan"
```

#### All Arguments

| Argument | Default | Description |
|:---|:---|:---|
| `source` | `NULL` | File path or label |
| `analyses` | `c("health","descriptive", | Analysis blocks | | | "temporal","network","text") | | |`network`|`“coauthor”`| Network type | |`group`|`NULL`| Group definition | |`report`|`“markdown”`| Report format | |`seed`|`123\` | Reproducibility seed |

#### Plan with Group Comparison

``` r

g <- ifelse(x$works$year < 2022, "early", "recent")
plan_grp <- form_plan(
  analyses = c("health", "descriptive", "groups"),
  group    = g,
  seed     = 42
)
plan_grp
#> $source
#> NULL
#> 
#> $analyses
#> [1] "health"      "descriptive" "groups"     
#> 
#> $network
#> [1] "coauthor"
#> 
#> $group
#>  [1] "early"  "early"  "early"  "early"  "recent" "recent" "early"  "early" 
#>  [9] "recent" "recent" "recent" "recent"
#> 
#> $report
#> [1] "markdown"
#> 
#> $seed
#> [1] 42
#> 
#> attr(,"class")
#> [1] "biblio_plan"
```

#### Plan with Network Type

``` r

plan_kw <- form_plan(network = "keyword")
plan_kw$network
#> [1] "keyword"
```

### `validate_plan()`

#### Basic Validation

``` r

validate_plan(plan)
```

Validation checks:

1.  The object must be a `biblio_plan`.
2.  Every element of `analyses` must be one of the allowed values.
3.  The `network` must be `"coauthor"`, `"keyword"`, or `"citation"`.

#### Allowed Analysis Blocks

``` r

allowed <- c("health", "descriptive", "temporal",
             "network", "text", "groups")
cat("Allowed blocks:", paste(allowed, collapse = ", "), "\n")
#> Allowed blocks: health, descriptive, temporal, network, text, groups
```

#### Invalid Plans

``` r

tryCatch(
  validate_plan(form_plan(analyses = c("health", "unknown_block"))),
  error = function(e) message("Expected: ", conditionMessage(e))
)
```

#### Plan as a Validation Gate

In a function that accepts user-specified analysis blocks, validation
catches typos early:

``` r

safe_create_plan <- function(analyses, ...) {
  p <- form_plan(analyses = analyses, ...)
  validate_plan(p)
  p
}

p <- safe_create_plan(c("health", "descriptive"))
class(p)
#> [1] "biblio_plan"
```

### `run_plan()`

#### Basic Usage

``` r

res <- run_plan(plan, x)
names(res)
#> [1] "project"     "health"      "descriptive" "temporal"    "network"    
#> [6] "centrality"  "terms"
```

The result is a named list. Each element corresponds to one analysis
block:

``` r

sapply(res, class)
#>          project           health      descriptive         temporal 
#> "biblio_project"     "data.frame"           "list"     "data.frame" 
#>          network       centrality            terms 
#>         "igraph"     "data.frame"     "data.frame"
```

#### What Each Block Produces

| Block         | Output Class / Type             |
|:--------------|:--------------------------------|
| `project`     | `biblio_project`                |
| `health`      | `data.frame`                    |
| `descriptive` | list (`describe_biblio`)        |
| `temporal`    | `data.frame` (`temporal_growth` |
| `network`     | `igraph`                        |
| `centrality`  | `data.frame`                    |
| `terms`       | `data.frame`                    |
| `groups`      | `biblio_group_comparison`       |

#### Health Block

``` r

res$health
#>                  check n
#> 1        missing_title 0
#> 2         missing_year 0
#> 3          missing_doi 0
#> 4        duplicate_doi 0
#> 5 duplicate_title_year 0
#> 6   negative_citations 0
```

#### Descriptive Block

``` r

res$descriptive
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

#### Temporal Block

``` r

head(res$temporal)
#>   year documents citations growth_pct
#> 1 2017         1        55         NA
#> 2 2018         1        42          0
#> 3 2019         1        35          0
#> 4 2020         2        54        100
#> 5 2021         1        31        -50
#> 6 2022         2        39        100
```

#### Network Block

``` r

cat("Vertices:", igraph::vcount(res$network), "\n")
#> Vertices: 7
cat("Edges:   ", igraph::ecount(res$network), "\n")
#> Edges:    10
head(res$centrality, 10)
#>                node degree strength betweenness  pagerank
#> A000008c4 A000008c4      3        3  0.03333333 0.1290688
#> A00000905 A00000905      2        3  0.12222222 0.1267212
#> A00000f4d A00000f4d      4        4  0.12222222 0.1648773
#> A00000f73 A00000f73      3        4  0.27777778 0.1612960
#> A00000621 A00000621      3        3  0.05555556 0.1273099
#> A000008ad A000008ad      2        4  0.20000000 0.1617880
#> A0000043f A0000043f      3        3  0.12222222 0.1289388
```

#### Terms Block

``` r

head(res$terms, 15)
#>             term n
#> 1           soil 4
#> 2        silicon 3
#> 3          cover 2
#> 4          crops 2
#> 5          maize 2
#> 6       nitrogen 2
#> 7       salinity 2
#> 8        soybean 2
#> 9    aggregation 1
#> 10        carbon 1
#> 11 climate-smart 1
#> 12          crop 1
#> 13       drought 1
#> 14    efficiency 1
#> 15      learning 1
```

#### Group Comparison Block

``` r

plan_g <- form_plan(
  analyses = c("groups"),
  group    = ifelse(x$works$year < 2022, "early", "recent"),
  seed     = 42
)
res_g <- run_plan(plan_g, x)
res_g$groups
#> <biblio_group_comparison> native engine
#> Chi-square: 21.29  p: 0.867  V: 0.816
```

#### Running from a Data Frame

[`run_plan()`](https://wep69.github.io/biblioIntegrator/reference/run_plan.md)
accepts a raw data frame; it calls
[`as_biblio_project()`](https://wep69.github.io/biblioIntegrator/reference/as_biblio_project.md)
internally:

``` r

res_raw <- run_plan(form_plan(analyses = "health"),
                    example_biblio())
head(res_raw$health)
#>                  check n
#> 1        missing_title 0
#> 2         missing_year 0
#> 3          missing_doi 0
#> 4        duplicate_doi 0
#> 5 duplicate_title_year 0
#> 6   negative_citations 0
```

#### Reproducibility

Plans are self-contained: all random seeds are captured, so the same
plan run on the same data produces identical results.

``` r

res1 <- run_plan(plan, x)
res2 <- run_plan(plan, x)
identical(names(res1), names(res2))
# TRUE — structure is identical
```

### Plan Composition

#### Combining Plans

You can create separate plans for each phase of a study and run them
sequentially:

``` r

p_qc   <- form_plan(analyses = "health")
p_desc <- form_plan(analyses = c("descriptive", "temporal"))
p_net  <- form_plan(analyses = c("network", "text"), network = "keyword")

res_qc   <- run_plan(p_qc,   x)
res_desc <- run_plan(p_desc, x)
res_net  <- run_plan(p_net,  x)

cat("QC blocks:      ", names(res_qc),   "\n")
#> QC blocks:       project health
cat("Desc blocks:    ", names(res_desc), "\n")
#> Desc blocks:     project descriptive temporal
cat("Network blocks: ", names(res_net),  "\n")
#> Network blocks:  project network centrality terms
```

#### Batch Execution Over Multiple Corpora

``` r

# Suppose you have multiple files:
corpus_files <- c("agronomy.csv",
                   "nutrition.csv",
                   "soil_science.csv")

batch_results <- lapply(corpus_files, function(f) {
  raw_f <- read.csv(f)
  run_plan(form_plan(analyses = c("health", "descriptive")))
})
```

### Plans and Reports Together

Plans and reports are designed to work together seamlessly:

``` r

plan <- form_plan(
  analyses = c("health", "descriptive", "network", "text"),
  network  = "coauthor",
  report   = "html",
  seed     = 42
)
# Note: plan$report is used by downstream reporting logic,
#       but run_plan() itself returns analysis objects.
res <- run_plan(plan, x)

# Generate the report separately:
f_out <- file.path(tempdir(), "plan-report.md")
biblio_report(x, f_out,
              format = plan$report,
              title  = "Plan-driven report")
cat("Report:", f_out, "\n")
```

## Common Mistakes

### Mistake 1: Not Checking Python Availability First

**Wrong pattern:**

``` r

biblium_compare_groups(x, g,
                       permutations = 199,
                       seed = 42)
# Error: Biblium 2.16 backend is unavailable or not importable.
```

**Correct pattern:**

``` r

st <- python_backend_status()
if (isTRUE(st$available)) {
  biblium_compare_groups(x, g,
                         permutations = 199,
                         seed = 42)
} else {
  message("Biblium not available; using native engine.")
  compare_groups(x, g,
                 permutations = 199,
                 seed = 42,
                 engine = "native")
}
```

### Mistake 2: Ignoring Biblium Version Requirements

The package requires **Biblium 2.16**. Installing an older or newer
version may yield different results or fail.

``` r

st <- biblium_backend_status()
if (!is.na(st$version) && st$version != "2.16.0") {
  warning("Expected Biblium 2.16.0; found ", st$version)
}
```

### Mistake 3: Not Validating Cross-Engine Results

Running
[`biblium_compare_groups()`](https://wep69.github.io/biblioIntegrator/reference/biblium_compare_groups.md)
alone does **not** verify that the two engines agree. Use
[`validate_biblium()`](https://wep69.github.io/biblioIntegrator/reference/validate_biblium.md):

``` r

# Wrong: only one engine
# bm <- biblium_compare_groups(x, g, permutations = 199)

# Right: cross-validate
vb <- validate_biblium(x, g,
                       entity       = "keyword",
                       permutations = 199,
                       seed         = 1)
vb$comparison
```

### Mistake 4: Over-Relying on Shiny for Reproducible Analysis

The Shiny app is for exploration and collaboration, **not** for
reproducible pipelines. A reproducible workflow requires scripts.

**Wrong pattern:**

    1. Open biblio_app()
    2. Click "Load agronomy demo"
    3. Browse tabs
    4. Download report
    5. Paste report section into manuscript

**Correct pattern:**

``` r

# Write a script that is re-runnable:
library(biblioIntegrator)
x <- as_biblio_project(example_biblio(), source = "thesis review")
g <- ifelse(x$works$year < 2022, "early", "recent")

# Analysis
cmp <- compare_groups(x, g, permutations = 999, seed = 42)
ca  <- group_ca(cmp)

# Report
f <- file.path(tempdir(), "thesis-review.md")
biblio_report(x, f, title = "Thesis literature review")
#> [1] "C:/Users/wep69/AppData/Local/Temp/RtmpK2KHgj/thesis-review.md"
```

### Mistake 5: Forgetting That `validate_biblium()` Requires Both Engines

If only one engine is available,
[`validate_biblium()`](https://wep69.github.io/biblioIntegrator/reference/validate_biblium.md)
will error. Guard the call:

``` r

if (isTRUE(biblium_backend_status()$available)) {
  vb <- validate_biblium(x, g,
                         permutations = 199,
                         seed = 1)
} else {
  message("Biblium unavailable; cannot cross-validate.")
  native <- compare_groups(x, g,
                           permutations = 199,
                           seed = 1)
}
```

### Mistake 6: Skipping Plan Validation

[`run_plan()`](https://wep69.github.io/biblioIntegrator/reference/run_plan.md)
calls
[`validate_plan()`](https://wep69.github.io/biblioIntegrator/reference/validate_plan.md)
internally, but if you build plans programmatically it is good practice
to validate early:

``` r

# Wrong:
# plan <- form_plan(analyses = c("health", "typo"))

# Right:
plan <- form_plan(analyses = c("health", "descriptive"))
validate_plan(plan)
run_plan(plan, x)
```

### Mistake 7: Using `biblio_report()` Without Version Control

Reports overwrite files silently. In a scripted pipeline, always
uniquely name output files:

``` r

# Wrong:
# biblio_report(x, "report.md")
# biblio_report(x2, "report.md")  # overwrites!

# Right:
date_tag <- format(Sys.Date(), "%Y-%m-%d")
f <- paste0("report-", date_tag, ".md")
biblio_report(x, f, title = paste("Report", date_tag))
```

### Mistake 8: Misinterpreting the Shiny Compare Tab

The Compare tab shows **backend availability only** — it does not run
permutation inference. Do not report those numbers as analytical
results.

``` r

# What the tab shows:
backend_status()

# What it does NOT show:
# compare_groups(x, g, permutations = 999)
# Use scripts for formal inference.
```

## Working Example: End-to-End Pipeline

This section assembles all major functions into a single reproducible
script.

``` r

# =========================================================
#  End-to-End biblioIntegrator Pipeline
# =========================================================

# 0. Setup
library(biblioIntegrator)

# 1. Import and project creation
raw_data <- example_biblio()
proj     <- as_biblio_project(raw_data,
                               source = "end-to-end example")

# 2. Quality diagnostics
cat("=== Corpus Health ===\n")
#> === Corpus Health ===
print(biblio_health(proj))
#>                  check n
#> 1        missing_title 0
#> 2         missing_year 0
#> 3          missing_doi 0
#> 4        duplicate_doi 0
#> 5 duplicate_title_year 0
#> 6   negative_citations 0

# 3. Descriptive analysis
cat("\n=== Descriptive ===\n")
#> 
#> === Descriptive ===
print(describe_biblio(proj))
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

# 4. Temporal growth
cat("\n=== Temporal Growth ===\n")
#> 
#> === Temporal Growth ===
gr <- temporal_growth(proj)
print(gr)
#>   year documents citations growth_pct
#> 1 2017         1        55         NA
#> 2 2018         1        42          0
#> 3 2019         1        35          0
#> 4 2020         2        54        100
#> 5 2021         1        31        -50
#> 6 2022         2        39        100
#> 7 2023         1        18        -50
#> 8 2024         2        26        100
#> 9 2025         1         9        -50

# 5. Leading terms
cat("\n=== Leading Terms ===\n")
#> 
#> === Leading Terms ===
print(head(term_frequency(proj), 10))
#>           term n
#> 1         soil 4
#> 2      silicon 3
#> 3        cover 2
#> 4        crops 2
#> 5        maize 2
#> 6     nitrogen 2
#> 7     salinity 2
#> 8      soybean 2
#> 9  aggregation 1
#> 10      carbon 1

# 6. Group comparison (native)
cat("\n=== Group Comparison (native) ===\n")
#> 
#> === Group Comparison (native) ===
g <- ifelse(proj$works$year < 2022, "early", "recent")
cmp <- compare_groups(proj, g,
                      permutations = 199,
                      seed         = 42)
print(cmp)
#> <biblio_group_comparison> native engine
#> Chi-square: 21.29  p: 0.855  V: 0.816
cat("\nTop residuals:\n")
#> 
#> Top residuals:
print(head(association_residuals(cmp, min_abs = 0.5), 10))
#>                   group           entity   residual observed expected
#> 1   factor(groups)early      aggregation -0.9543668        0  0.46875
#> 2  factor(groups)recent      aggregation  0.9543668        1  0.53125
#> 3   factor(groups)early    climate-smart -0.9543668        0  0.46875
#> 4  factor(groups)recent    climate-smart  0.9543668        1  0.53125
#> 7   factor(groups)early          drought  1.0816157        1  0.46875
#> 8  factor(groups)recent          drought -1.0816157        0  0.53125
#> 9   factor(groups)early       efficiency -0.9543668        0  0.46875
#> 10 factor(groups)recent       efficiency  0.9543668        1  0.53125
#> 11  factor(groups)early machine learning -0.9543668        0  0.46875
#> 12 factor(groups)recent machine learning  0.9543668        1  0.53125

# 7. Network analysis
cat("\n=== Coauthorship Network ===\n")
#> 
#> === Coauthorship Network ===
net <- bibliographic_network(proj, "coauthor")
cat("Vertices:", igraph::vcount(net),
    " Edges:", igraph::ecount(net), "\n")
#> Vertices: 7  Edges: 10
print(head(network_centrality(net), 8))
#>                node degree strength betweenness  pagerank
#> A000008c4 A000008c4      3        3  0.03333333 0.1290688
#> A00000905 A00000905      2        3  0.12222222 0.1267212
#> A00000f4d A00000f4d      4        4  0.12222222 0.1648773
#> A00000f73 A00000f73      3        4  0.27777778 0.1612960
#> A00000621 A00000621      3        3  0.05555556 0.1273099
#> A000008ad A000008ad      2        4  0.20000000 0.1617880
#> A0000043f A0000043f      3        3  0.12222222 0.1289388

# 8. Backend status
cat("\n=== Backend Status ===\n")
#> 
#> === Backend Status ===
print(backend_status())
#>                     backend available
#> biblionetwork biblionetwork      TRUE
#> arrow                 arrow      TRUE
#> duckdb               duckdb      TRUE
#> DBI                     DBI      TRUE
#> bibliometrix   bibliometrix      TRUE
#> openalexR         openalexR      TRUE

# 9. Python backend check
cat("\n=== Python/Biblium Status ===\n")
#> 
#> === Python/Biblium Status ===
print(python_backend_status())
#> $available
#> [1] TRUE
#> 
#> $python
#> [1] "H:/uv/AppDataLocalUv/cache/archive-v0/MfuOKTFtveE-Nd3l_RFiM/Scripts/python.exe"
#> 
#> $version
#> [1] "2.16.0"
#> 
#> $reason
#> [1] "ok"

# 10. Report generation
f_report <- file.path(tempdir(), "end-to-end-report.md")
biblio_report(proj, f_report,
              title = "End-to-End Bibliometric Analysis")
#> [1] "C:/Users/wep69/AppData/Local/Temp/RtmpK2KHgj/end-to-end-report.md"
cat("\nReport saved to:", f_report, "\n")
#> 
#> Report saved to: C:\Users\wep69\AppData\Local\Temp\RtmpK2KHgj/end-to-end-report.md

# 11. Plan-based execution
plan <- form_plan(
  analyses = c("health", "descriptive", "network", "text"),
  network  = "coauthor",
  report   = "markdown",
  seed     = 42
)
plan_res <- run_plan(plan, proj)
cat("\nPlan results:", paste(names(plan_res), collapse = ", "),
    "\n")
#> 
#> Plan results: project, health, descriptive, network, centrality, terms
```

## Function Reference Summary

### Python Backend Functions

| Function | Description |
|:---|:---|
| [`python_backend_status()`](https://wep69.github.io/biblioIntegrator/reference/python_backend_status.md) | Check Python/Biblium availability |
| [`biblium_backend_status()`](https://wep69.github.io/biblioIntegrator/reference/biblium_backend_status.md) | Canonical name (same as above) |
| [`enable_python_backend()`](https://wep69.github.io/biblioIntegrator/reference/enable_python_backend.md) | Set Python executable path |
| [`install_biblium_backend()`](https://wep69.github.io/biblioIntegrator/reference/install_biblium_backend.md) | Create virtual env, install Biblium |
| [`to_biblium()`](https://wep69.github.io/biblioIntegrator/reference/to_biblium.md) | Convert project to Biblium data frame |
| [`biblium_compare_groups()`](https://wep69.github.io/biblioIntegrator/reference/biblium_compare_groups.md) | Biblium group comparison |
| [`validate_biblium()`](https://wep69.github.io/biblioIntegrator/reference/validate_biblium.md) | Cross-validate native vs. Biblium |

### Report Function

| Function | Description |
|:---|:---|
| [`biblio_report()`](https://wep69.github.io/biblioIntegrator/reference/biblio_report.md) | Generate MD/HTML/DOCX/PDF report |

### Shiny Function

| Function | Description |
|:---|:---|
| [`biblio_app()`](https://wep69.github.io/biblioIntegrator/reference/biblio_app.md) | Launch interactive Shiny workbench |

### Plan Functions

| Function | Description |
|:---|:---|
| [`form_plan()`](https://wep69.github.io/biblioIntegrator/reference/form_plan.md) | Create an analysis plan |
| [`validate_plan()`](https://wep69.github.io/biblioIntegrator/reference/validate_plan.md) | Validate plan structure |
| [`run_plan()`](https://wep69.github.io/biblioIntegrator/reference/run_plan.md) | Execute a plan on data |

## References

### Primary Package References

- Pereira, W.E., Pereira Martinez, M.H. (2026). *biblioIntegrator:
  Harmonized, Comparative and Network-Based Bibliometric Analysis*. R
  package version 0.3.0.

- Umek, L. (2026). Biblium: a Python library for comparative
  bibliometric analysis. *Scientometrics*, 131(5), 3359–3377.
  <doi:%5B10.1007/s11192-026-05636-8>\](<https://doi.org/10.1007/s11192-026-05636-8>)

### Key Methodological References

- Aria, M. & Cuccurullo, C. (2017). bibliometrix: An R-tool for
  comprehensive science mapping analysis. *Journal of Informetrics*,
  11(4), 959–975.
  <doi:%5B10.1016/j.joi.2017.08.007>\](<https://doi.org/10.1016/j.joi.2017.08.007>)

### Web Resources

- Biblium on PyPI — <https://pypi.org/project/biblium/>
- biblioIntegrator GitHub — <https://github.com/wep69/biblioIntegrator>
- reticulate documentation — <https://rstudio.github.io/reticulate/>
- Shiny tutorial — <https://shiny.posit.co/r/articles/>
- rmarkdown: The Definitive Guide —
  <https://bookdown.org/yihui/rmarkdown/>

### Session Info

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
#> [1] knitr_1.52             biblioIntegrator_0.3.0
#> 
#> loaded via a namespace (and not attached):
#>   [1] tidyselect_1.2.1       viridisLite_0.4.3      dplyr_1.2.1           
#>   [4] farver_2.1.2           arrow_25.0.1           S7_0.2.2              
#>   [7] fastmap_1.2.0          duckdb_1.5.5           janeaustenr_1.0.0     
#>  [10] promises_1.5.0         XML_3.99-0.24          digest_0.6.39         
#>  [13] mime_0.13              lifecycle_1.0.5        qpdf_1.4.1            
#>  [16] tokenizers_0.3.0       magrittr_2.0.5         compiler_4.6.0        
#>  [19] rlang_1.3.0            sass_0.4.10            tools_4.6.0           
#>  [22] igraph_2.3.3           tidytext_0.4.3         yaml_2.3.12           
#>  [25] data.table_1.18.6.1    askpass_1.2.1          htmlwidgets_1.6.4     
#>  [28] bit_4.6.0              reticulate_1.47.0      plyr_1.8.9            
#>  [31] RColorBrewer_1.1-3     ca_0.72                withr_3.0.3           
#>  [34] purrr_1.2.2            pubmedR_1.0.2          contentanalysis_1.1.1 
#>  [37] desc_1.4.3             grid_4.6.0             xtable_1.8-8          
#>  [40] ggplot2_4.0.3          scales_1.4.0           dichromat_2.0-1       
#>  [43] cli_3.6.6              rmarkdown_2.32         ragg_1.5.2            
#>  [46] generics_0.1.4         stringdist_0.9.17      otel_0.2.0            
#>  [49] httr_1.4.9             tzdb_0.5.0             visNetwork_2.1.4      
#>  [52] readxl_1.5.0.1         DBI_1.3.0              cachem_1.1.0          
#>  [55] stringr_1.6.0          rscopus_0.9.0          parallel_4.6.0        
#>  [58] assertthat_0.2.1       cellranger_1.1.0       base64enc_0.1-6       
#>  [61] vctrs_0.7.3            Matrix_1.7-6           jsonlite_2.0.0        
#>  [64] hms_1.1.4              bit64_4.8.6            ggrepel_0.9.8         
#>  [67] systemfonts_1.3.2      biblionetwork_0.1.0    plotly_4.12.1         
#>  [70] tidyr_1.3.2            jquerylib_0.1.4        glue_1.8.1            
#>  [73] pkgdown_2.2.1          stringi_1.8.9          gtable_0.3.6          
#>  [76] later_1.4.8            shinycssloaders_1.1.0  tibble_3.3.1          
#>  [79] pillar_1.11.1          htmltools_0.5.9        bibliometrixData_0.3.0
#>  [82] R6_2.6.1               httr2_1.3.0            textshaping_1.0.5     
#>  [85] Rdpack_2.6.6           shiny_1.14.0           evaluate_1.0.5        
#>  [88] lattice_0.23-1         readr_2.2.0            rentrez_1.2.4         
#>  [91] rbibutils_2.4.1        png_0.1-9              SnowballC_0.7.1       
#>  [94] openxlsx_4.2.9         httpuv_1.6.17          openalexR_3.1.0       
#>  [97] bslib_0.12.0           zip_3.0.2              Rcpp_1.1.2            
#> [100] bibliometrix_5.5.0     xfun_0.61              dimensionsR_0.0.3     
#> [103] fs_2.1.0               forcats_1.0.1          pdftools_3.9.1        
#> [106] pkgconfig_2.0.3
```

------------------------------------------------------------------------

*This vignette is part of the biblioIntegrator documentation (vignettes
`v00` to `v09`). For the foundational tutorial, see
`v07-foundations-to-advanced-tutorial.Rmd`. For scalable backends
(Arrow, DuckDB), see `v08-scalable-backends.Rmd`.*
