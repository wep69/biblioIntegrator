# Internal helpers ---------------------------------------------------------
.bi_norm_doi <- function(x) {
  x <- tolower(trimws(as.character(x)))
  x <- sub("^https?://(dx\\.)?doi\\.org/", "", x)
  x <- sub("^doi:\\s*", "", x)
  x[is.na(x)] <- ""
  x
}
.bi_id <- function(prefix, x) {
  x <- as.character(x); x[is.na(x)] <- ""
  vapply(x, function(z) paste0(prefix, sprintf("%08x", abs(sum(utf8ToInt(z) * seq_along(utf8ToInt(z)))) %% .Machine$integer.max)), character(1))
}
.bi_split <- function(x) {
  if (length(x) == 0L || is.na(x) || !nzchar(trimws(x))) return(character())
  y <- trimws(unlist(strsplit(as.character(x), "[;|]")))
  unique(y[nzchar(y)])
}
.bi_cols <- function(d, candidates, default = NA_character_) {
  hit <- candidates[candidates %in% tolower(names(d))][1]
  if (is.na(hit)) return(rep(default, nrow(d)))
  d[[which(tolower(names(d)) == hit)[1]]]
}
.bi_project <- function(works, authorships=data.frame(), authors=data.frame(), keywords=data.frame(), references=data.frame(), provenance=data.frame()) {
  structure(list(works=works, authorships=authorships, authors=authors, keywords=keywords,
                 references=references, provenance=provenance), class="biblio_project")
}
.bi_add_provenance <- function(x, operation, details="") {
  row <- data.frame(timestamp=as.character(Sys.time()), operation=operation, details=as.character(details), stringsAsFactors=FALSE)
  x$provenance <- if (nrow(x$provenance)) rbind(x$provenance,row) else row
  x
}
.bi_membership <- function(groups, n) {
  if (is.factor(groups) || is.character(groups)) return(stats::model.matrix(~0+factor(groups)))
  if (is.data.frame(groups) || is.matrix(groups)) {
    m <- as.matrix(groups); storage.mode(m) <- "numeric"; return((m>0)*1)
  }
  stop("`groups` must be a factor/character vector or a membership matrix.", call.=FALSE)
}
.bi_entity_matrix <- function(x, entity=c("keyword","author")) {
  entity <- match.arg(entity); n <- nrow(x$works); ids <- x$works$work_id
  tab <- if (entity=="keyword") x$keywords else x$authorships
  nm <- if (entity=="keyword") "keyword" else "author_id"
  if (!nrow(tab)) return(matrix(0,n,0,dimnames=list(ids,character())))
  vals <- sort(unique(as.character(tab[[nm]])))
  m <- matrix(0,n,length(vals),dimnames=list(ids,vals)); ii <- match(tab$work_id,ids); jj <- match(tab[[nm]],vals)
  ok <- !is.na(ii)&!is.na(jj); m[cbind(ii[ok],jj[ok])] <- 1; m
}

#' Example bibliographic corpus
#'
#' Returns a small agronomy-oriented corpus used in examples and tests.
#' @return A data frame.
#' @export
#' @examples
#' d <- example_biblio(); head(d)
#' nrow(example_biblio())
#' names(example_biblio())
example_biblio <- function() {
  data.frame(
    title=c("Silicon and salinity tolerance in rice","Soil carbon under cover crops","Remote sensing of soybean nitrogen","Silicon nutrition in maize drought","Cover crops and soil aggregation","Machine learning for crop yield","Salinity responses of wheat","Soil microbiome under rotation","UAV phenotyping of soybean","Meta-analysis of silicon stress","Nitrogen use efficiency in maize","Climate-smart soil management"),
    year=c(2018,2019,2020,2021,2022,2023,2017,2020,2024,2025,2022,2024),
    doi=paste0("10.1000/agri.",1:12),
    authors=c("Silva A; Pereira W","Martins B; Costa C","Lima D; Pereira W","Silva A; Gomez E","Martins B; Lima D","Costa C; Rao F","Gomez E; Silva A","Rao F; Martins B","Lima D; Costa C","Pereira W; Silva A","Rao F; Gomez E","Martins B; Pereira W"),
    keywords=c("silicon; salinity; rice","soil carbon; cover crops","remote sensing; soybean; nitrogen","silicon; drought; maize","cover crops; aggregation; soil","machine learning; yield","salinity; wheat","soil microbiome; rotation","UAV; soybean; phenotyping","silicon; meta-analysis; stress","nitrogen; maize; efficiency","climate-smart; soil; management"),
    citations=c(42,35,28,31,22,18,55,26,12,9,17,14),
    source=c("Field Crops","Soil Science","Remote Sensing","Plant Nutrition","Soil Science","Agricultural Systems","Plant Stress","Soil Biology","Precision Agriculture","Agronomy Reviews","Crop Science","Sustainable Agriculture"), stringsAsFactors=FALSE)
}

