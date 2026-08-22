#' Optional backend status
#'
#' @return A data frame indicating installed scalable backends.
#' @export
#' @examples
#' backend_status()
#' subset(backend_status(), available)
#' backend_status()$backend
backend_status <- function() {
  pk <- c("biblionetwork","arrow","duckdb","DBI","bibliometrix","openalexR")
  data.frame(backend=pk,available=vapply(pk,requireNamespace,logical(1),quietly=TRUE),stringsAsFactors=FALSE)
}

.bi_edges_native <- function(x,type) {
  if(type=="coauthor") {
    a=x$authorships; if(!nrow(a)) return(data.frame(from=character(),to=character(),weight=numeric()))
    z=split(a$author_id,a$work_id); out=lapply(z,function(v){v=unique(v); if(length(v)<2)return(NULL); c=utils::combn(v,2); data.frame(from=c[1,],to=c[2,],weight=1)})
  } else if(type=="keyword") {
    a=x$keywords; z=split(a$keyword,a$work_id); out=lapply(z,function(v){v=unique(v); if(length(v)<2)return(NULL); c=utils::combn(v,2); data.frame(from=c[1,],to=c[2,],weight=1)})
  } else if(type=="citation") {
    r=x$references; if(!all(c("citing_id","cited_id")%in%names(r))) return(data.frame(from=character(),to=character(),weight=numeric())); out=list(data.frame(from=r$citing_id,to=r$cited_id,weight=1))
  } else stop("Unsupported network type.",call.=FALSE)
  out=Filter(Negate(is.null),out); if(!length(out))return(data.frame(from=character(),to=character(),weight=numeric()))
  d=do.call(rbind,out); stats::aggregate(weight~from+to,d,sum)
}

#' Build a bibliographic network
#'
#' @param x A `biblio_project`.
#' @param type `"coauthor"`, `"keyword"`, or `"citation"`.
#' @param engine `"native"`, `"biblionetwork"`, or `"auto"`.
#' @param min_weight Minimum edge weight retained.
#' @param counting Counting scheme for biblionetwork coauthorship.
#' @return An igraph object with an `engine` attribute.
#' @export
#' @examples
#' x <- as_biblio_project(example_biblio()); bibliographic_network(x,"coauthor")
#' bibliographic_network(x,"keyword",min_weight=1)
#' if (requireNamespace("biblionetwork", quietly = TRUE)) {
#'   bibliographic_network(x, "coauthor", engine = "biblionetwork")
#' }
bibliographic_network <- function(x,type=c("coauthor","keyword","citation"),engine=c("auto","native","biblionetwork"),min_weight=1,counting=c("full_counting","fractional_counting","fractional_counting_refined")) {
  type=match.arg(type); engine=match.arg(engine); counting=match.arg(counting)
  use_bn=(engine=="biblionetwork" || (engine=="auto"&&type=="coauthor"&&requireNamespace("biblionetwork",quietly=TRUE)))
  if(use_bn && type!="coauthor") { if(engine=="biblionetwork") stop("The biblionetwork engine is currently exposed for coauthorship networks.",call.=FALSE); use_bn=FALSE }
  if(use_bn) {
    if(!requireNamespace("biblionetwork",quietly=TRUE)) stop("Install 'biblionetwork'.",call.=FALSE)
    dt=data.frame(author=x$authorships$author_id,article=x$authorships$work_id,stringsAsFactors=FALSE)
    e=as.data.frame(biblionetwork::coauth_network(dt,authors="author",articles="article",method=counting))[,c("from","to","weight"),drop=FALSE]; eng="biblionetwork"
  } else { e=.bi_edges_native(x,type); eng="native" }
  e=e[is.finite(e$weight)&e$weight>=min_weight,,drop=FALSE]
  g=igraph::graph_from_data_frame(e,directed=(type=="citation")); attr(g,"engine")=eng; g
}

#' Network centrality table
#' @param graph An igraph object.
#' @return A data frame of degree, strength, betweenness and PageRank.
#' @export
#' @examples
#' g <- bibliographic_network(as_biblio_project(example_biblio()),"coauthor"); network_centrality(g)
#' head(network_centrality(g),3)
#' network_centrality(bibliographic_network(as_biblio_project(example_biblio()),"keyword"))
network_centrality <- function(graph) {
  w=igraph::E(graph)$weight; if(is.null(w)) w=rep(1,igraph::ecount(graph))
  data.frame(node=igraph::V(graph)$name,degree=igraph::degree(graph),strength=igraph::strength(graph,weights=w),betweenness=igraph::betweenness(graph,weights=1/pmax(w,.Machine$double.eps),normalized=TRUE),pagerank=igraph::page_rank(graph,weights=w)$vector,stringsAsFactors=FALSE)
}

