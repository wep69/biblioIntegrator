#' Create a Biblium-ready data frame
#' @param x A `biblio_project`.
#' @return A data frame with Biblium canonical field names.
#' @export
#' @examples
#' to_biblium(as_biblio_project(example_biblio()))
#' head(to_biblium(as_biblio_project(example_biblio())),3)
#' names(to_biblium(as_biblio_project(example_biblio())))
to_biblium <- function(x) {
  w=x$works; au=tapply(x$authors$display_name[match(x$authorships$author_id,x$authors$author_id)],x$authorships$work_id,paste,collapse="; "); kw=tapply(x$keywords$keyword,x$keywords$work_id,paste,collapse="; ")
  src=if(!is.null(w$source)) as.character(w$source) else rep(NA_character_,nrow(w))
  data.frame(Title=w$title,Year=w$year,Authors=unname(au[w$work_id]),`Author Keywords`=unname(kw[w$work_id]),Source=src,check.names=FALSE,stringsAsFactors=FALSE)
}

# Chamada unica a ponte Python: importa o modulo uma vez por chamada, captura o
# stderr do Python (onde o Biblium emite avisos) e o reemite como warning do R,
# pois tryCatch(warning=) e suppressWarnings() nao alcancam o stderr externo.
.bi_bridge_call <- function(fun, args, python=NULL) {
  st=biblium_backend_status(python); if(!isTRUE(st$available)) stop("Biblium backend is unavailable or not importable. Run install_biblium_backend().",call.=FALSE)
  path=system.file("python",package="biblioIntegrator"); mod=reticulate::import_from_path("biblium_bridge",path=path,convert=TRUE)
  out=NULL; saida <- reticulate::py_capture_output(out <- do.call(mod[[fun]],args))
  if (nzchar(trimws(saida))) warning(trimws(saida), call.=FALSE)
  out
}

.bi_python <- function(python=NULL) {
  if(!is.null(python)) return(normalizePath(python,winslash="/",mustWork=FALSE))
  e=Sys.getenv("BIBLIOINTEGRATOR_PYTHON",unset=""); if(nzchar(e))return(e)
  o=getOption("biblioIntegrator.python",NULL); if(!is.null(o))return(o)
  NULL
}

# cache de sessao do status do backend (memoizacao): fica antes do bloco de
# documentacao para nao deslocar o roxygen da funcao exportada
.bi_status_cache <- new.env(parent=emptyenv())

#' Status of the optional Biblium Python backend
#' @param python Optional Python executable.
#' @return A list with availability, Python path and Biblium version.
#' @export
#' @examples
#' biblium_backend_status()
#' python_backend_status()
#' names(biblium_backend_status())
biblium_backend_status <- function(python=NULL) {
  if(is.null(python)&&!is.null(.bi_status_cache$status))return(.bi_status_cache$status)
  if(!requireNamespace("reticulate",quietly=TRUE)) return(list(available=FALSE,python=NA_character_,version=NA_character_,reason="reticulate not installed"))
  py=.bi_python(python); if(!is.null(py)) try(reticulate::use_python(py,required=FALSE),silent=TRUE)
  ok=tryCatch(reticulate::py_module_available("biblium"),error=function(e)FALSE)
  ver=if(ok)tryCatch(as.character(reticulate::import("biblium",convert=TRUE)$`__version__`),error=function(e)NA_character_) else NA_character_
  cfg=tryCatch(reticulate::py_config(),error=function(e)NULL)
  res=list(available=isTRUE(ok)&&!is.na(ver),python=if(is.null(cfg)) py %||% NA_character_ else cfg$python,version=ver,reason=if(ok&&!is.na(ver))"ok" else "Biblium could not be imported"); if(is.null(python)).bi_status_cache$status=res; res
}

#' Backward-compatible Python backend status
#' @param python Optional Python executable.
#' @return Same result as [biblium_backend_status()].
#' @export
#' @examples
#' python_backend_status()
#' names(python_backend_status())
#' is.list(python_backend_status())
python_backend_status <- function(python=NULL) biblium_backend_status(python)