#' Construct a bibliometric project
#'
#' Harmonizes a bibliographic data frame into relational tables while retaining provenance.
#' @param x Data frame or existing `biblio_project`.
#' @param source Source label recorded in provenance.
#' @return A `biblio_project`.
#' @export
#' @examples
#' x <- as_biblio_project(example_biblio())
#' x2 <- as_biblio_project(head(example_biblio(), 5), source="demo")
#' inherits(as_biblio_project(x), "biblio_project")
as_biblio_project <- function(x, source="user") {
  if (inherits(x,"biblio_project")) return(x)
  if (!is.data.frame(x)) stop("`x` must be a data frame or biblio_project.", call.=FALSE)
  title <- as.character(.bi_cols(x,c("title","ti"),"")); year <- suppressWarnings(as.integer(.bi_cols(x,c("year","py"),NA_integer_)))
  doi <- .bi_norm_doi(.bi_cols(x,c("doi","di"),"")); wid <- as.character(.bi_cols(x,c("work_id","id","eid"),""))
  miss <- is.na(wid)|!nzchar(wid); wid[miss] <- .bi_id("W",paste(title[miss],year[miss],doi[miss]))
  works <- data.frame(work_id=wid,title=title,year=year,doi=doi,source=as.character(.bi_cols(x,c("source","journal","so","source_title"),"")),
                      cited_by_count=suppressWarnings(as.numeric(.bi_cols(x,c("cited_by_count","citations","tc"),0))), abstract=as.character(.bi_cols(x,c("abstract","ab"),"")), stringsAsFactors=FALSE)
  ar <- as.character(.bi_cols(x,c("authors","author","au"),"")); auth=list(); aut=list()
  for(i in seq_len(nrow(x))) { a <- .bi_split(ar[i]); if(length(a)){ aid=.bi_id("A",a); auth[[length(auth)+1L]]=data.frame(work_id=wid[i],author_id=aid,stringsAsFactors=FALSE); aut[[length(aut)+1L]]=data.frame(author_id=aid,display_name=a,stringsAsFactors=FALSE)}}
  authorships <- if(length(auth)) unique(do.call(rbind,auth)) else data.frame(work_id=character(),author_id=character())
  authors <- if(length(aut)) unique(do.call(rbind,aut)) else data.frame(author_id=character(),display_name=character())
  kr <- as.character(.bi_cols(x,c("keywords","de","author_keywords"),"")); kw=list()
  for(i in seq_len(nrow(x))) { k=.bi_split(kr[i]); if(length(k)) kw[[length(kw)+1L]]=data.frame(work_id=wid[i],keyword=tolower(k),stringsAsFactors=FALSE) }
  keywords <- if(length(kw)) unique(do.call(rbind,kw)) else data.frame(work_id=character(),keyword=character())
  p <- .bi_project(works,authorships,authors,keywords,data.frame(citing_id=character(),cited_id=character()),data.frame())
  .bi_add_provenance(p,"as_biblio_project",paste0("source=",source,"; n=",nrow(works)))
}

#' Print a bibliometric project
#' @param x A `biblio_project`.
#' @param ... Unused.
#' @return `x`, invisibly.
#' @export
print.biblio_project <- function(x, ...) { cat("<biblio_project>",nrow(x$works),"works;",nrow(x$authors),"authors;",nrow(x$keywords),"work-keyword links\n"); invisible(x) }

#' Inspect the provenance log
#' @param x A `biblio_project`.
#' @return A data frame.
#' @export
#' @examples
#' audit_biblio(as_biblio_project(example_biblio()))
#' nrow(audit_biblio(as_biblio_project(head(example_biblio()))))
#' names(audit_biblio(as_biblio_project(example_biblio())))
audit_biblio <- function(x) { stopifnot(inherits(x,"biblio_project")); x$provenance }

