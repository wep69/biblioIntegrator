# Bibliographic Networks and Stability

## 1. Why this vignette exists

### 1.1 Networks reveal collaboration and knowledge structure

Bibliometric counts — how many papers someone published, how often a
journal is cited — describe *volume* but not *structure*. A researcher
who co-authors with thirty different teams plays a different role in the
scientific ecosystem than one who publishes exclusively within a single
group, even if both have the same *h*-index. Similarly, two topics may
appear equally frequent in a corpus but differ markedly in how tightly
they cluster and how many bridge articles connect them.

Network analysis gives us language and tools for this structural view.
By representing authors, documents, or keywords as **nodes** and their
relationships as **edges**, we move from counting to mapping.

biblioIntegrator lets you construct three families of bibliographic
networks — coauthorship, bibliographic coupling, and co-citation —
compute standard centrality measures, detect communities with several
algorithms, and assess how stable those results are when the underlying
corpus is perturbed. Everything runs through a single relational project
object (`biblio_project`), so network analysis plugs naturally into the
import, audit, and descriptive workflows covered in earlier vignettes.

### 1.2 Network construction is distinct from network interpretation

A common pitfall is to treat the output of a network algorithm as if it
were a finding. The Louvain community structure of a coauthorship graph
tells you how a particular algorithm partitions a particular graph at a
particular threshold; it is not an immutable fact about collaboration in
a field. Different algorithms, different weight thresholds, and even
different random seeds can yield different partitions.

This vignette therefore separates **construction** (building the graph),
**analysis** (centrality, communities), and **validation** (stability
resampling) into clear, repeatable steps. When you report a network
result, you should always be able to say: *here is the graph, here is
the method, and here is the evidence that the result is robust*.

### 1.3 Stability assessment is often neglected