#' Install an isolated Biblium backend
#' @param envname Virtual environment name or path.
#' @param python Python executable used to create the environment.
#' @param version Biblium version.
#' @param extras Optional Biblium extras (`"nlp"`, `"geo"`, `"ml"`,
#'   `"interactive"`, `"llm"`, `"network"`, `"extra"`); installed as
#'   `biblium[extra,...]`. NLP topic models via scikit-learn need no extra;
#'   transformer-based models do.
#' @return Invisible virtual environment path.
#' @export
#' @examples
#' \dontrun{
#' install_biblium_backend()
#' install_biblium_backend(version="2.16.0")
#' install_biblium_backend(envname="r-bibliointegrator")
#' install_biblium_backend(extras="geo")
#' }
install_biblium_backend <- function(envname="r-bibliointegrator",python=NULL,version="2.16.0",extras=NULL) {
  if(!requireNamespace("reticulate",quietly=TRUE)) stop("Install 'reticulate'.",call.=FALSE)
  if(!is.null(extras)) { extras=match.arg(extras,c("nlp","geo","ml","interactive","llm","network","extra"),several.ok=TRUE); extras=unique(extras) }
  if(!reticulate::virtualenv_exists(envname)) reticulate::virtualenv_create(envname=envname,python=python)
  pkgs=c(paste0("biblium",if(length(extras))paste0("[",paste(extras,collapse=","),"]"),"==",version),"huggingface_hub","plotly")
  reticulate::py_install(pkgs,envname=envname,pip=TRUE)
  .bi_status_cache$status <- NULL; p=reticulate::virtualenv_python(envname); message("Set options(biblioIntegrator.python = ",dQuote(p),") before initializing Python."); invisible(p)
}

.bi_pyextras <- function(modules) {
  ok=vapply(modules,function(m)isTRUE(tryCatch(reticulate::py_module_available(m),error=function(e)FALSE)),logical(1L))
  missing=modules[!ok]; if(length(missing)) stop("Python modules missing: ",paste(missing,collapse=", "),". Run install_biblium_backend(extras=...).",call.=FALSE)
  invisible(TRUE)
}

#' Enable an existing Python backend
#' @param python Python executable.
#' @return Backend status.
#' @export
#' @examples
#' \dontrun{
#' enable_python_backend("path/to/python")
#' enable_python_backend(Sys.which("python"))
#' enable_python_backend(reticulate::virtualenv_python("r-bibliointegrator"))
#' }
enable_python_backend <- function(python) { options(biblioIntegrator.python=python); biblium_backend_status(python) }

#' Compare bibliometric groups with Biblium 2.16
#'
#' Calls the public `BiblioGroup` association interface with permutation inference,
#' then converts the result to the same R structure used by the native engine.
#' @param x A `biblio_project`.
#' @param groups Group definition accepted by [form_groups()].
#' @param entity `"keyword"` or `"author"`.
#' @param permutations Number of Biblium permutations.
#' @param seed Random seed.
#' @param python Optional Python executable.
#' @return A `biblio_group_comparison`.
#' @export
#' @examples
#' \dontrun{
#' x <- as_biblio_project(example_biblio()); g <- rep(c("early","late"),6)
#' biblium_compare_groups(x,g,permutations=99,seed=1)
#' biblium_compare_groups(x,cbind(a=1:12<=7,b=1:12>=5),permutations=99,seed=2)
#' biblium_compare_groups(x,g,entity="author",permutations=99,seed=3)
#' }
biblium_compare_groups <- function(x,groups,entity=c("keyword","author"),permutations=999,seed=NULL,python=NULL) {
  entity=match.arg(entity); G=as.data.frame(form_groups(x,groups),check.names=FALSE)
  ans=.bi_bridge_call("compare_groups",list(to_biblium(x),G,entity=entity,permutations=as.integer(permutations),random_state=if(is.null(seed))NULL else as.integer(seed)),python=python)
  structure(list(engine="biblium",entity=entity,groups=as.matrix(G),observed=as.matrix(ans$observed),expected=as.matrix(ans$expected),residuals=as.matrix(ans$residuals),chi_square=as.numeric(ans$chi_square),p_value=as.numeric(ans$p_value),cramers_v=as.numeric(ans$cramers_v),cramers_v_ci=c(NA_real_,NA_real_),overlap=!isTRUE(ans$disjoint),permutations=as.integer(ans$permutations),cell_p_adjusted=if(is.null(ans$permutation_residuals_p_adj))NULL else as.matrix(ans$permutation_residuals_p_adj)),class="biblio_group_comparison")
}