#' Import a bibliographic file
#' @param path CSV, TSV, JSON, RIS, BibTeX, or database export.
#' @param dbsource Optional source for `bibliometrix::convert2df()`.
#' @param format Optional format for `bibliometrix::convert2df()`.
#' @return A `biblio_project`.
#' @export
#' @examples
#' f <- tempfile(fileext = ".csv")
#' utils::write.csv(example_biblio(), f, row.names = FALSE)
#' biblio_import(f)
#' f2 <- tempfile(fileext=".json"); jsonlite::write_json(example_biblio(),f2); biblio_import(f2)
#' biblio_import(f, dbsource="auto")
biblio_import <- function(path, dbsource=NULL, format=NULL) {
  ext <- tolower(tools::file_ext(path))
  if(ext %in% c("csv","tsv")) d <- utils::read.table(path,header=TRUE,sep=if(ext=="tsv") "\t" else ",",quote='"',comment.char="",check.names=FALSE)
  else if(ext=="json") d <- as.data.frame(jsonlite::read_json(path,simplifyVector=TRUE))
  else if(requireNamespace("bibliometrix",quietly=TRUE)) {
    ds <- if(is.null(dbsource)||identical(dbsource,"auto")) "wos" else dbsource; fm <- if(is.null(format)) ext else format
    d <- bibliometrix::convert2df(path,dbsource=ds,format=fm)
  } else stop("For this file type install 'bibliometrix', or provide CSV/TSV/JSON.",call.=FALSE)
  as_biblio_project(d,source=basename(path))
}

#' Convert to bibliometrix field-tag data
#' @param x A `biblio_project`.
#' @return A data frame compatible with common `bibliometrix` workflows.
#' @export
#' @examples
#' to_bibliometrix(as_biblio_project(example_biblio()))
#' nrow(to_bibliometrix(as_biblio_project(head(example_biblio()))))
#' names(to_bibliometrix(as_biblio_project(example_biblio())))
to_bibliometrix <- function(x) {
  w=x$works; au=tapply(x$authors$display_name[match(x$authorships$author_id,x$authors$author_id)],x$authorships$work_id,paste,collapse=";")
  kw=tapply(x$keywords$keyword,x$keywords$work_id,paste,collapse=";")
  data.frame(TI=w$title,PY=w$year,DI=w$doi,SO=w$source,TC=w$cited_by_count,AU=unname(au[w$work_id]),DE=unname(kw[w$work_id]),stringsAsFactors=FALSE)
}

#' Diagnose corpus quality
#' @param x A `biblio_project`.
#' @return A data frame of checks and counts.
#' @export
#' @examples
#' biblio_health(as_biblio_project(example_biblio()))
#' biblio_health(as_biblio_project(head(example_biblio())))
#' subset(biblio_health(as_biblio_project(example_biblio())), n>0)
biblio_health <- function(x) {
  w=x$works; data.frame(check=c("missing_title","missing_year","missing_doi","duplicate_doi","duplicate_title_year","negative_citations"),
    n=c(sum(!nzchar(trimws(w$title))),sum(is.na(w$year)),sum(!nzchar(w$doi)),sum(duplicated(w$doi)&nzchar(w$doi)),sum(duplicated(paste(tolower(w$title),w$year))),sum(w$cited_by_count<0,na.rm=TRUE)),stringsAsFactors=FALSE)
}

#' Deduplicate bibliographic records
#' @param x A `biblio_project`.
#' @param method Matching hierarchy: DOI then normalized title-year.
#' @return A deduplicated `biblio_project` with a log attribute.
#' @export
#' @examples
#' x <- as_biblio_project(rbind(example_biblio(),example_biblio()[1,])); deduplicate_biblio(x)
#' nrow(deduplicate_biblio(x)$works)
#' attr(deduplicate_biblio(x),"dedup_log")
deduplicate_biblio <- function(x, method=c("doi_title_year")) {
  w=x$works; key=ifelse(nzchar(w$doi),paste0("doi:",w$doi),paste0("ty:",tolower(gsub("[^[:alnum:]]","",w$title)),":",w$year)); keep=!duplicated(key)
  removed=w[!keep,c("work_id","title","doi"),drop=FALSE]; ids=w$work_id[keep]
  x$works=w[keep,,drop=FALSE]; x$authorships=x$authorships[x$authorships$work_id%in%ids,,drop=FALSE]; x$keywords=x$keywords[x$keywords$work_id%in%ids,,drop=FALSE]
  x=.bi_add_provenance(x,"deduplicate_biblio",paste0("removed=",nrow(removed))); attr(x,"dedup_log")=removed; x
}

