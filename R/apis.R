#' Fetch works from OpenAlex
#' @param query Search string.
#' @param n Maximum records requested.
#' @param mailto Optional contact email for polite API use.
#' @return A `biblio_project`.
#' @export
#' @examples
#' \dontrun{
#' fetch_openalex("silicon salinity plants",n=10)
#' fetch_openalex("soil carbon cover crops",n=5)
#' x <- fetch_openalex("soybean remote sensing",n=3); x$works
#' }
fetch_openalex <- function(query,n=25,mailto=NULL) {
  # validacao de entrada: n = 0 chegava a API e voltava HTTP 400, e consulta vazia
  # devolvia 25 obras do acervo inteiro sem aviso
  if (!is.character(query) || length(query) != 1L || !nzchar(trimws(query)))
    stop("`query` must be a non-empty search string.", call.=FALSE)
  if (!is.numeric(n) || length(n) != 1L || is.na(n) || n < 1)
    stop("`n` must be a positive number of records.", call.=FALSE)
  n <- as.integer(n)
  req=httr2::request("https://api.openalex.org/works") |> httr2::req_url_query(search=query,per_page=min(n,200)); if(!is.null(mailto))req=httr2::req_url_query(req,mailto=mailto)
  js=httr2::resp_body_json(httr2::req_perform(req),simplifyVector=FALSE); z=js$results[seq_len(min(n,length(js$results)))]; if(!length(z))return(as_biblio_project(data.frame()))
  d=do.call(rbind,lapply(z,function(a)data.frame(work_id=a$id,title=a$title %||% "",year=a$publication_year %||% NA,doi=a$doi %||% "",authors=paste(vapply(a$authorships,function(q)q$author$display_name %||% "",character(1)),collapse=";"),keywords=paste(vapply(a$keywords %||% list(),function(q)q$display_name %||% "",character(1)),collapse=";"),citations=a$cited_by_count %||% 0,source=if(!is.null(a$primary_location$source))a$primary_location$source$display_name %||% "" else "",stringsAsFactors=FALSE)))
  as_biblio_project(d,source="OpenAlex")
}
`%||%` <- function(x,y) if(is.null(x)||length(x)==0) y else x

#' Normaliza um identificador para o PID exigido pela API do OpenCitations
#'
#' A API v2 espera o PID completo (`doi:10.xxxx/...`). Um DOI nu era recusado com
#' HTTP 400; a funcao acrescenta o prefixo e remove URLs do doi.org.
#' @param identifier Identificador informado pelo usuario.
#' @return Identificador no formato `doi:...`.
#' @noRd
.oc_pid <- function(identifier) {
  id=trimws(as.character(identifier)[1]); if(is.na(id)||!nzchar(id)) stop("identifier is empty.",call.=FALSE)
  id=sub("^https?://(dx\\.)?doi\\.org/","",id); if(!grepl(":",id,fixed=TRUE)) id=paste0("doi:",id)
  utils::URLencode(id,reserved=FALSE)
}

#' Fetch OpenCitations Index relations
#' @param identifier DOI or supported persistent identifier.
#' @param direction `"citations"` or `"references"`.
#' @return A data frame returned by the OpenCitations API.
#' @export
#' @examples
#' \dontrun{
#' fetch_opencitations("10.1038/nature12373")
#' fetch_opencitations("10.1038/nature12373",direction="references")
#' head(fetch_opencitations("10.1038/nature12373"))
#' }
fetch_opencitations <- function(identifier,direction=c("citations","references")) {
  direction=match.arg(direction); id=.oc_pid(identifier); u=paste0("https://api.opencitations.net/index/v2/",direction,"/",id); r=httr2::req_perform(httr2::request(u)); as.data.frame(httr2::resp_body_json(r,simplifyVector=TRUE),stringsAsFactors=FALSE)
}