#' Cross-validate native and Biblium group inference
#' @param x A `biblio_project`.
#' @param groups Group definition.
#' @param entity Entity type.
#' @param permutations Number of permutations.
#' @param seed Seed used by both engines.
#' @return A comparison data frame and both fitted objects.
#' @export
#' @examples
#' \dontrun{
#' x <- as_biblio_project(example_biblio())
#' g <- rep(c("a", "b"), 6)
#' validate_biblium(x, g, permutations = 99, seed = 1)
#' validate_biblium(x,g,entity="author",permutations=99,seed=2)
#' validate_biblium(x,cbind(a=1:12<=7,b=1:12>=5),permutations=99,seed=3)
#' }
validate_biblium <- function(x,groups,entity=c("keyword","author"),permutations=999,seed=1) {
  entity=match.arg(entity); a=compare_groups(x,groups,entity=entity,permutations=permutations,seed=seed,engine="native"); b=biblium_compare_groups(x,groups,entity=entity,permutations=permutations,seed=seed)
  list(comparison=data.frame(metric=c("chi_square","p_value","cramers_v"),native=c(a$chi_square,a$p_value,a$cramers_v),biblium=c(b$chi_square,b$p_value,b$cramers_v),difference=c(a$chi_square-b$chi_square,a$p_value-b$p_value,a$cramers_v-b$cramers_v)),native=a,biblium=b)
}

#' Diversity indices with Biblium 2.16
#'
#' Shannon, Simpson and Gini indices over authors, keywords or sources, for the
#' whole corpus (`"overall"`), per year (`"temporal"`) or per group (`"group"`).
#' @param x A `biblio_project`.
#' @param entity `"keyword"`, `"author"` or `"source"`.
#' @param level `"overall"`, `"temporal"` or `"group"`.
#' @param groups Group definition accepted by [form_groups()]; required when `level="group"`.
#' @param min_items_per_year Minimum works per year in `"temporal"` level.
#' @param python Optional Python executable.
#' @return A `biblio_diversity` list with engine, indices and summary/trend.
#' @export
#' @examples
#' \dontrun{
#' x <- as_biblio_project(example_biblio())
#' biblium_diversity(x)
#' biblium_diversity(x,entity="author",level="temporal",min_items_per_year=1)
#' biblium_diversity(x,level="group",groups=ifelse(x$works$year<2022,"early","late"))
#' }
biblium_diversity <- function(x,entity=c("keyword","author","source"),level=c("overall","temporal","group"),groups=NULL,min_items_per_year=5L,python=NULL) {
  entity=match.arg(entity); level=match.arg(level); x=as_biblio_project(x)
  if(level=="group") {
    if(is.null(groups)) stop("`groups` is required when level=\"group\".",call.=FALSE)
    G=as.data.frame(form_groups(x,groups),check.names=FALSE)
    if(!any(colSums(G)>0)) stop("No group contains works.",call.=FALSE)
    ans=.bi_bridge_call("diversity_group",list(to_biblium(x),G,entity=entity),python=python)
    idx=.bi_pyframe(ans$indices); summ=NULL; tr=NULL
  } else if(level=="temporal") {
    ans=.bi_bridge_call("diversity_temporal",list(to_biblium(x),entity=entity,min_items_per_year=as.integer(min_items_per_year)),python=python)
    idx=.bi_pyframe(ans$series); summ=NULL; tr=ans$trend
  } else {
    ans=.bi_bridge_call("diversity_overall",list(to_biblium(x),entity=entity),python=python)
    idx=.bi_pyframe(ans$indices); summ=ans$summary; tr=NULL
  }
  structure(list(engine="biblium",entity=entity,level=level,indices=idx,summary=summ,trend=tr),class="biblio_diversity")
}

