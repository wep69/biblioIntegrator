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
  req=httr2::request("https://api.openalex.org/works") |> httr2::req_url_query(search=query,per_page=min(n,200)); if(!is.null(mailto))req=httr2::req_url_query(req,mailto=mailto)
  js=httr2::resp_body_json(httr2::req_perform(req),simplifyVector=FALSE); z=js$results[seq_len(min(n,length(js$results)))]; if(!length(z))return(as_biblio_project(data.frame()))
  d=do.call(rbind,lapply(z,function(a)data.frame(work_id=a$id,title=a$title %||% "",year=a$publication_year %||% NA,doi=a$doi %||% "",authors=paste(vapply(a$authorships,function(q)q$author$display_name %||% "",character(1)),collapse=";"),keywords=paste(vapply(a$keywords %||% list(),function(q)q$display_name %||% "",character(1)),collapse=";"),citations=a$cited_by_count %||% 0,source=if(!is.null(a$primary_location$source))a$primary_location$source$display_name %||% "" else "",stringsAsFactors=FALSE)))
  as_biblio_project(d,source="OpenAlex")
}
`%||%` <- function(x,y) if(is.null(x)||length(x)==0) y else x

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
  direction=match.arg(direction); id=utils::URLencode(identifier,reserved=TRUE); u=paste0("https://api.opencitations.net/index/v2/",direction,"/",id); r=httr2::req_perform(httr2::request(u)); as.data.frame(httr2::resp_body_json(r,simplifyVector=TRUE),stringsAsFactors=FALSE)
}