#' Compare coverage across bibliographic sources
#' @param ... Data frames or `biblio_project` objects.
#' @return A list with coverage and pairwise overlap.
#' @export
#' @examples
#' compare_sources(example_biblio(), head(example_biblio(),8))
#' compare_sources(as_biblio_project(example_biblio()), example_biblio()[5:12,])
#' compare_sources(A=example_biblio(), B=example_biblio()[1:6,])
compare_sources <- function(...) {
  z=list(...); if(is.null(names(z))||any(names(z)=="")) names(z)=paste0("source",seq_along(z))
  keys=lapply(z,function(a){ if(inherits(a,"biblio_project")) w=a$works else w=as_biblio_project(a)$works; ifelse(nzchar(w$doi),paste0("doi:",w$doi),paste0("ty:",tolower(w$title),":",w$year))})
  coverage=data.frame(source=names(keys),records=vapply(keys,length,integer(1)),unique=vapply(keys,function(k)sum(!duplicated(k)),integer(1)))
  cmb=utils::combn(seq_along(keys),2); overlap=if(ncol(cmb)) data.frame(source1=names(keys)[cmb[1,]],source2=names(keys)[cmb[2,]],intersection=vapply(seq_len(ncol(cmb)),function(i)length(intersect(keys[[cmb[1,i]]],keys[[cmb[2,i]]])),integer(1))) else data.frame()
  list(coverage=coverage,overlap=overlap)
}

#' Descriptive bibliometric summary
#' @param x A `biblio_project`.
#' @return A list of summary tables.
#' @export
#' @examples
#' describe_biblio(as_biblio_project(example_biblio()))
#' describe_biblio(as_biblio_project(head(example_biblio())))$annual
#' describe_biblio(as_biblio_project(example_biblio()))$top_sources
describe_biblio <- function(x) {
  w=x$works; annual=stats::aggregate(list(documents=w$work_id,citations=w$cited_by_count),list(year=w$year),function(v)if(is.character(v))length(v) else sum(v,na.rm=TRUE))
  top_sources=sort(table(w$source),decreasing=TRUE); top_keywords=sort(table(x$keywords$keyword),decreasing=TRUE)
  list(n_documents=nrow(w),years=range(w$year,na.rm=TRUE),total_citations=sum(w$cited_by_count,na.rm=TRUE),annual=annual,top_sources=top_sources,top_keywords=top_keywords)
}

#' Author-level bibliometric metrics
#' @param x A `biblio_project`.
#' @return Author publication, citation, h-index, g-index and m-index metrics.
#' @export
#' @examples
#' biblio_metrics(as_biblio_project(example_biblio()))
#' head(biblio_metrics(as_biblio_project(example_biblio())),3)
#' subset(biblio_metrics(as_biblio_project(example_biblio())), documents>=2)
biblio_metrics <- function(x) {
  a=merge(x$authorships,x$works[,c("work_id","year","cited_by_count")],by="work_id"); a=merge(a,x$authors,by="author_id"); sp=split(a,a$author_id)
  out=lapply(sp,function(d){ cits=sort(d$cited_by_count,decreasing=TRUE); h=max(c(0,which(cits>=seq_along(cits)))); g=max(c(0,which(cumsum(cits)>=seq_along(cits)^2))); yrs=max(d$year,na.rm=TRUE)-min(d$year,na.rm=TRUE)+1; data.frame(author=d$display_name[1],documents=nrow(d),citations=sum(cits),h_index=h,g_index=g,m_index=h/yrs)})
  do.call(rbind,out)
}

#' Field/year normalized citations
#' @param x A `biblio_project`.
#' @param strata Character columns in `works` defining comparable strata.
#' @return Work-level normalized citation scores.
#' @export
#' @examples
#' normalized_citations(as_biblio_project(example_biblio()))
#' head(normalized_citations(as_biblio_project(example_biblio())),4)
#' mean(normalized_citations(as_biblio_project(example_biblio()))$normalized,na.rm=TRUE)
normalized_citations <- function(x, strata="year") {
  w=x$works; g=interaction(w[,strata,drop=FALSE],drop=TRUE); mu=stats::ave(w$cited_by_count,g,FUN=function(z)mean(z,na.rm=TRUE)); data.frame(work_id=w$work_id,citations=w$cited_by_count,expected=mu,normalized=ifelse(mu>0,w$cited_by_count/mu,NA_real_))
}

#' Citation velocity
#' @param x A `biblio_project`.
#' @param current_year Reference year.
#' @return Work-level citations per year.
#' @export
#' @examples
#' citation_velocity(as_biblio_project(example_biblio()))
#' head(citation_velocity(as_biblio_project(example_biblio())),3)
#' summary(citation_velocity(as_biblio_project(example_biblio()))$velocity)
citation_velocity <- function(x,current_year=as.integer(format(Sys.Date(),"%Y"))) { w=x$works; age=pmax(1,current_year-w$year+1); data.frame(work_id=w$work_id,year=w$year,citations=w$cited_by_count,velocity=w$cited_by_count/age) }