# Converte quadro vindo do Python: preserva rotulos do Biblium (com espacos)
# e remove o indice pandas, que quebra comparacoes em testes.
.bi_pyframe <- function(x) {
  d=as.data.frame(x,check.names=FALSE); attr(d,"pandas.index")<-NULL; rownames(d)<-NULL; d
}

.bi_oa_cache_path <- function(start_year,end_year) {
  d=tools::R_user_dir("biblioIntegrator","cache"); dir.create(d,recursive=TRUE,showWarnings=FALSE)
  file.path(d,sprintf("oa_years_%d_%d.csv",as.integer(start_year),as.integer(end_year)))
}

#' Representativeness against the OpenAlex benchmark with Biblium 2.16
#'
#' Compares the corpus year distribution to global OpenAlex counts through
#' percentage-point differences (`compute_relative_representation()`). The
#' reference is cached on disk; only a cache miss reaches the network.
#' @param x A `biblio_project`.
#' @param category Currently only `"year"` (works carry year; country, doctype
#'   and OA status need per-work enrichment).
#' @param threshold Absolute pp difference classified as over/under-represented.
#' @param reference Optional data frame with `Year` and `Count` used instead of
#'   the live OpenAlex benchmark (offline testing).
#' @param use_cache Logical: reuse the on-disk OpenAlex reference.
#' @param python Optional Python executable.
#' @return A `biblio_representation` list with engine, table and cache flag.
#' @export
#' @examples
#' \dontrun{
#' x <- as_biblio_project(example_biblio())
#' biblium_representativeness(x)
#' }
biblium_representativeness <- function(x,category="year",threshold=1.0,reference=NULL,use_cache=TRUE,python=NULL) {
  if(!identical(category,"year")) stop("Only category=\"year\" is supported yet: works carry year; country/doctype/OA need per-work enrichment.",call.=FALSE)
  x=as_biblio_project(x); yr=x$works$year; yr=yr[!is.na(yr)]; if(!length(yr)) stop("No years available in works.",call.=FALSE)
  tab=as.data.frame(table(yr),stringsAsFactors=FALSE,check.names=FALSE); names(tab)=c("Year","Count"); tab$Year=as.integer(tab$Year); tab$Count=as.numeric(tab$Count)
  rng=range(tab$Year); cached=FALSE; ref=reference
  if(is.null(ref)) {
    cp=.bi_oa_cache_path(rng[1],rng[2])
    if(isTRUE(use_cache)&&.bi_cache_on()&&file.exists(cp)) { ref=utils::read.csv(cp,check.names=FALSE); cached=TRUE }
  }
  args=list(as.integer(tab$Year),tab$Count,as.integer(rng[1]),as.integer(rng[2]),as.numeric(threshold))
  if(!is.null(ref)) args=c(args,list(as.integer(ref$Year),as.numeric(ref$Count)))
  ans=.bi_bridge_call("representation_year",args,python=python)
  if(is.null(ref)&&.bi_cache_on()) { utils::write.csv(.bi_pyframe(ans$reference),.bi_oa_cache_path(rng[1],rng[2]),row.names=FALSE); cached=FALSE }
  structure(list(engine="biblium",category="year",years=rng,threshold=as.numeric(threshold),
    table=.bi_pyframe(ans$table),cached=cached),class="biblio_representation")
}