Published bibliometric network studies rarely report whether their
centrality rankings or community assignments survive subsampling. A hub
that appears in only 60 out of 100 bootstrap replicates may still be
important, but the reader deserves to know. The
[`network_stability()`](https://wep69.github.io/biblioIntegrator/reference/network_stability.md)
function in biblioIntegrator exists to fill this gap: it repeatedly
subsamples the corpus, rebuilds the network from scratch each time, and
reports the mean rank and rank variability for every node.

------------------------------------------------------------------------

## 2. Learning objectives

After working through this vignette you will be able to:

1.  Explain the conceptual difference between coauthorship, coupling,
    and cocitation networks, and choose the right one for a given
    research question.
2.  Use
    [`bibliographic_network()`](https://wep69.github.io/biblioIntegrator/reference/bibliographic_network.md)
    to build any of the three network types from a `biblio_project`.
3.  Select between the native engine and the **biblionetwork** engine,
    understanding when each is appropriate.
4.  Compute degree, strength, betweenness, closeness, and PageRank
    centrality with
    [`network_centrality()`](https://wep69.github.io/biblioIntegrator/reference/network_centrality.md)
    and interpret the results.
5.  Detect communities using Louvain, Walktrap, and label propagation
    via
    [`network_communities()`](https://wep69.github.io/biblioIntegrator/reference/network_communities.md).
6.  Compare community assignments across algorithms to check structural
    robustness.
7.  Assess network stability with
    [`network_stability()`](https://wep69.github.io/biblioIntegrator/reference/network_stability.md)
    and interpret the mean-rank and standard-deviation output.
8.  Apply edge-weight thresholds (`min_weight`) and understand their
    effect on graph density and interpretation.
9.  Visualize networks with both **igraph** (static) and **visNetwork**
    (interactive) backends.
10. Recognise and avoid the most common mistakes in bibliographic
    network analysis.

------------------------------------------------------------------------

## 3. Network types

### 3.1 Coauthorship networks

In a **coauthorship network** each node is an author and each edge
connects two authors who have co-authored at least one document. The
edge weight typically counts the number of shared publications.

Coauthorship networks answer questions like:

- Who are the most connected researchers in a field?
- Are there distinct collaboration communities?
- Who acts as a bridge between otherwise separate groups?

Because coauthorship is explicit in the bibliographic record (every
paper lists its authors), data quality is usually high. The main
challenge is **name disambiguation** — the same person may appear under
variant spellings. biblioIntegrator uses deterministic author IDs
derived from the display name, which works well for small-to-medium
corpora but may need external disambiguation for large-scale studies.

### 3.2 Bibliographic coupling networks

Two documents are **coupled** when they share at least one cited
reference. In a coupling network, documents (or their authors) are nodes
and shared references are the basis of edges. Strong coupling suggests
that two papers draw from a similar intellectual foundation.

Coupling networks are forward-looking: they map the current state of a
field based on cumulative reference overlap. They are useful for:

- Identifying emerging clusters of related research.
- Mapping the intellectual neighbourhood of a focal paper.
- Detecting convergence or divergence across sub-disciplines.

biblioIntegrator constructs coupling networks from the `references`
table in the project. When that table is empty (which is common if the
import source did not include reference lists), coupling networks cannot
be constructed and the function will return an empty graph.

### 3.3 Co-citation networks

Two documents are **co-cited** when they both appear in the reference
list of a later paper. Like coupling, co-citation links documents
through shared citing contexts, but the direction of inference is
reversed: coupling looks *backward* from documents to their references,
while co-citation looks *forward* from references to their joint
appearances in subsequent literature.

Co-citation networks are especially useful for:

- Mapping the intellectual core — the foundational works of a field.
- Identifying classic and emerging streams of thought.
- Studying how knowledge is recombined over time.

Constructing co-citation networks requires a non-trivial citation graph
(i.e., works that cite other works in the corpus). In small corpora, the
graph may be too sparse for meaningful analysis.

### 3.4 When to use each type

| Research question | Network type |
|----|----|
| Who collaborates with whom? | Coauthorship |
| Which papers share an intellectual base? | Bibliographic coupling |
| Which works are jointly foundational? | Co-citation |
| How are authors clustered into schools? | Coauthorship |
| What are the emerging research fronts? | Coupling |
| What are the canonical works? | Co-citation |
| Need edge weights from counting? | Coauthorship (native or biblionetwork) |

A practical workflow often uses all three. Coauthorship maps the social
structure; coupling and cocitation map the intellectual structure. When
the three tell consistent stories, confidence increases; when they
diverge, the discrepancy itself is informative.

------------------------------------------------------------------------

## 4. The native engine

### 4.1 How networks are constructed

biblioIntegrator’s native engine lives entirely inside the package — it
requires only **igraph** (which is an Import, not a Suggest). The
construction follows three steps:

1.  **Pair enumeration.** For each grouping unit (a work, a keyword
    list), all unordered pairs of its members are enumerated using
    [`utils::combn()`](https://rdrr.io/r/utils/combn.html).
2.  **Edge counting.** Each enumerated pair contributes a weight of 1
    (full counting). The pair table is then aggregated by
    `stats::aggregate(weight ~ from + to, ..., sum)` so that repeated
    co-occurrences across multiple works accumulate.
3.  **Graph assembly.** The aggregated edge list is passed to
    [`igraph::graph_from_data_frame()`](https://r.igraph.org/reference/graph_from_data_frame.html).
    Coauthorship and keyword networks are undirected; citation networks
    are directed.

This approach is simple, transparent, and exact — it does not involve
probabilistic approximation or external data.

### 4.2 Edge weight calculation

By default, every co-occurrence adds 1 to the edge weight. This is
called **full counting** in the bibliometric literature.

For coauthorship, bibliometrix-style frameworks sometimes offer
**fractional counting** (each author on a *k*-author paper receives
1/*k* of a link) or **fractional counting refined** (which further
adjusts for the number of papers). biblioIntegrator’s native engine uses
full counting; the refinements are available when the optional
**biblionetwork** engine is selected (see Section 5).

The `min_weight` parameter filters weak edges *after* aggregation.
Setting `min_weight = 2` keeps only pairs that have co-authored at least
two papers together. This is the single most powerful lever for
controlling graph density and interpretability.

### 4.3 Handling isolated nodes

If a work has only one author, or a keyword appears alone in a work, no
edges are generated for that node. In the final igraph object such nodes
may appear as isolates (degree 0). Isolates are not removed
automatically because:

- They can carry information (a lone author may be early-career).
- Removing them silently would change node counts reported downstream.

You can always filter isolates yourself:

``` r

library(igraph)
g <- bibliographic_network(x, "coauthor")
g_no_isolates <- delete.vertices(g, degree(g) == 0)
```

------------------------------------------------------------------------

## 5. The biblionetwork engine

### 5.1 When to use it

The **biblionetwork** package (Goutsmedt, Claveau & Truc, 2021) provides
high-performance network construction using `data.table` under the hood.
For large corpora (thousands of works, tens of thousands of author
pairs), it can be dramatically faster than the native engine.

biblioIntegrator wraps
[`biblionetwork::coauth_network()`](https://agoutsmedt.github.io/biblionetwork//reference/coauth_network.html)
for coauthorship networks. The engine is automatically selected when:

- `engine = "auto"` (the default),
- `type = "coauthor"`, *and*
- the `biblionetwork` package is installed.

If `biblionetwork` is not installed, the function falls back to the
native engine with a message. You never need to install optional
packages to get a working result.

### 5.2 Performance comparison

The timing difference matters mainly for corpora with many thousands of
works. For the small example corpus shipped with biblioIntegrator (12
works, ~7 authors), the difference is negligible. For a corpus of 5,000
works with an average of 4 authors each, the native engine must
enumerate ~6 pair-combinations per work and aggregate, while
biblionetwork uses optimised data.table joins.

A rough guideline:

| Corpus size  | Native engine | biblionetwork engine |
|--------------|---------------|----------------------|
| \< 500 works | Fast enough   | Marginal gain        |
| 500 – 5,000  | Acceptable    | Noticeable speedup   |
| \> 5,000     | May slow down | Recommended          |

You can check whether biblionetwork is available without building a
network:

``` r

requireNamespace("biblionetwork", quietly = TRUE)
```

### 5.3 Coupling angle method

The biblionetwork engine exposes a **counting** parameter that controls
how co-authorship weights are computed:

- `"full_counting"` – every co-authorship adds 1 (same as native).
- `"fractional_counting"` – each co-authorship adds 1 / (number of
  authors on that paper).
- `"fractional_counting_refined"` – further adjusts for the number of
  co-authored documents per author pair.

Fractional counting reduces the inflation of weights for large
multi-author teams and is often considered more analytically fair. The
native engine always uses full counting.

``` r

# Fractional counting (requires biblionetwork)
if (requireNamespace("biblionetwork", quietly = TRUE)) {
  g_frac <- bibliographic_network(
    x, "coauthor",
    engine   = "biblionetwork",
    counting = "fractional_counting"
  )
}
```

------------------------------------------------------------------------

## 6. Step-by-step workflow

### 6.1 Load example data

biblioIntegrator ships a small agronomy-oriented corpus that we use
throughout the vignettes. It contains 12 works spanning 2017–2025, with
7 distinct authors, 12 keyword sets, and several sources.

``` r

library(biblioIntegrator)

# Load the built-in example corpus and convert to a project
raw <- example_biblio()
x   <- as_biblio_project(raw, source = "network-vignette")

# Quick diagnostics
x
#> <biblio_project> 12 works; 7 authors; 32 work-keyword links
biblio_health(x)
#>                  check n
#> 1        missing_title 0
#> 2         missing_year 0
#> 3          missing_doi 0
#> 4        duplicate_doi 0
#> 5 duplicate_title_year 0
#> 6   negative_citations 0
describe_biblio(x)
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

The
[`biblio_health()`](https://wep69.github.io/biblioIntegrator/reference/biblio_health.md)
output tells us there are no missing titles, years, or DOIs — a clean
corpus, as expected for the example data.

### 6.2 Build a coauthorship network

``` r

# Build coauthorship network using the native engine (always available)
g_coauthor <- bibliographic_network(x, "coauthor")
g_coauthor
#> IGRAPH 79d32c6 UNW- 7 10 -- 
#> + attr: name (v/c), weight (e/n)
#> + edges from 79d32c6 (vertex names):
#>  [1] A000008c4--A00000621 A00000905--A000008ad A000008c4--A00000f4d
#>  [4] A00000f4d--A00000f73 A00000f4d--A0000043f A000008c4--A0000043f
#>  [7] A00000f73--A000008ad A00000f4d--A00000621 A00000905--A0000043f
#> [10] A00000f73--A00000621

# Examine the engine used
attr(g_coauthor, "engine")
#> [1] "biblionetwork"

# Basic graph properties
igraph::vcount(g_coauthor)  # number of authors
#> [1] 7
igraph::ecount(g_coauthor)  # number of collaboration edges
#> [1] 10
igraph::is.directed(g_coauthor)
#> Warning: `is.directed()` was deprecated in igraph 2.0.0.
#> ℹ Please use `is_directed()` instead.
#> This warning is displayed once per session.
#> Call `lifecycle::last_lifecycle_warnings()` to see where this warning was
#> generated.
#> [1] FALSE
```

Each node is an author ID; each edge connects two authors who have
co-authored at least one work. The edge weight counts the number of
shared publications.

### 6.3 Inspect the internal structure

The `biblio_project` contains several data frames that feed into network
construction. Understanding these tables helps diagnose issues when a
network comes out unexpectedly.

``` r

# Works table
nrow(x$works)
#> [1] 12
names(x$works)
#> [1] "work_id"        "title"          "year"           "doi"           
#> [5] "source"         "cited_by_count" "abstract"

# Authorships table (many-to-many: work <-> author)
nrow(x$authorships)
#> [1] 24
names(x$authorships)
#> [1] "work_id"   "author_id"

# Keywords table (many-to-many: work <-> keyword)
nrow(x$keywords)
#> [1] 32
names(x$keywords)
#> [1] "work_id" "keyword"

# References table (many-to-many: citing -> cited)
nrow(x$references)
#> [1] 0
names(x$references)
#> [1] "citing_id" "cited_id"
```

For coauthorship networks, the key table is `authorships`. Each row
links a `work_id` to an `author_id`. The native engine groups
authorships by work and enumerates all pairwise combinations.

For keyword networks, the `keywords` table plays an analogous role.

For citation networks, the `references` table is needed. If it is empty
(as in the example corpus), citation networks cannot be built. This is a
common scenario: many bibliographic databases do not export reference
lists, or you may need to enrich your data from external APIs (e.g.,
OpenAlex via
[`fetch_openalex()`](https://wep69.github.io/biblioIntegrator/reference/fetch_openalex.md)
or OpenCitations via
[`fetch_opencitations()`](https://wep69.github.io/biblioIntegrator/reference/fetch_opencitations.md)).

### 6.4 Expand the graph with author names

The author IDs in the graph are hashes (e.g., `A1a2b3c4`). For readable
output we merge with the author display names:

``` r

# Map author IDs to display names
auth_map <- setNames(x$authors$display_name, x$authors$author_id)
igraph::V(g_coauthor)$label <- auth_map[igraph::V(g_coauthor)$name]

# Verify
head(data.frame(
  id    = igraph::V(g_coauthor)$name,
  label = igraph::V(g_coauthor)$label
))
#>          id     label
#> 1 A000008c4   Costa C
#> 2 A00000905   Gomez E
#> 3 A00000f4d Martins B
#> 4 A00000f73 Pereira W
#> 5 A00000621    Lima D
#> 6 A000008ad   Silva A
```

### 6.4 Build a keyword co-occurrence network

``` r

g_keyword <- bibliographic_network(x, "keyword", min_weight = 1)
g_keyword
#> IGRAPH 7a0c88f UNW- 24 28 -- 
#> + attr: name (v/c), weight (e/n)
#> + edges from 7a0c88f (vertex names):
#>  [1] cover crops    --aggregation    cover crops    --soil carbon   
#>  [3] silicon        --drought        maize          --efficiency    
#>  [5] nitrogen       --efficiency     maize          --drought       
#>  [7] maize          --nitrogen       silicon        --maize         
#>  [9] climate-smart  --management     soil           --management    
#> [11] silicon        --meta-analysis  nitrogen       --remote sensing
#> [13] nitrogen       --soybean        soybean        --phenotyping   
#> [15] uav            --phenotyping    salinity       --rice          
#> + ... omitted several edges

# Edge data
head(igraph::as_data_frame(g_keyword, what = "edges"))
#>          from          to weight
#> 1 cover crops aggregation      1
#> 2 cover crops soil carbon      1
#> 3     silicon     drought      1
#> 4       maize  efficiency      1
#> 5    nitrogen  efficiency      1
#> 6       maize     drought      1
```

Keywords that appear together in the same document form an edge. Setting
`min_weight = 1` keeps all edges; increasing it filters weak
associations.

### 6.5 Build a citation network (directed)

``` r

# Citation networks require non-empty reference data.
# The example corpus has no references, so this would return an empty graph.
g_citation <- bibliographic_network(x, "citation")
g_citation
igraph::vcount(g_citation)
igraph::ecount(g_citation)
```

If your imported corpus includes a reference list, the citation network
will contain directed edges from citing to cited works. Citation edges
point **from** the citing work **to** the cited work, following the
convention that information flows from older to newer literature.

### 6.6 Enriching data for citation networks

If the `references` table is empty, you can populate it from external
APIs. biblioIntegrator provides wrappers for OpenAlex and OpenCitations:

``` r

# Attempt to fetch citation data from OpenAlex
if (requireNamespace("openalexR", quietly = TRUE)) {
  x_enriched <- fetch_openalex(x)
  nrow(x_enriched$references)
}
```

Once the references table is populated, citation networks become
available:

``` r

# After enrichment
if (nrow(x_enriched$references) > 0) {
  g_cite <- bibliographic_network(x_enriched, "citation")
  igraph::vcount(g_cite)
  igraph::ecount(g_cite)
  igraph::is.directed(g_cite)
}
```

### 6.7 Building multiple networks from the same project

A single `biblio_project` can feed all three network types without
modification. This is one of the advantages of the relational
architecture: the same authorships table generates both the coauthorship
graph and (via the keyword table) the keyword co-occurrence graph.

``` r

# All three network types from the same project
g_co  <- bibliographic_network(x, "coauthor")
g_kw  <- bibliographic_network(x, "keyword")
g_cit <- tryCatch(bibliographic_network(x, "citation"),
                   error = function(e) NULL)

summary_df <- data.frame(
  type     = c("coauthor", "keyword", "citation"),
  vertices = c(igraph::vcount(g_co), igraph::vcount(g_kw),
               if (!is.null(g_cit)) igraph::vcount(g_cit) else 0),
  edges    = c(igraph::ecount(g_co), igraph::ecount(g_kw),
               if (!is.null(g_cit)) igraph::ecount(g_cit) else 0),
  directed = c(igraph::is.directed(g_co), igraph::is.directed(g_kw),
               if (!is.null(g_cit)) igraph::is.directed(g_cit) else FALSE)
)
summary_df
#>       type vertices edges directed
#> 1 coauthor        7    10    FALSE
#> 2  keyword       24    28    FALSE
#> 3 citation        0     0    FALSE
```

------------------------------------------------------------------------

## 7. Centrality analysis

### 7.1 Computing centrality measures

[`network_centrality()`](https://wep69.github.io/biblioIntegrator/reference/network_centrality.md)
returns a data frame with four columns:

- **degree** – number of neighbours (unweighted).
- **strength** – sum of edge weights (the weighted analogue of degree).
- **betweenness** – normalised betweenness centrality, computed with
  inverse weights so that stronger edges are treated as shorter paths.
- **pagerank** – Google PageRank score, incorporating edge weights.

``` r

cent <- network_centrality(g_coauthor)
cent
#>                node degree strength betweenness  pagerank
#> A000008c4 A000008c4      3        3  0.03333333 0.1290688
#> A00000905 A00000905      2        3  0.12222222 0.1267212
#> A00000f4d A00000f4d      4        4  0.12222222 0.1648773
#> A00000f73 A00000f73      3        4  0.27777778 0.1612960
#> A00000621 A00000621      3        3  0.05555556 0.1273099
#> A000008ad A000008ad      2        4  0.20000000 0.1617880
#> A0000043f A0000043f      3        3  0.12222222 0.1289388
```

### 7.2 Interpreting degree and strength

Degree counts distinct collaborators; strength counts total co-authored
works. A researcher with degree 4 and strength 8 has four co-authors and
an average of two co-authored papers per pair. When degree equals
strength, every collaboration involved exactly one joint paper.

``` r

# Degree vs. strength
cent[, c("node", "degree", "strength")]
#>                node degree strength
#> A000008c4 A000008c4      3        3
#> A00000905 A00000905      2        3
#> A00000f4d A00000f4d      4        4
#> A00000f73 A00000f73      3        4
#> A00000621 A00000621      3        3
#> A000008ad A000008ad      2        4
#> A0000043f A0000043f      3        3
```

### 7.3 Betweenness centrality

Betweenness measures how often a node lies on the shortest path between
other pairs of nodes. High-betweenness authors are **bridges** — they
connect communities that would otherwise be disconnected (or only weakly
connected).

Because the example corpus is small (12 works, 7 authors), betweenness
values may be zero for many nodes. In larger corpora, betweenness is one
of the most informative centrality measures for identifying key
intermediaries.

``` r

# Authors with non-zero betweenness
subset(cent, betweenness > 0)
#>                node degree strength betweenness  pagerank
#> A000008c4 A000008c4      3        3  0.03333333 0.1290688
#> A00000905 A00000905      2        3  0.12222222 0.1267212
#> A00000f4d A00000f4d      4        4  0.12222222 0.1648773
#> A00000f73 A00000f73      3        4  0.27777778 0.1612960
#> A00000621 A00000621      3        3  0.05555556 0.1273099
#> A000008ad A000008ad      2        4  0.20000000 0.1617880
#> A0000043f A0000043f      3        3  0.12222222 0.1289388
```

### 7.4 PageRank

PageRank generalises degree centrality by recursively crediting nodes
that are connected to other high-scoring nodes. It is useful for
identifying authors who are embedded in dense collaboration clusters
(even if they are not directly highly connected to many others).

``` r

# Top authors by PageRank
cent[order(-cent$pagerank), ]
#>                node degree strength betweenness  pagerank
#> A00000f4d A00000f4d      4        4  0.12222222 0.1648773
#> A000008ad A000008ad      2        4  0.20000000 0.1617880
#> A00000f73 A00000f73      3        4  0.27777778 0.1612960
#> A000008c4 A000008c4      3        3  0.03333333 0.1290688
#> A0000043f A0000043f      3        3  0.12222222 0.1289388
#> A00000621 A00000621      3        3  0.05555556 0.1273099
#> A00000905 A00000905      2        3  0.12222222 0.1267212
```

### 7.5 Combining centrality measures

No single measure captures “importance” completely. A practical approach
is to inspect all four and look for convergences:

``` r

# Rank authors on each centrality measure
cent_rank <- data.frame(
  node         = cent$node,
  degree_rank  = rank(-cent$degree),
  strength_rank = rank(-cent$strength),
  betw_rank    = rank(-cent$betweenness),
  pr_rank      = rank(-cent$pagerank)
)
cent_rank
#>        node degree_rank strength_rank betw_rank pr_rank
#> 1 A000008c4         3.5           5.5         7       4
#> 2 A00000905         6.5           5.5         4       7
#> 3 A00000f4d         1.0           2.0         4       1
#> 4 A00000f73         3.5           2.0         1       3
#> 5 A00000621         3.5           5.5         6       6
#> 6 A000008ad         6.5           2.0         2       2
#> 7 A0000043f         3.5           5.5         4       5
```

Authors who rank near the top on multiple measures are robustly central.
Authors who rank high on only one measure may be specialised — e.g.,
high betweenness but moderate degree suggests a brokerage role.

### 7.6 Centrality for keyword networks

The same function works on any undirected network:

``` r

cent_kw <- network_centrality(g_keyword)
head(cent_kw, 8)
#>                        node degree strength betweenness   pagerank
#> cover crops     cover crops      3        3  0.01581028 0.05408732
#> soil carbon     soil carbon      1        1  0.00000000 0.02157474
#> silicon             silicon      6        6  0.18181818 0.08640333
#> maize                 maize      4        4  0.16600791 0.05643655
#> nitrogen           nitrogen      4        4  0.14229249 0.05692476
#> drought             drought      2        2  0.00000000 0.03048324
#> climate-smart climate-smart      2        2  0.00000000 0.03568058
#> soil                   soil      4        4  0.02371542 0.06713569
```

High-degree keywords are those that co-occur with many other topics.
High-betweenness keywords are bridging terms that connect thematic
clusters.

------------------------------------------------------------------------

## 8. Community detection

### 8.1 Why communities matter

Community detection partitions the network into groups of nodes that are
more densely connected internally than with the rest of the graph. In a
coauthorship network, communities often correspond to research groups,
departments, or disciplinary sub-fields. In a keyword network, they
correspond to thematic clusters.

### 8.2 The Louvain algorithm

Louvain maximises modularity — a measure of the quality of a partition —
by iteratively moving nodes between communities. It is fast, widely
used, and works well for networks with clear modular structure.

``` r

comm_louvain <- network_communities(g_coauthor, method = "louvain")
comm_louvain
#>        node community
#> 1 A000008c4         1
#> 2 A00000905         2
#> 3 A00000f4d         1
#> 4 A00000f73         2
#> 5 A00000621         1
#> 6 A000008ad         2
#> 7 A0000043f         1
```

### 8.3 The Walktrap algorithm

Walktrap simulates short random walks on the graph and merges nodes that
are frequently visited in the same walks. It tends to produce slightly
more fine-grained communities than Louvain and is less sensitive to
resolution limits.

``` r

comm_walktrap <- network_communities(g_coauthor, method = "walktrap")
comm_walktrap
#>        node community
#> 1 A000008c4         2
#> 2 A00000905         1
#> 3 A00000f4d         2
#> 4 A00000f73         1
#> 5 A00000621         2
#> 6 A000008ad         1
#> 7 A0000043f         2
```

### 8.4 Label propagation

Label propagation is the fastest of the three and works by iteratively
assigning each node the most common label among its neighbours. It is
non-deterministic — results can vary across runs — so it is best used as
a complement to the other two methods.

``` r

comm_label <- network_communities(g_coauthor, method = "label_prop")
comm_label
#>        node community
#> 1 A000008c4         1
#> 2 A00000905         2
#> 3 A00000f4d         1
#> 4 A00000f73         1
#> 5 A00000621         1
#> 6 A000008ad         2
#> 7 A0000043f         1
```

### 8.5 Comparing community assignments

When all three algorithms agree on the partition, we have strong
evidence for community structure. When they disagree, the network may
not have a clean modular decomposition, or the resolution parameter
(implicit in Louvain, explicit in others) may need tuning.

``` r

# Side-by-side comparison
comm_compare <- data.frame(
  node      = comm_louvain$node,
  louvain   = comm_louvain$community,
  walktrap  = comm_walktrap$community,
  label_prop = comm_label$community
)
comm_compare
#>        node louvain walktrap label_prop
#> 1 A000008c4       1        2          1
#> 2 A00000905       2        1          2
#> 3 A00000f4d       1        2          1
#> 4 A00000f73       2        1          1
#> 5 A00000621       1        2          1
#> 6 A000008ad       2        1          2
#> 7 A0000043f       1        2          1
```

### 8.6 Community-level summaries

Once communities are assigned, you can aggregate characteristics:

``` r

# Average citations per community (Louvain)
comm_cit <- merge(comm_louvain, x$authorships, by.x = "node", by.y = "author_id")
comm_cit <- merge(comm_cit, x$works[, c("work_id", "cited_by_count")], by = "work_id")
aggregate(cited_by_count ~ community, data = comm_cit, FUN = mean)
#>   community cited_by_count
#> 1         1       21.92308
#> 2         2       30.27273
```

### 8.7 Community detection for keyword networks

``` r

comm_kw <- network_communities(g_keyword, method = "louvain")
comm_kw
#>                node community
#> 1       cover crops         1
#> 2       soil carbon         1
#> 3           silicon         2
#> 4             maize         3
#> 5          nitrogen         3
#> 6           drought         3
#> 7     climate-smart         1
#> 8              soil         1
#> 9    remote sensing         4
#> 10          soybean         4
#> 11              uav         4
#> 12         salinity         2
#> 13  soil microbiome         5
#> 14      aggregation         1
#> 15    meta-analysis         2
#> 16 machine learning         6
#> 17       efficiency         3
#> 18       management         1
#> 19      phenotyping         4
#> 20             rice         2
#> 21         rotation         5
#> 22           stress         2
#> 23            wheat         2
#> 24            yield         6

# Number of communities
length(unique(comm_kw$community))
#> [1] 6
```

------------------------------------------------------------------------

## 9. Network stability

### 9.1 Why stability matters

A central node could be an artefact of one particular paper. A community
boundary could shift if one or two papers are removed. Stability
analysis lets you quantify how sensitive your results are to the
composition of the corpus.

The idea is simple: subsample the corpus *B* times, rebuild the network
from scratch each time, and track how node rankings change. If a node
consistently ranks near the top across subsamples, its centrality is
robust. If its rank fluctuates wildly, any single ranking should be
interpreted cautiously.

### 9.2 The `network_stability()` function

``` r

stab <- network_stability(x, type = "coauthor", B = 30, fraction = 0.8, seed = 42)
stab
#>        node mean_rank  sd_rank replicates
#> 1 A0000043f  4.400000 1.599569         30
#> 2 A00000621  4.866667 1.553269         30
#> 3 A000008ad  3.450000 1.723819         30
#> 4 A000008c4  4.800000 1.589838         30
#> 5 A00000905  5.033333 1.473521         30
#> 6 A00000f4d  2.650000 1.480622         30
#> 7 A00000f73  2.800000 1.710011         30
```

The output has four columns:

- **node** – author ID.
- **mean_rank** – average degree rank across subsamples (lower = more
  central).
- **sd_rank** – standard deviation of the rank (lower = more stable).
- **replicates** – number of subsamples in which the node appeared.

### 9.3 Interpreting stability results

A node with `mean_rank = 1.0` and `sd_rank = 0.0` is the top-ranked node
in every subsample — maximally stable. A node with `mean_rank = 3.5` and
`sd_rank = 2.1` fluctuates between roughly ranks 1 and 6, which is still
reasonably stable for a small network.

Nodes with high `sd_rank` relative to `mean_rank` are unstable. This can
happen when:

- The node participates in only one or two papers, so its connectivity
  changes substantially when those papers are removed.
- The network is small and subsampling creates large structural shifts.

``` r

# Sort by stability (lowest SD = most stable)
stab[order(stab$sd_rank), ]
#>        node mean_rank  sd_rank replicates
#> 5 A00000905  5.033333 1.473521         30
#> 6 A00000f4d  2.650000 1.480622         30
#> 2 A00000621  4.866667 1.553269         30
#> 4 A000008c4  4.800000 1.589838         30
#> 1 A0000043f  4.400000 1.599569         30
#> 7 A00000f73  2.800000 1.710011         30
#> 3 A000008ad  3.450000 1.723819         30
```

### 9.4 Stability for keyword networks

``` r

stab_kw <- network_stability(x, type = "keyword", B = 20, fraction = 0.8, seed = 7)
stab_kw[order(stab_kw$sd_rank), ]
#>                node mean_rank   sd_rank replicates
#> 23            wheat 17.541667 0.6200562         12
#> 16          silicon  2.025000 0.6972691         20
#> 6  machine learning 17.607143 0.7119467         14
#> 24            yield 17.607143 0.7119467         14
#> 4           drought 10.187500 0.7274384         16
#> 18      soil carbon 17.750000 0.7524470         18
#> 14         rotation 17.909091 0.7687061         11
#> 19  soil microbiome 17.909091 0.7687061         11
#> 5        efficiency 10.382353 0.8009645         17
#> 12   remote sensing 10.392857 0.8361673         14
#> 13             rice 10.357143 0.8418974         14
#> 2     climate-smart 10.305556 0.8425956         18
#> 8        management 10.305556 0.8425956         18
#> 1       aggregation 10.428571 0.8516306         14
#> 9     meta-analysis 10.200000 0.8618916         15
#> 21           stress 10.200000 0.8618916         15
#> 11      phenotyping 10.264706 0.8859608         17
#> 22              uav 10.264706 0.8859608         17
#> 7             maize  4.578947 3.6752292         19
#> 10         nitrogen  5.315789 3.6976364         19
#> 17             soil  5.325000 3.7880525         20
#> 20          soybean  5.900000 3.8340579         20
#> 15         salinity  9.361111 5.3873642         18
#> 3       cover crops  9.075000 6.1479029         20
```

### 9.5 Choosing the number of subsamples

More subsamples give more precise stability estimates but take longer.
For exploratory work, `B = 20` to `B = 50` is usually sufficient. For
publication-quality results, `B = 100` to `B = 200` is recommended. The
default of `B = 100` strikes a balance.

``` r

# Quick stability check
stab_quick <- network_stability(x, B = 10, seed = 1)

# More thorough stability check
stab_thorough <- network_stability(x, B = 100, seed = 1)
```

### 9.6 The `fraction` parameter

The `fraction` parameter controls what proportion of works is retained
in each subsample. The default of `0.8` (80%) applies moderate
perturbation — enough to test sensitivity without destroying the network
structure. Lower values (e.g., `0.5`) test more extreme scenarios but
may produce disconnected subgraphs that penalise centrality unfairly.

``` r

# Very aggressive subsampling
stab_extreme <- network_stability(x, B = 20, fraction = 0.5, seed = 42)
stab_extreme[order(stab_extreme$sd_rank), ]
#>        node mean_rank  sd_rank replicates
#> 6 A00000f4d  2.525000 1.229837         20
#> 3 A000008ad  3.250000 1.428101         20
#> 5 A00000905  4.555556 1.679363         18
#> 2 A00000621  3.805556 1.681551         18
#> 4 A000008c4  4.225000 1.705062         20
#> 7 A00000f73  4.150000 1.762922         20
#> 1 A0000043f  4.558824 1.853058         17
```

### 9.7 Stability as a reporting standard

We recommend that any published bibliometric network analysis include a
stability assessment. A simple table of mean rank and standard deviation
for the top 10 nodes adds negligible space to a paper but substantially
increases reproducibility and reader confidence.

------------------------------------------------------------------------

## 10. Edge weight thresholds

### 10.1 Why thresholding matters

A bibliography with 12 works and 7 authors will inevitably produce a
small, sparse graph. In larger corpora, the edge list can be enormous.
Thresholding — keeping only edges above a minimum weight — is the
primary tool for controlling graph density.

Setting `min_weight = 1` keeps all edges. Increasing the threshold
removes weak or incidental co-occurrences, often revealing the
underlying structure more clearly.

### 10.2 Effect on graph density

``` r

# Compare graph size at different thresholds
thresholds <- 1:3
graph_sizes <- data.frame(
  min_weight = thresholds,
  vertices   = NA_integer_,
  edges      = NA_integer_
)
for (i in seq_along(thresholds)) {
  g <- bibliographic_network(x, "coauthor", min_weight = thresholds[i])
  graph_sizes$vertices[i] <- igraph::vcount(g)
  graph_sizes$edges[i]    <- igraph::ecount(g)
}
graph_sizes
#>   min_weight vertices edges
#> 1          1        7    10
#> 2          2        3     2
#> 3          3        0     0
```

As the threshold increases, edges drop — but isolated vertices (authors
with no suprathreshold connections) may remain.

### 10.3 Choosing the right threshold

There is no universal answer. Guidelines:

- Start with `min_weight = 1` (the default) to see the full network.
- Increase to 2 or 3 to remove noise.
- For very large corpora, a threshold of 3–5 is common for coauthorship
  networks.
- Always report the threshold used.

### 10.4 Thresholding and stability interact

Higher thresholds produce smaller, more stable networks (fewer weak
edges means less variability). However, they also eliminate information.
A complementary approach is to build at `min_weight = 1` and let the
stability analysis identify which connections are robust.

### 10.5 Thresholding by percentile

Some analysts prefer to set the threshold based on the distribution of
edge weights rather than an absolute value. The idea is to keep, say,
the top 50% of edges by weight:

``` r

# Percentile-based thresholding
g_full <- bibliographic_network(x, "coauthor", min_weight = 1)
all_weights <- igraph::E(g_full)$weight

# Compute percentiles
percentiles <- c(0, 25, 50, 75)
pct_thresholds <- quantile(all_weights, probs = percentiles / 100)

# Resulting edge counts at each percentile
pct_df <- data.frame(
  percentile    = paste0(percentiles, "%"),
  min_weight    = as.numeric(pct_thresholds),
  edges_retained = vapply(as.numeric(pct_thresholds), function(thr) {
    sum(all_weights >= thr)
  }, integer(1))
)
pct_df
#>   percentile min_weight edges_retained
#> 1         0%          1             10
#> 2        25%          1             10
#> 3        50%          1             10
#> 4        75%          1             10
```

### 10.6 Network density and connected components

Beyond edge count, two useful graph metrics are density (the ratio of
actual edges to all possible edges) and the number of connected
components:

``` r

# Network density at the default threshold
g1 <- bibliographic_network(x, "coauthor", min_weight = 1)
cat("Density (min_weight = 1):", igraph::edge_density(g1), "\n")
#> Density (min_weight = 1): 0.4761905
cat("Connected components:", igraph::count_components(g1), "\n\n")
#> Connected components: 1

# At a higher threshold
g2 <- bibliographic_network(x, "coauthor", min_weight = 2)
cat("Density (min_weight = 2):", igraph::edge_density(g2), "\n")
#> Density (min_weight = 2): 0.6666667
cat("Connected components:", igraph::count_components(g2), "\n")
#> Connected components: 1
```

Increasing the threshold may fragment the network into multiple
components. When this happens, centrality measures like betweenness
(which assumes paths exist between all node pairs) become less
meaningful. Use `igraph::decompose(g)` to extract individual components
for analysis.

``` r

# Analyse individual components (if graph fragments)
components <- igraph::decompose(g2)
cat("Number of components:", length(components), "\n")
#> Number of components: 1
for (i in seq_along(components)) {
  cat(sprintf("  Component %d: %d vertices, %d edges\n",
              i,
              igraph::vcount(components[[i]]),
              igraph::ecount(components[[i]])))
}
#>   Component 1: 3 vertices, 2 edges
```

------------------------------------------------------------------------

## 11. Visualization

### 11.1 Static plots with igraph

igraph provides basic but functional plotting. For publication-quality
figures you would typically export the graph to a vector format and
refine it in a dedicated tool, but igraph plots are excellent for
exploratory analysis.

``` r

library(igraph)

g <- bibliographic_network(x, "coauthor")
auth_map <- setNames(x$authors$display_name, x$authors$author_id)
igraph::V(g)$label <- auth_map[igraph::V(g)$name]
igraph::V(g)$color <- "lightblue"
igraph::V(g)$size  <- 10 + 3 * igraph::degree(g)
E(g)$width <- 0.5 + igraph::E(g)$weight

set.seed(42)
plot(g,
     vertex.label.cex   = 0.8,
     edge.arrow.size    = 0.3,
     main               = "Coauthorship network")
```

### 11.2 Community-coloured plots

``` r

library(igraph)

g <- bibliographic_network(x, "coauthor")
comm <- network_communities(g, method = "louvain")
auth_map <- setNames(x$authors$display_name, x$authors$author_id)
igraph::V(g)$label <- auth_map[igraph::V(g)$name]

# Assign colours by community
membership_vec <- comm$community[match(igraph::V(g)$name, comm$node)]
palette_colors <- c("#E41A1C", "#377EB8", "#4DAF4A",
                     "#984EA3", "#FF7F00", "#FFFF33")
igraph::V(g)$color <- palette_colors[membership_vec]

set.seed(42)
plot(g,
     vertex.label.cex   = 0.8,
     vertex.size        = 12,
     main               = "Coauthorship communities (Louvain)")
```

### 11.3 Keyword network plot

``` r

library(igraph)

g_kw <- bibliographic_network(x, "keyword", min_weight = 1)
igraph::V(g_kw)$size  <- 8 + 2 * igraph::degree(g_kw)
igraph::V(g_kw)$color <- "lightyellow"

comm_kw <- network_communities(g_kw, method = "louvain")
membership_kw <- comm_kw$community[match(igraph::V(g_kw)$name, comm_kw$node)]
igraph::V(g_kw)$color <- palette_colors[as.numeric(factor(membership_kw))]

set.seed(42)
plot(g_kw,
     vertex.label.cex   = 0.7,
     edge.arrow.size    = 0,
     main               = "Keyword co-occurrence network")
```

### 11.4 Interactive plots with visNetwork

For presentations, web reports, and exploratory analysis, **visNetwork**
provides interactive, zoomable network visualizations. It is an optional
dependency (Suggests).

``` r

if (requireNamespace("visNetwork", quietly = TRUE)) {

  g <- bibliographic_network(x, "coauthor")

  # Node data frame
  auth_map <- setNames(x$authors$display_name, x$authors$author_id)
  nodes <- data.frame(
    id    = igraph::V(g)$name,
    label = auth_map[igraph::V(g)$name],
    size  = 10 + 3 * igraph::degree(g),
    color = "lightblue",
    stringsAsFactors = FALSE
  )

  # Edge data frame
  edges <- igraph::as_data_frame(g, what = "edges")
  names(edges)[names(edges) == "weight"] <- "value"

  visNetwork::visNetwork(nodes, edges, main = "Coauthorship Network") %>%
    visNetwork::visOptions(highlightNearest = TRUE) %>%
    visNetwork::visPhysics(stabilization = TRUE)
}
```

### 11.5 Exporting to VOSviewer

biblioIntegrator can export networks in VOSviewer format for advanced
visualisation in that tool. This is done via
[`export_vosviewer()`](https://wep69.github.io/biblioIntegrator/reference/export_vosviewer.md).

``` r

# Export the coauthorship network to VOSviewer format
f_vos <- tempfile(fileext = ".txt")
export_vosviewer(x, f_vos, type = "coauthor")
# Open f_vos in VOSviewer
```

### 11.6 Layout choices

The choice of layout algorithm significantly affects what the viewer
sees:

- **Fruchterman-Reingold** (default in igraph): good general-purpose
  force-directed layout.
- **Kamada-Kawai**: produces more aesthetically pleasing layouts for
  small-to-medium graphs.
- **LGL** (Large Graph Layout): for graphs with hundreds of nodes.
- **Drl** (DrL): fast force-directed layout for large graphs.

``` r

library(igraph)
g <- bibliographic_network(x, "coauthor")
set.seed(42)
plot(g, layout = layout_with_kk, main = "Kamada-Kawai layout")
```

### 11.7 Centrality-weighted visualization

A useful technique is to scale node sizes and colours by centrality
values, making important nodes visually prominent:

``` r

library(igraph)

g  <- bibliographic_network(x, "coauthor")
cent <- network_centrality(g)

# Map centrality to visual properties
auth_map <- setNames(x$authors$display_name, x$authors$author_id)
igraph::V(g)$label <- auth_map[igraph::V(g)$name]

# Size by PageRank (scaled)
pr_scaled <- (cent$pagerank - min(cent$pagerank)) /
  (max(cent$pagerank) - min(cent$pagerank) + 1e-10)
igraph::V(g)$size <- 8 + 20 * pr_scaled

# Colour by betweenness (gradient: light grey to red)
bet_scaled <- (cent$betweenness - min(cent$betweenness)) /
  (max(cent$betweenness) - min(cent$betweenness) + 1e-10)
igraph::V(g)$color <- rgb(0.9 - 0.6 * bet_scaled,
                  0.6 * (1 - bet_scaled),
                  0.6 * (1 - bet_scaled))

# Edge width by weight
E(g)$width <- 0.5 + E(g)$weight

set.seed(42)
plot(g, main = "Node size = PageRank, colour = betweenness")
```

### 11.8 Producing publication-ready figures

For journal submission, raster or vector output at 300+ DPI is typically
required. igraph plots work well with R’s standard graphics devices:

``` r

library(igraph)

g <- bibliographic_network(x, "coauthor")
auth_map <- setNames(x$authors$display_name, x$authors$author_id)
igraph::V(g)$label <- auth_map[igraph::V(g)$name]
igraph::V(g)$color <- "lightblue"
igraph::V(g)$size  <- 12 + 3 * igraph::degree(g)
E(g)$width <- 0.8 + E(g)$weight

# Save as PNG (300 DPI)
png("coauthor_network.png", width = 8, height = 6,
    units = "in", res = 300)
set.seed(42)
plot(g, vertex.label.cex = 0.7, main = "Coauthorship Network")
dev.off()

# Save as PDF (vector, scalable)
pdf("coauthor_network.pdf", width = 8, height = 6)
set.seed(42)
plot(g, vertex.label.cex = 0.7, main = "Coauthorship Network")
dev.off()
```

### 11.9 visNetwork with community colours

Combining visNetwork with community detection produces interactive,
colour-coded plots that are excellent for presentation:

``` r

if (requireNamespace("visNetwork", quietly = TRUE)) {
  library(igraph)

  g <- bibliographic_network(x, "coauthor")
  comm <- network_communities(g, method = "louvain")
  auth_map <- setNames(x$authors$display_name, x$authors$author_id)

  # Build node data frame
  nodes <- data.frame(
    id    = igraph::V(g)$name,
    label = auth_map[igraph::V(g)$name],
    group = as.factor(comm$community[match(igraph::V(g)$name, comm$node)]),
    size  = 10 + 3 * igraph::degree(g),
    stringsAsFactors = FALSE
  )

  edges <- igraph::as_data_frame(g, what = "edges")
  names(edges)[names(edges) == "weight"] <- "value"

  visNetwork::visNetwork(nodes, edges,
                         main = "Coauthorship by Community") %>%
    visNetwork::visOptions(highlightNearest = TRUE) %>%
    visNetwork::visLegend()
}
```

------------------------------------------------------------------------

## 12. Comparing native and biblionetwork engines

### 12.1 Side-by-side comparison

When the biblionetwork package is installed, you can compare the two
engines directly:

``` r

g_native <- bibliographic_network(x, "coauthor", engine = "native")
attr(g_native, "engine")
#> [1] "native"
igraph::vcount(g_native)
#> [1] 7
igraph::ecount(g_native)
#> [1] 12

if (requireNamespace("biblionetwork", quietly = TRUE)) {
  g_bn <- bibliographic_network(x, "coauthor", engine = "biblionetwork")
  attr(g_bn, "engine")
  igraph::vcount(g_bn)
  igraph::ecount(g_bn)
}
#> [1] 10
```

### 12.2 Do the graphs match?

With full counting, both engines should produce equivalent edge lists
(though not necessarily in the same order). With fractional counting,
the biblionetwork engine will produce different weights.

``` r

e_native <- igraph::as_data_frame(g_native, what = "edges")
e_native <- e_native[order(e_native$from, e_native$to), ]

if (requireNamespace("biblionetwork", quietly = TRUE)) {
  e_bn <- igraph::as_data_frame(g_bn, what = "edges")
  e_bn <- e_bn[order(e_bn$from, e_bn$to), ]

  # Compare edge sets
  identical(
    paste(e_native$from, e_native$to),
    paste(e_bn$from, e_bn$to)
  )
}
#> [1] FALSE
```

### 12.3 Performance benchmark

For this tiny example the difference is negligible, but it becomes
significant for larger corpora:

``` r

# Benchmark (if microbenchmark is available)
if (requireNamespace("microbenchmark", quietly = TRUE)) {
  bench <- microbenchmark::microbenchmark(
    native         = bibliographic_network(x, "coauthor", engine = "native"),
    biblionetwork  = bibliographic_network(x, "coauthor", engine = "biblionetwork"),
    times = 100
  )
  print(bench)
}
```

------------------------------------------------------------------------

## 13. Integration with other biblioIntegrator workflows

### 13.1 Network after import and audit

The recommended workflow starts with import, proceeds through audit and
deduplication, and only then builds networks. This ensures the network
reflects a clean, harmonised corpus.

``` r

# Full pipeline
raw_data <- example_biblio()
x <- as_biblio_project(raw_data, source = "workflow-demo")

# Audit
biblio_health(x)
#>                  check n
#> 1        missing_title 0
#> 2         missing_year 0
#> 3          missing_doi 0
#> 4        duplicate_doi 0
#> 5 duplicate_title_year 0
#> 6   negative_citations 0

# Network
g <- bibliographic_network(x, "coauthor")
head(network_centrality(g))
#>                node degree strength betweenness  pagerank
#> A000008c4 A000008c4      3        3  0.03333333 0.1290688
#> A00000905 A00000905      2        3  0.12222222 0.1267212
#> A00000f4d A00000f4d      4        4  0.12222222 0.1648773
#> A00000f73 A00000f73      3        4  0.27777778 0.1612960
#> A00000621 A00000621      3        3  0.05555556 0.1273099
#> A000008ad A000008ad      2        4  0.20000000 0.1617880
network_communities(g)
#>        node community
#> 1 A000008c4         1
#> 2 A00000905         2
#> 3 A00000f4d         1
#> 4 A00000f73         2
#> 5 A00000621         1
#> 6 A000008ad         2
#> 7 A0000043f         1
```

### 13.2 Network after group comparison

If you have defined groups (e.g., early vs. recent period), you can
compare network structure between them by filtering the project first:

``` r

# Split by period
x_early <- x
x_early$works <- x$works[x$works$year <= 2021, , drop = FALSE]
x_early$authorships <- x$authorships[
  x$authorships$work_id %in% x_early$works$work_id, , drop = FALSE
]
x_early$keywords <- x$keywords[
  x$keywords$work_id %in% x_early$works$work_id, , drop = FALSE
]

x_recent <- x
x_recent$works <- x$works[x$works$year > 2021, , drop = FALSE]
x_recent$authorships <- x$authorships[
  x$authorships$work_id %in% x_recent$works$work_id, , drop = FALSE
]
x_recent$keywords <- x$keywords[
  x$keywords$work_id %in% x_recent$works$work_id, , drop = FALSE
]

# Compare network structure
g_early  <- bibliographic_network(x_early, "coauthor")
g_recent <- bibliographic_network(x_recent, "coauthor")

data.frame(
  period  = c("early (<=2021)", "recent (>2021)"),
  authors = c(igraph::vcount(g_early), igraph::vcount(g_recent)),
  edges   = c(igraph::ecount(g_early), igraph::ecount(g_recent))
)
#>           period authors edges
#> 1 early (<=2021)       7     5
#> 2 recent (>2021)       7     6
```

### 13.3 Comparing network structure across periods

Beyond simply building two graphs side-by-side, you can compute summary
statistics that highlight structural differences:

``` r

# Structural comparison
compare_network_stats <- function(g1, g2, label1 = "A", label2 = "B") {
  data.frame(
    metric    = c("vertices", "edges", "density",
                  "components", "avg_degree"),
    period_A  = c(
      igraph::vcount(g1),
      igraph::ecount(g1),
      round(igraph::edge_density(g1), 4),
      igraph::count_components(g1),
      round(mean(igraph::degree(g1)), 2)
    ),
    period_B  = c(
      igraph::vcount(g2),
      igraph::ecount(g2),
      round(igraph::edge_density(g2), 4),
      igraph::count_components(g2),
      round(mean(igraph::degree(g2)), 2)
    )
  )
}

compare_network_stats(g_early, g_recent, "early", "recent")
#>       metric period_A period_B
#> 1   vertices   7.0000   7.0000
#> 2      edges   5.0000   6.0000
#> 3    density   0.2381   0.2857
#> 4 components   2.0000   1.0000
#> 5 avg_degree   1.4300   1.7100
```

### 13.4 Networks within a foundations-to-advanced tutorial

Network analysis is step 4 in the comprehensive tutorial vignette (v07).
There the pipeline is:

1.  Diagnose the corpus (`biblio_health`).
2.  Describe production and impact (`describe_biblio`,
    `biblio_metrics`).
3.  Compare periods with inferential support (`compare_groups`).
4.  **Study the collaboration structure** (`bibliographic_network`,
    `network_centrality`, `network_communities`, `network_stability`).
5.  Examine topical change (`trend_topics`, `tfidf_terms`).
6.  Check threshold sensitivity (`sensitivity_analysis`).
7.  Generate an auditable report (`biblio_report`).

------------------------------------------------------------------------

## 14. Common mistakes

### 14.1 Confusing network construction with interpretation

The graph is an artefact of your choices (network type, engine,
threshold, algorithm). Always state these choices when reporting
results.

### 14.2 Ignoring edge weights

Edge weights carry real information about the strength of relationships.
Centrality measures that ignore weights (e.g., plain degree) treat a
single co-authored paper the same as a 20-paper collaboration. Use
`strength` alongside `degree` and note that `betweenness` in
biblioIntegrator uses inverse weights (stronger edge = shorter path).

### 14.3 Not assessing stability

Reporting “Author X is the most central” without any stability evidence
is a weak claim. Especially in small corpora, centrality ranks can be
fragile. Always include stability results.

### 14.4 Using inappropriate community detection algorithms

No single algorithm is best for all networks. Louvain can suffer from a
resolution limit (it may miss small communities). Walktrap is more
granular but slower. Label propagation is fast but non-deterministic.
Comparing at least two algorithms is good practice.

``` r

# Compare Louvain and Walktrap assignments
comm_l <- network_communities(g_coauthor, method = "louvain")
comm_w <- network_communities(g_coauthor, method = "walktrap")

comparison <- data.frame(
  node     = comm_l$node,
  louvain  = comm_l$community,
  walktrap = comm_w$community
)

# Do they agree?
all(comparison$louvain == comparison$walktrap)
#> [1] FALSE
```

### 14.5 Over-interpreting small networks

A 7-author coauthorship network from 12 papers is a toy example, not a
basis for field-level claims. The functions work correctly at any scale,
but interpretation must match the scale and scope of the data.

### 14.6 Confusing coupling with cocitation

Coupling links papers that *share references* (backward-looking).
Cocitation links papers that *are cited together* (forward-looking). The
two can produce quite different topologies from the same corpus. Be
explicit about which one you are using.

### 14.7 Handling isolated nodes silently

Isolated nodes (degree 0) are not errors — they are structural features.
Don’t remove them without explaining why, and don’t ignore them when
reporting node counts.

### 14.8 Forgetting the `engine` attribute

Always check `attr(graph, "engine")` when writing methods or comparing
results. The native and biblionetwork engines can produce different
weight distributions (especially with fractional counting), and this
affects downstream analysis.

``` r

# Check the engine
attr(g_coauthor, "engine")
#> [1] "biblionetwork"
```

------------------------------------------------------------------------

## 15. Advanced topics

### 15.1 Multi-layer networks

biblioIntegrator builds separate networks for each type (coauthor,
keyword, citation). Combining them into a multi-layer network is
possible but requires manual construction:

``` r

library(igraph)

g_coauthor <- bibliographic_network(x, "coauthor")
g_keyword  <- bibliographic_network(x, "keyword")

# Add a type attribute to distinguish layers
E(g_coauthor)$layer <- "coauthor"
E(g_keyword)$layer  <- "keyword"

# Combine (disjoint union; rename to avoid clashes)
igraph::V(g_keyword)$name <- paste0("kw_", igraph::V(g_keyword)$name)
g_combined <- igraph::disjoint_union(g_coauthor, g_keyword)
```

### 15.2 Temporal network slices

Building networks for different time windows and comparing them reveals
how collaboration patterns evolve. This is useful for studying the
emergence of new research communities.

``` r

# Build networks for each year
years <- sort(unique(x$works$year))
year_nets <- list()
for (yr in years) {
  x_sub <- x
  x_sub$works <- x$works[x$works$year == yr, , drop = FALSE]
  x_sub$authorships <- x$authorships[
    x$authorships$work_id %in% x_sub$works$work_id, , drop = FALSE
  ]
  x_sub$keywords <- x$keywords[
    x$keywords$work_id %in% x_sub$works$work_id, , drop = FALSE
  ]
  g_sub <- tryCatch(
    bibliographic_network(x_sub, "coauthor"),
    error = function(e) NULL
  )
  if (!is.null(g_sub) && igraph::vcount(g_sub) > 0) {
    year_nets[[as.character(yr)]] <- g_sub
  }
}

# Summary per year
data.frame(
  year    = names(year_nets),
  authors = vapply(year_nets, function(g) as.integer(igraph::vcount(g)), integer(1)),
  edges   = vapply(year_nets, function(g) as.integer(igraph::ecount(g)), integer(1))
)
#>      year authors edges
#> 2017 2017       2     1
#> 2018 2018       2     1
#> 2019 2019       2     1
#> 2020 2020       4     2
#> 2021 2021       2     1
#> 2022 2022       4     2
#> 2023 2023       2     1
#> 2024 2024       4     2
#> 2025 2025       2     1
```

### 15.3 Custom centrality weight transformations

Sometimes you want to transform weights before computing centrality —
e.g., taking the log of weights to reduce skew. The igraph object allows
you to set edge attributes directly:

``` r

library(igraph)

g <- bibliographic_network(x, "coauthor")
E(g)$log_weight <- log1p(E(g)$weight)

# Betweenness with log-transformed weights
bc <- betweenness(g, weights = 1 / E(g)$log_weight, normalized = TRUE)
data.frame(node = igraph::V(g)$name, betweenness = bc)
```

### 15.4 Exporting network data for external tools

biblioIntegrator stores networks as igraph objects, which can be
exported to many formats:

``` r

library(igraph)

g <- bibliographic_network(x, "coauthor")

# Edge list (CSV)
e <- igraph::as_data_frame(g, what = "edges")
write.csv(e, "coauthor_edges.csv", row.names = FALSE)

# GraphML (for Gephi, Cytoscape, etc.)
igraph::write_graph(g, "coauthor.graphml", format = "graphml")

# Pajek format
igraph::write_graph(g, "coauthor.net", format = "pajek")

# Adjacency matrix
adj <- as.matrix(igraph::as_adjacency_matrix(g, attr = "weight"))
```

### 15.5 Sensitivity of network metrics to the threshold

This helper function explores how centrality rankings change as the
weight threshold increases:

``` r

# Sensitivity analysis for thresholds
threshold_sensitivity <- function(proj, type = "coauthor",
                                  thresholds = 1:3) {
  results <- list()
  for (thr in thresholds) {
    g <- bibliographic_network(proj, type, min_weight = thr)
    if (igraph::vcount(g) == 0) next
    cent <- network_centrality(g)
    cent$threshold <- thr
    results[[as.character(thr)]] <- cent
  }
  do.call(rbind, results)
}

sens <- threshold_sensitivity(x, thresholds = 1:3)
head(sens, 12)
#>                  node degree strength betweenness  pagerank threshold
#> 1.A000008c4 A000008c4      3        3  0.03333333 0.1290688         1
#> 1.A00000905 A00000905      2        3  0.12222222 0.1267212         1
#> 1.A00000f4d A00000f4d      4        4  0.12222222 0.1648773         1
#> 1.A00000f73 A00000f73      3        4  0.27777778 0.1612960         1
#> 1.A00000621 A00000621      3        3  0.05555556 0.1273099         1
#> 1.A000008ad A000008ad      2        4  0.20000000 0.1617880         1
#> 1.A0000043f A0000043f      3        3  0.12222222 0.1289388         1
#> 2.A00000905 A00000905      1        2  0.00000000 0.2567568         2
#> 2.A00000f73 A00000f73      1        2  0.00000000 0.2567568         2
#> 2.A000008ad A000008ad      2        4  1.00000000 0.4864865         2
```

### 15.6 Global network statistics

Beyond individual node metrics, whole-network statistics describe the
overall structure. These are returned directly by igraph:

``` r

# Global network statistics
g <- bibliographic_network(x, "coauthor", min_weight = 1)

global_stats <- data.frame(
  metric = c(
    "vertices", "edges", "density", "diameter",
    "avg_path_length", "transitivity", "components"
  ),
  value  = c(
    igraph::vcount(g),
    igraph::ecount(g),
    round(igraph::edge_density(g), 4),
    igraph::diameter(g, directed = FALSE),
    round(igraph::average.path.length(g, directed = FALSE), 3),
    round(igraph::transitivity(g, type = "global"), 4),
    igraph::count_components(g)
  )
)
#> Warning: `average.path.length()` was deprecated in igraph 2.0.0.
#> ℹ Please use `mean_distance()` instead.
#> This warning is displayed once per session.
#> Call `lifecycle::last_lifecycle_warnings()` to see where this warning was
#> generated.
global_stats
#>            metric   value
#> 1        vertices  7.0000
#> 2           edges 10.0000
#> 3         density  0.4762
#> 4        diameter  4.0000
#> 5 avg_path_length  1.9520
#> 6    transitivity  0.4500
#> 7      components  1.0000
```

These metrics characterise the network as a whole:

- **Density** ranges from 0 (no edges) to 1 (all possible edges).
  Bibliographic networks are typically sparse (density \< 0.3).
- **Diameter** is the longest shortest path. Small diameters suggest a
  “small world” structure.
- **Transitivity** (global clustering coefficient) measures the tendency
  of triads to close — high transitivity is a hallmark of collaboration
  networks.

### 15.7 Using the adjacency matrix directly

Some analyses (e.g., eigendecomposition, hierarchical clustering) work
on the adjacency matrix rather than the igraph object. You can extract
it easily:

``` r

# Weighted adjacency matrix
g <- bibliographic_network(x, "coauthor", min_weight = 1)
adj <- as.matrix(igraph::as_adjacency_matrix(g, attr = "weight"))

# Display the matrix (rows and columns are author IDs)
auth_map <- setNames(x$authors$display_name, x$authors$author_id)
dimnames(adj) <- list(
  auth_map[rownames(adj)],
  auth_map[colnames(adj)]
)
adj
#>           Costa C Gomez E Martins B Pereira W Lima D Silva A Rao F
#> Costa C         0       0         1         0      1       0     1
#> Gomez E         0       0         0         0      0       2     1
#> Martins B       1       0         0         1      1       0     1
#> Pereira W       0       0         1         0      1       2     0
#> Lima D          1       0         1         1      0       0     0
#> Silva A         0       2         0         2      0       0     0
#> Rao F           1       1         1         0      0       0     0
```

### 15.8 Correlation between centrality measures

In many networks, degree and strength are highly correlated (they differ
mainly when weights are heterogeneous). Betweenness and degree are often
less correlated because betweenness depends on position in the global
structure, not just local connectivity.

``` r

# Correlation matrix of centrality measures
cent <- network_centrality(g)
cent_numeric <- cent[, c("degree", "strength", "betweenness", "pagerank")]
round(cor(cent_numeric, use = "complete.obs"), 3)
#>             degree strength betweenness pagerank
#> degree       1.000    0.194      -0.193    0.250
#> strength     0.194    1.000       0.748    0.997
#> betweenness -0.193    0.748       1.000    0.711
#> pagerank     0.250    0.997       0.711    1.000
```

------------------------------------------------------------------------

## 16. Reproducibility checklist

When publishing network results from biblioIntegrator, report:

**Network type**: coauthorship, coupling, or cocitation.

**Engine**: native or biblionetwork (with version).

**Counting method**: full or fractional.

**Weight threshold**: `min_weight` value.

**Centrality measures**: which ones were used (degree, strength,
betweenness, closeness, PageRank).

**Community algorithm**: Louvain, Walktrap, label propagation, etc.

**Stability assessment**: number of subsamples (*B*), fraction, and
seed.

**Corpus metadata**: number of works, time span, source database(s).

**Software versions**: biblioIntegrator version, igraph version,
biblionetwork version (if used).

``` r

# Capture versions
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
#>  [1] vctrs_0.7.3         cli_3.6.6           knitr_1.52         
#>  [4] rlang_1.3.0         xfun_0.61           otel_0.2.0         
#>  [7] textshaping_1.0.5   data.table_1.18.6.1 jsonlite_2.0.0     
#> [10] glue_1.8.1          htmltools_0.5.9     ragg_1.5.2         
#> [13] sass_0.4.10         rmarkdown_2.32      grid_4.6.0         
#> [16] evaluate_1.0.5      jquerylib_0.1.4     fastmap_1.2.0      
#> [19] yaml_2.3.12         lifecycle_1.0.5     compiler_4.6.0     
#> [22] igraph_2.3.3        fs_2.1.0            pkgconfig_2.0.3    
#> [25] htmlwidgets_1.6.4   biblionetwork_0.1.0 lattice_0.23-1     
#> [28] systemfonts_1.3.2   digest_0.6.39       R6_2.6.1           
#> [31] pillar_1.11.1       Rdpack_2.6.6        magrittr_2.0.5     
#> [34] rbibutils_2.4.1     Matrix_1.7-6        bslib_0.12.0       
#> [37] tools_4.6.0         pkgdown_2.2.1       cachem_1.1.0       
#> [40] desc_1.4.3
```

------------------------------------------------------------------------

## 17. Function reference

The following functions are covered in this vignette:

| Function | Purpose |
|----|----|
| [`bibliographic_network()`](https://wep69.github.io/biblioIntegrator/reference/bibliographic_network.md) | Build coauthorship, keyword, or citation networks |
| [`network_centrality()`](https://wep69.github.io/biblioIntegrator/reference/network_centrality.md) | Compute degree, strength, betweenness, PageRank |
| [`network_communities()`](https://wep69.github.io/biblioIntegrator/reference/network_communities.md) | Detect communities (Louvain, Walktrap, label_prop) |
| [`network_stability()`](https://wep69.github.io/biblioIntegrator/reference/network_stability.md) | Assess rank stability via subsampling |
| [`backend_status()`](https://wep69.github.io/biblioIntegrator/reference/backend_status.md) | Check which optional backends are installed |
| [`export_vosviewer()`](https://wep69.github.io/biblioIntegrator/reference/export_vosviewer.md) | Export to VOSviewer format |

See the function help pages for complete parameter documentation:

``` r

?bibliographic_network
?network_centrality
?network_communities
?network_stability
```

------------------------------------------------------------------------

## 18. Quick reference: complete workflow

``` r

# --- Complete network analysis workflow ---
library(biblioIntegrator)

# 1. Load and harmonise data
x <- as_biblio_project(example_biblio(), source = "quick-ref")

# 2. Build network
g <- bibliographic_network(x, "coauthor")
cat("Engine:", attr(g, "engine"), "\n")
#> Engine: biblionetwork
cat("Vertices:", igraph::vcount(g), "  Edges:", igraph::ecount(g), "\n")
#> Vertices: 7   Edges: 10

# 3. Centrality
cent <- network_centrality(g)
cat("\nTop authors by PageRank:\n")
#> 
#> Top authors by PageRank:
print(head(cent[order(-cent$pagerank), ], 3))
#>                node degree strength betweenness  pagerank
#> A00000f4d A00000f4d      4        4   0.1222222 0.1648773
#> A000008ad A000008ad      2        4   0.2000000 0.1617880
#> A00000f73 A00000f73      3        4   0.2777778 0.1612960

# 4. Communities
comm <- network_communities(g, method = "louvain")
cat("\nCommunity assignments:\n")
#> 
#> Community assignments:
print(comm)
#>        node community
#> 1 A000008c4         1
#> 2 A00000905         2
#> 3 A00000f4d         1
#> 4 A00000f73         2
#> 5 A00000621         1
#> 6 A000008ad         2
#> 7 A0000043f         1

# 5. Stability
stab <- network_stability(x, B = 20, seed = 42)
cat("\nMost stable nodes:\n")
#> 
#> Most stable nodes:
print(stab[order(stab$sd_rank)[1:3], ])
#>        node mean_rank  sd_rank replicates
#> 6 A00000f4d     2.375 1.234110         20
#> 2 A00000621     5.000 1.468977         20
#> 5 A00000905     5.175 1.498025         20
cat("\nDone.\n")
#> 
#> Done.
```

------------------------------------------------------------------------

## 19. References

- Goutsmedt, A., Claveau, F. & Truc, A. (2021). biblionetwork.
  <https://github.com/agoutsmedt/biblionetwork>

- Aria, M. & Cuccurullo, C. (2017). bibliometrix: An R-tool for
  comprehensive science mapping analysis. *Journal of Informetrics*,
  11(4), 959–975. <doi:10.1016/j.joi.2017.08.007>

- Csardi, G. & Nepusz, T. (2006). The igraph software package for
  complex network research. *InterJournal, Complex Systems*, 1695(5),
  1–9. <https://igraph.org>

- Blondel, V. D., Guillaume, J.-L., Lambiotte, R. & Lefebvre, E. (2008).
  Fast unfolding of communities in large networks. *Journal of
  Statistical Mechanics: Theory and Experiment*, 2008(10), P10008.
  <doi:10.1088/1742-5468/2008/10/P10008>

- Pons, P. & Latapy, M. (2005). Computing communities in large networks
  using random walks. *Journal of Graph Algorithms and Applications*,
  10(2), 191–218.

- Raghavan, U. N., Albert, R. & Kumara, S. (2007). Near linear time
  algorithm to detect community structures in large-scale networks.
  *Physical Review E*, 76(3), 036106.

- Brin, S. & Page, L. (1998). The anatomy of a large-scale hypertextual
  Web search engine. *Computer Networks and ISDN Systems*, 30(1–7),
  107–117.

- Kessler, M. M. (1963). Bibliographic coupling between scientific
  papers. *American Documentation*, 14(1), 10–25.

- Small, H. (1973). Co-citation in the scientific literature: A new
  measure of the relationship between two documents. *Journal of the
  American Society for Information Science*, 24(4), 265–269.

- Newman, M. E. J. (2004). Coauthorship networks and patterns of
  scientific collaboration. *Proceedings of the National Academy of
  Sciences*, 101(suppl 1), 5200–5205. <doi:10.1073/pnas.0307545100>

- Wasserman, S. & Faust, K. (1994). *Social Network Analysis: Methods
  and Applications*. Cambridge University Press.

------------------------------------------------------------------------

## 20. Session info

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
#>  [1] vctrs_0.7.3         cli_3.6.6           knitr_1.52         
#>  [4] rlang_1.3.0         xfun_0.61           otel_0.2.0         
#>  [7] textshaping_1.0.5   data.table_1.18.6.1 jsonlite_2.0.0     
#> [10] glue_1.8.1          htmltools_0.5.9     ragg_1.5.2         
#> [13] sass_0.4.10         rmarkdown_2.32      grid_4.6.0         
#> [16] evaluate_1.0.5      jquerylib_0.1.4     fastmap_1.2.0      
#> [19] yaml_2.3.12         lifecycle_1.0.5     compiler_4.6.0     
#> [22] igraph_2.3.3        fs_2.1.0            pkgconfig_2.0.3    
#> [25] htmlwidgets_1.6.4   biblionetwork_0.1.0 lattice_0.23-1     
#> [28] systemfonts_1.3.2   digest_0.6.39       R6_2.6.1           
#> [31] pillar_1.11.1       Rdpack_2.6.6        magrittr_2.0.5     
#> [34] rbibutils_2.4.1     Matrix_1.7-6        bslib_0.12.0       
#> [37] tools_4.6.0         pkgdown_2.2.1       cachem_1.1.0       
#> [40] desc_1.4.3
```

------------------------------------------------------------------------

*End of vignette v05-networks.Rmd. For the complete end-to-end workflow
covering all biblioIntegrator features, see
[`vignette("v07-foundations-to-advanced-tutorial")`](https://wep69.github.io/biblioIntegrator/articles/v07-foundations-to-advanced-tutorial.md).*