#' Detect network communities
#' @param graph Undirected igraph network.
#' @param method `"louvain"`, `"walktrap"`, or `"label_prop"`.
#' @return A data frame with node membership.
#' @export
#' @examples
#' g <- bibliographic_network(as_biblio_project(example_biblio()),"coauthor"); network_communities(g)
#' network_communities(g,"walktrap")
#' network_communities(g,"label_prop")
network_communities <- function(graph,method=c("louvain","walktrap","label_prop")) {
  method=match.arg(method); if(igraph::is_directed(graph)) graph=igraph::as_undirected(graph,mode="collapse",edge.attr.comb=list(weight="sum"))
  cl=switch(method,louvain=igraph::cluster_louvain(graph),walktrap=igraph::cluster_walktrap(graph),label_prop=igraph::cluster_label_prop(graph))
  data.frame(node=names(igraph::membership(cl)),community=as.integer(igraph::membership(cl)),stringsAsFactors=FALSE)
}

#' Bootstrap/subsampling stability of node centrality
#' @param x A `biblio_project`.
#' @param type Network type.
#' @param B Number of subsamples.
#' @param fraction Fraction of works retained per subsample.
#' @param seed Random seed.
#' @return Node-wise mean and SD of degree ranks.
#' @export
#' @examples
#' x <- as_biblio_project(example_biblio()); network_stability(x,B=10,seed=1)
#' network_stability(x,type="keyword",B=8,fraction=.8,seed=2)
#' head(network_stability(x,B=6,seed=3),3)
network_stability <- function(x,type=c("coauthor","keyword"),B=100,fraction=.8,seed=NULL) {
  type=match.arg(type); if(!is.null(seed))set.seed(seed); ids=x$works$work_id; keepn=max(2,floor(length(ids)*fraction)); ranks=list()
  for(b in seq_len(B)){ k=sample(ids,keepn); y=x; y$works=x$works[x$works$work_id%in%k,,drop=FALSE]; y$authorships=x$authorships[x$authorships$work_id%in%k,,drop=FALSE]; y$keywords=x$keywords[x$keywords$work_id%in%k,,drop=FALSE]; g=bibliographic_network(y,type,engine="native"); if(igraph::vcount(g)){ d=igraph::degree(g); ranks[[b]]=data.frame(node=names(d),rank=rank(-d,ties.method="average")) }}
  a=do.call(rbind,ranks); if(is.null(a))return(data.frame()); m=stats::aggregate(rank~node,a,function(z)c(mean=mean(z),sd=stats::sd(z),n=length(z))); data.frame(node=m$node,mean_rank=m$rank[,"mean"],sd_rank=m$rank[,"sd"],replicates=m$rank[,"n"],row.names=NULL)
}

#' Store a bibliometric project using Arrow or DuckDB
#' @param x A `biblio_project`.
#' @param path Directory (Arrow) or database file (DuckDB).
#' @param engine Storage engine.
#' @param overwrite Replace existing output.
#' @return Normalized output path, invisibly.
#' @export
#' @examples
#' \donttest{
#' x <- as_biblio_project(example_biblio())
#' if (requireNamespace("arrow", quietly = TRUE)) {
#'   p <- tempfile()
#'   biblio_store(x, p, "arrow")
#'   biblio_load(p, "arrow")
#' }
#' if (requireNamespace("duckdb", quietly = TRUE) &&
#'     requireNamespace("DBI", quietly = TRUE)) {
#'   p <- tempfile(fileext = ".duckdb")
#'   biblio_store(x, p, "duckdb")
#'   biblio_load(p, "duckdb")
#' }
#' if (requireNamespace("arrow", quietly = TRUE)) {
#'   p <- tempfile()
#'   biblio_store(x, p, "arrow", overwrite = TRUE)
#' }
#' }
biblio_store <- function(x,path,engine=c("arrow","duckdb"),overwrite=FALSE) {
  engine=match.arg(engine); tabs=c("works","authors","authorships","keywords","references","provenance")
  if(engine=="arrow") {
    if(!requireNamespace("arrow",quietly=TRUE)) stop("Install 'arrow'.",call.=FALSE); if(dir.exists(path)&&overwrite)unlink(path,recursive=TRUE); dir.create(path,recursive=TRUE,showWarnings=FALSE)
    for(n in tabs) arrow::write_parquet(x[[n]],file.path(path,paste0(n,".parquet")))
  } else {
    if(!requireNamespace("duckdb",quietly=TRUE)||!requireNamespace("DBI",quietly=TRUE)) stop("Install 'duckdb' and 'DBI'.",call.=FALSE); if(file.exists(path)&&overwrite)unlink(path)
    con=DBI::dbConnect(duckdb::duckdb(),dbdir=path); on.exit(DBI::dbDisconnect(con,shutdown=TRUE),add=TRUE); for(n in tabs)DBI::dbWriteTable(con,n,x[[n]],overwrite=TRUE)
  }
  invisible(normalizePath(path,winslash="/",mustWork=FALSE))
}