#' Compare group means with Biblium 2.16
#'
#' Compares a numeric work metric across groups with automatic test selection
#' (t/Welch/Mann-Whitney for two groups; ANOVA/Welch-ANOVA/Kruskal-Wallis plus
#' post-hoc for three or more), normality and homogeneity checks, and effect
#' sizes (Cohen's d / eta squared).
#' @param x A `biblio_project`.
#' @param metric `"citations"`, `"velocity"` or `"year"`.
#' @param groups A single categorical grouping (vector, factor or function of
#'   `x$works`); multi-column membership matrices are refused.
#' @param alpha Significance level.
#' @param python Optional Python executable.
#' @return A `biblio_means_comparison` list with engine, descriptives, tests,
#'   post-hoc, recommended test and interpretation.
#' @export
#' @examples
#' \dontrun{
#' x <- as_biblio_project(example_biblio())
#' biblium_compare_means(x,groups=ifelse(x$works$year<2022,"early","late"))
#' biblium_compare_means(x,metric="velocity",groups=x$works$source)
#' }
biblium_compare_means <- function(x,metric=c("citations","velocity","year"),groups,alpha=0.05,python=NULL) {
  metric=match.arg(metric); x=as_biblio_project(x)
  if(is.function(groups)) groups=groups(x$works)
  if(is.matrix(groups)||is.data.frame(groups)) {
    if(ncol(groups)!=1L) stop("`groups` must be a single categorical variable for means comparison; multi-column membership is not supported.",call.=FALSE)
    groups=groups[,1L]
  }
  g=as.character(groups); if(length(g)!=nrow(x$works)) stop("Group vector must have one entry per work.",call.=FALSE)
  v=switch(metric,citations=x$works$cited_by_count,velocity={cv=citation_velocity(x); cv$velocity[match(x$works$work_id,cv$work_id)]},year=x$works$year)
  ok=stats::complete.cases(v,g); v=v[ok]; g=g[ok]
  if(length(unique(g))<2L) stop("At least two groups with data are required.",call.=FALSE)
  ans=.bi_bridge_call("compare_means",list(as.numeric(v),g,as.numeric(alpha)),python=python)
  structure(list(engine="biblium",metric=metric,alpha=as.numeric(alpha),
    n_groups=as.integer(ans$n_groups),n_total=as.integer(ans$n_total),
    recommended_test=ans$recommended_test,interpretation=ans$interpretation,
    assumptions_met=isTRUE(ans$assumptions_met),
    descriptives=.bi_pyframe(ans$descriptives),normality=.bi_pyframe(ans$normality),
    homogeneity=ans$homogeneity,tests=.bi_pyframe(ans$tests),
    post_hoc_method=ans$post_hoc_method,
    posthoc=if(is.null(ans$posthoc)||!NROW(ans$posthoc))NULL else .bi_pyframe(ans$posthoc)),
    class="biblio_means_comparison")
}

#' Cross-validate native and Biblium disruption indices
#'
#' Same CD formula both sides (`(N_i - N_j)/(N_i + N_j + N_k)`); the comparison
#' must agree to machine precision, as in [validate_biblium()].
#' @param x A `biblio_project` with references.
#' @param focal_ids Focal work IDs (default: cited works with references).
#' @param python Optional Python executable.
#' @return A list with comparison data frame and both fitted tables.
#' @export
#' @examples
#' \dontrun{
#' x <- as_biblio_project(example_biblio())
#' validate_disruption(x)
#' }
validate_disruption <- function(x,focal_ids=NULL,python=NULL) {
  x=as_biblio_project(x); ref=x$references
  if(!nrow(ref)||!all(c("citing_id","cited_id")%in%names(ref))) stop("Disruption needs references (x$references with citing_id/cited_id).",call.=FALSE)
  if(is.null(focal_ids)) focal_ids=unique(ref$cited_id)
  refs_of=lapply(focal_ids,function(f)unique(ref$cited_id[ref$citing_id==f]))
  nat=do.call(rbind,lapply(seq_along(focal_ids),function(i) {
    suppressWarnings(disruption_index(focal_ids[i],ref,refs_of[[i]]))
  }))
  ans=.bi_bridge_call("disruption",list(ref$citing_id,ref$cited_id,as.list(focal_ids),lapply(refs_of,as.list)),python=python)
  bib=.bi_pyframe(ans$table)
  cmp=data.frame(focal_id=focal_ids,native=nat$disruption,biblium=bib$disruption[match(focal_ids,bib$focal_id)],
    difference=nat$disruption-bib$disruption[match(focal_ids,bib$focal_id)],check.names=FALSE)
  list(comparison=cmp,native=nat,biblium=bib)
}