#' Load a stored bibliometric project
#' @param path Directory or DuckDB file.
#' @param engine Storage engine.
#' @return A `biblio_project`.
#' @export
#' @examples
#' \donttest{
#' x <- as_biblio_project(example_biblio())
#' if(requireNamespace("arrow",quietly=TRUE)){p<-tempfile();biblio_store(x,p);biblio_load(p)}
#' if (requireNamespace("duckdb", quietly = TRUE) &&
#'     requireNamespace("DBI", quietly = TRUE)) {
#'   p <- tempfile(fileext = ".duckdb")
#'   biblio_store(x, p, "duckdb")
#'   biblio_load(p, "duckdb")
#' }
#' if (requireNamespace("arrow", quietly = TRUE)) {
#'   p <- tempfile()
#'   biblio_store(x, p)
#'   nrow(biblio_load(p)$works)
#' }
#' }
biblio_load <- function(path,engine=c("arrow","duckdb")) {
  engine=match.arg(engine); tabs=c("works","authors","authorships","keywords","references","provenance"); z=list()
  if(engine=="arrow") { if(!requireNamespace("arrow",quietly=TRUE))stop("Install 'arrow'.",call.=FALSE); for(n in tabs)z[[n]]=as.data.frame(arrow::read_parquet(file.path(path,paste0(n,".parquet")))) }
  else { if(!requireNamespace("duckdb",quietly=TRUE)||!requireNamespace("DBI",quietly=TRUE))stop("Install 'duckdb' and 'DBI'.",call.=FALSE); con=DBI::dbConnect(duckdb::duckdb(),dbdir=path,read_only=TRUE); on.exit(DBI::dbDisconnect(con,shutdown=TRUE),add=TRUE); for(n in tabs)z[[n]]=DBI::dbReadTable(con,n) }
  structure(z,class="biblio_project")
}

#' Query a DuckDB bibliometric store
#' @param path DuckDB database file.
#' @param sql SQL query.
#' @return A data frame.
#' @export
#' @examples
#' \donttest{
#' if (requireNamespace("duckdb", quietly = TRUE) &&
#'     requireNamespace("DBI", quietly = TRUE)) {
#'   x <- as_biblio_project(example_biblio())
#'   p <- tempfile(fileext = ".duckdb")
#'   biblio_store(x, p, "duckdb")
#'   biblio_query(p, "SELECT year, COUNT(*) AS n FROM works GROUP BY year")
#' }
#' if (requireNamespace("duckdb", quietly = TRUE) &&
#'     requireNamespace("DBI", quietly = TRUE)) {
#'   x <- as_biblio_project(example_biblio())
#'   p <- tempfile(fileext = ".duckdb")
#'   biblio_store(x, p, "duckdb")
#'   biblio_query(p, "SELECT * FROM works LIMIT 2")
#' }
#' if (requireNamespace("duckdb", quietly = TRUE) &&
#'     requireNamespace("DBI", quietly = TRUE)) {
#'   x <- as_biblio_project(example_biblio())
#'   p <- tempfile(fileext = ".duckdb")
#'   biblio_store(x, p, "duckdb")
#'   nrow(biblio_query(p, "SELECT * FROM keywords"))
#' }
#' }
biblio_query <- function(path,sql) { if(!requireNamespace("duckdb",quietly=TRUE)||!requireNamespace("DBI",quietly=TRUE))stop("Install 'duckdb' and 'DBI'.",call.=FALSE); con=DBI::dbConnect(duckdb::duckdb(),dbdir=path,read_only=TRUE); on.exit(DBI::dbDisconnect(con,shutdown=TRUE),add=TRUE); DBI::dbGetQuery(con,sql) }