#' SDG classification with Biblium 2.16
#'
#' Query-based matching (Scopus SDG queries) over titles or abstracts; returns
#' binary SDG01-SDG17 flags per work.
#' @param x A `biblio_project`.
#' @param text `"abstract"` or `"title"`.
#' @param python Optional Python executable.
#' @return A `biblio_sdg` list with engine and flags data frame.
#' @export
#' @examples
#' \dontrun{
#' x <- as_biblio_project(example_biblio())
#' biblium_sdg(x,text="title")
#' }
biblium_sdg <- function(x,text=c("abstract","title"),python=NULL) {
  text=match.arg(text); x=as_biblio_project(x); w=x$works
  txt=as.character(w[[text]]); if(!any(nzchar(trimws(txt)))) { warning("Field '",text,"' is empty: all SDG flags will be zero.",call.=FALSE); txt=rep("",nrow(w)) }
  ans=.bi_bridge_call("sdg_labels",list(w$title,if(text=="abstract")txt else w$title,text),python=python)
  sdg=.bi_pyframe(ans$sdg)
  structure(list(engine="biblium",text=text,flags=data.frame(work_id=w$work_id,sdg,check.names=FALSE),
    n_hits=sum(sdg$n_sdgs)),class="biblio_sdg")
}

#' Group classification with Biblium 2.16
#'
#' Trains TF-IDF + scikit-learn classifiers per group (cross-validation) and
#' reports accuracy/AUC/precision/recall/F1: a direct answer to whether groups
#' are separable by vocabulary.
#' @param x A `biblio_project`.
#' @param groups Group definition accepted by [form_groups()].
#' @param python Optional Python executable.
#' @return A `biblio_group_classification` list with the performance table.
#' @export
#' @examples
#' \dontrun{
#' x <- as_biblio_project(example_biblio())
#' biblium_classify_groups(x,ifelse(x$works$year<2022,"early","late"))
#' }
biblium_classify_groups <- function(x,groups,python=NULL) {
  x=as_biblio_project(x); G=as.data.frame(form_groups(x,groups),check.names=FALSE)
  if(any(colSums(G)<2L)) stop("Each group needs at least two works for cross-validation.",call.=FALSE)
  ans=.bi_bridge_call("classify_groups",list(to_biblium(x),G),python=python)
  structure(list(engine="biblium",performance=.bi_pyframe(ans$performance)),class="biblio_group_classification")
}

#' Topic models with Biblium 2.16 (tier-2 backend)
#'
#' LDA/NMF over titles or abstracts via scikit-learn (no transformer stack
#' needed). Tier-2: documented and tested, but outside the default plan blocks.
#' @param x A `biblio_project`.
#' @param field `"title"` or `"abstract"`.
#' @param model `"LDA"` or `"NMF"`.
#' @param n_topics Fixed topic count (`NULL` = automatic up to `max_topics`).
#' @param max_topics Cap for automatic selection.
#' @param python Optional Python executable.
#' @return A `biblio_topics` list with the topics frame and term/coherence summary.
#' @export
#' @examples
#' \dontrun{
#' x <- as_biblio_project(example_biblio())
#' biblium_topics(x,n_topics=2)
#' }
biblium_topics <- function(x,field=c("title","abstract"),model=c("LDA","NMF"),n_topics=NULL,max_topics=10L,python=NULL) {
  field=match.arg(field); model=match.arg(model); x=as_biblio_project(x)
  txt=as.character(x$works[[field]]); txt=txt[nzchar(trimws(txt))]
  if(length(txt)<4L) stop("At least four non-empty texts are required.",call.=FALSE)
  args=list(txt,if(is.null(n_topics))NULL else as.integer(n_topics),as.integer(max_topics),model)
  ans=.bi_bridge_call("topic_models",args,python=python)
  structure(list(engine="biblium",field=field,model=model,
    topics=.bi_pyframe(ans$topics),weights=.bi_pyframe(ans$weights),summary=.bi_pyframe(ans$summary)),class="biblio_topics")
}

#' Main path analysis with Biblium 2.16
#'
#' Traversal-weight (SPC/SPLC/SPNP) main paths over the citation network:
#' global, forward and backward paths plus key routes. Edges flow cited ->
#' citing as required by `compute_main_path_analysis()`.
#' @param x A `biblio_project` with references.
#' @param method `"SPC"`, `"SPLC"` or `"SPNP"`.
#' @param python Optional Python executable.
#' @return A `biblio_main_path` list with engine, paths, weights and documents.
#' @export
#' @examples
#' \dontrun{
#' x <- as_biblio_project(example_biblio())
#' biblium_main_path(x)
#' }
biblium_main_path <- function(x,method=c("SPC","SPLC","SPNP"),python=NULL) {
  method=match.arg(method); x=as_biblio_project(x)
  e=.bi_edges_native(x,"citation")
  if(!nrow(e)) stop("No citation edges: main path needs references (x$references with citing_id/cited_id).",call.=FALSE)
  e=e[!duplicated(e[,c("from","to")]),,drop=FALSE]
  w=x$works; docs=data.frame(work_id=w$work_id,year=w$year,title=w$title,stringsAsFactors=FALSE)
  ans=.bi_bridge_call("main_path",list(e$to,e$from,docs$work_id,docs$year,docs$title,method),python=python)
  structure(list(engine="biblium",method=method,
    n_nodes=as.integer(ans$n_nodes),n_edges=as.integer(ans$n_edges),
    n_sources=as.integer(ans$n_sources),n_sinks=as.integer(ans$n_sinks),
    global_main_path=as.character(ans$global_main_path),
    forward_main_path=as.character(ans$forward_main_path),
    backward_main_path=as.character(ans$backward_main_path),
    key_routes=as.character(ans$key_routes),path_length=as.integer(ans$path_length),
    path_documents=if(is.null(ans$path_documents)||!NROW(ans$path_documents))NULL else .bi_pyframe(ans$path_documents),
    edge_weights=.bi_pyframe(ans$edge_weights),node_weights=.bi_pyframe(ans$node_weights),
    statistics=ans$statistics),class="biblio_main_path")
}

# Tabelas de contingencia do Biblium trazem linha/coluna "Total": os rotulos
# vem na primeira coluna (indice resetado na ponte) e as margens sao removidas.
.bi_table_labels <- function(d) {
  d=.bi_pyframe(d); if(ncol(d)<2L) return(d)
  rn=as.character(d[[1L]]); d=d[,-1L,drop=FALSE]; rownames(d)=rn
  if("Total"%in%rn) d=d[rn!="Total",,drop=FALSE]
  cn=colnames(d); if("Total"%in%cn) d=d[,cn!="Total",drop=FALSE]
  d
}

.bi_categorical <- function(x, v, what) {
  if(length(v)==1L&&is.character(v)&&v%in%names(x$works)) return(as.character(x$works[[v]]))
  v=as.character(v); if(length(v)!=nrow(x$works)) stop("`",what,"` must be a works column name or a vector with one entry per work.",call.=FALSE)
  v
}

#' Cross-tabulation with Biblium 2.16
#'
#' Chi-squared (with assumption diagnostics), Fisher exact for 2x2 tables,
#' effect sizes (Cramer's V, phi, contingency coefficient) and interpretation.
#' @param x A `biblio_project`.
#' @param row,col Works column names or vectors with one entry per work.
#' @param alpha Significance level.
#' @param python Optional Python executable.
#' @return A `biblio_crosstab` list with tables, tests and interpretation.
#' @export
#' @examples
#' \dontrun{
#' x <- as_biblio_project(example_biblio())
#' biblium_crosstab(x,"source",ifelse(x$works$year<2022,"early","late"))
#' }
biblium_crosstab <- function(x,row,col,alpha=0.05,python=NULL) {
  x=as_biblio_project(x); r=.bi_categorical(x,row,"row"); c=.bi_categorical(x,col,"col")
  ans=.bi_bridge_call("crosstab",list(r,c,as.numeric(alpha)),python=python)
  structure(list(engine="biblium",n_rows=as.integer(ans$n_rows),n_cols=as.integer(ans$n_cols),
    n_total=as.integer(ans$n_total),is_2x2=isTRUE(ans$is_2x2),
    observed=.bi_table_labels(ans$observed),expected=.bi_table_labels(ans$expected),
    residuals=.bi_table_labels(ans$residuals),chi_squared=ans$chi_squared,
    fisher=ans$fisher,effect_size=ans$effect_size,interpretation=ans$interpretation),
    class="biblio_crosstab")
}

#' Correlation matrix with Biblium 2.16
#'
#' Pearson/Spearman/Kendall correlations among work metrics with p-values.
#' @param x A `biblio_project`.
#' @param vars Metrics among `"citations"`, `"velocity"` and `"year"`.
#' @param method `"pearson"`, `"spearman"` or `"kendall"`.
#' @param alpha Significance level.
#' @param python Optional Python executable.
#' @return A `biblio_correlation` list with matrices and pairs.
#' @export
#' @examples
#' \dontrun{
#' x <- as_biblio_project(example_biblio())
#' biblium_correlate(x)
#' }
biblium_correlate <- function(x,vars=c("citations","velocity","year"),method=c("pearson","spearman","kendall"),alpha=0.05,python=NULL) {
  x=as_biblio_project(x); method=match.arg(method)
  getm <- function(v) switch(v,citations=x$works$cited_by_count,velocity={cv=citation_velocity(x); cv$velocity[match(x$works$work_id,cv$work_id)]},year=x$works$year)
  mm=unique(vars); if(length(mm)<2L) stop("At least two metrics are required.",call.=FALSE)
  cols=lapply(mm,getm); ok=stats::complete.cases(as.data.frame(cols)); cols=lapply(cols,function(z)z[ok])
  ans=.bi_bridge_call("correlate",list(lapply(cols,as.numeric),as.list(mm),method,as.numeric(alpha)),python=python)
  cm=.bi_pyframe(ans$corr_matrix); rownames(cm)=colnames(cm)
  pm=.bi_pyframe(ans$p_matrix); rownames(pm)=colnames(pm)
  structure(list(engine="biblium",method=ans$method,n_significant=as.integer(ans$n_significant),
    n_total_pairs=as.integer(ans$n_total_pairs),corr_matrix=cm,p_matrix=pm,
    pairs=if(is.null(ans$pairs)||!NROW(ans$pairs))NULL else .bi_pyframe(ans$pairs)),
    class="biblio_correlation")
}

#' Citation pattern classification with Biblium 2.16
#'
#' Classifies trajectories (Evergreen, Flash-in-the-pan, Delayed Recognition,
#' Sleeping Beauty, Normal, Uncited, Too Recent) from OpenAlex yearly histories
#' or, offline, from estimated patterns.
#' @param x A `biblio_project`.
#' @param source `"estimated"` (offline) or `"openalex"` (live histories).
#' @param max_papers Maximum papers sent to the classifier.
#' @param min_age Minimum work age in years.
#' @param python Optional Python executable.
#' @return A `biblio_citation_patterns` list with trajectories and summary.
#' @export
#' @examples
#' \dontrun{
#' x <- as_biblio_project(example_biblio())
#' biblium_citation_patterns(x)
#' }
biblium_citation_patterns <- function(x,source=c("estimated","openalex"),max_papers=500L,min_age=3L,python=NULL) {
  source=match.arg(source); x=as_biblio_project(x); w=x$works
  ans=.bi_bridge_call("citation_patterns",
    list(w$title,w$year,w$cited_by_count,w$doi,identical(source,"openalex"),as.integer(max_papers),as.integer(min_age)),python=python)
  structure(list(engine="biblium",data_source=ans$data_source,
    n_papers=as.integer(ans$n_papers),n_analyzed=as.integer(ans$n_analyzed),
    trajectories=.bi_pyframe(ans$trajectories),summary=.bi_pyframe(ans$summary)),
    class="biblio_citation_patterns")
}
