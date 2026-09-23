#' Enrich works with author countries from OpenAlex
#'
#' Looks up each DOI once (cached on disk) and records the authors' countries.
#' Prerequisite for [biblium_geo()]: the project carries no affiliation data.
#' @param x A `biblio_project`.
#' @param use_cache Logical: reuse the on-disk cache.
#' @param email Optional email for the OpenAlex polite pool.
#' @return The project with `works$country` added (`"; "`-joined, `NA` when unknown).
#' @export
#' @examples
#' \dontrun{
#' x <- as_biblio_project(example_biblio())
#' enrich_countries(x)
#' }
enrich_countries <- function(x,use_cache=TRUE,email=NULL) {
  x=as_biblio_project(x); w=x$works
  cp=file.path(tools::R_user_dir("biblioIntegrator","cache"),"oa_countries.csv")
  cache=if(isTRUE(use_cache)&&.bi_cache_on()&&file.exists(cp)) utils::read.csv(cp,check.names=FALSE) else data.frame(doi=character(),country=character(),check.names=FALSE)
  need=unique(stats::na.omit(w$doi))
  m=match(need,cache$doi); hit=!is.na(m)&!is.na(cache$country[m])&nzchar(cache$country[m]); need=need[!hit]
  for(d in need) {
    u=paste0("https://api.openalex.org/works/https://doi.org/",d)
    if(!is.null(email))u=paste0(u,"?mailto=",email)
    js=tryCatch(jsonlite::fromJSON(suppressWarnings(httr2::req_perform(httr2::request(u))|>httr2::resp_body_string())),error=function(e)NULL)
    co=NA_character_
    if(!is.null(js)&&!is.null(js$authorships)) {
      cc=unique(unlist(js$authorships$countries)); cc=cc[!is.na(cc)&nzchar(cc)]
      if(length(cc))co=paste(cc,collapse="; ")
    }
    cache=rbind(cache,data.frame(doi=d,country=co,check.names=FALSE))
  }
  if(length(need)&&.bi_cache_on())utils::write.csv(cache,cp,row.names=FALSE)
  x$works$country=cache$country[match(w$doi,cache$doi)]; x
}

#' Geographic analysis with Biblium 2.16
#'
#' Country output, collaborations and trends over enriched data. Requires
#' `works$country`: run [enrich_countries()] first.
#' @param x A `biblio_project` with `works$country`.
#' @param python Optional Python executable.
#' @return A `biblio_geo` list with the country table.
#' @export
#' @examples
#' \dontrun{
#' x <- as_biblio_project(example_biblio())
#' biblium_geo(x)
#' }
biblium_geo <- function(x,python=NULL) {
  x=as_biblio_project(x); w=x$works
  if(!"country"%in%names(w)||all(is.na(w$country))) stop("No country data: run enrich_countries() first.",call.=FALSE)
  tb=to_biblium(x)
  ans=.bi_bridge_call("geo_countries",list(tb$Title,tb$Year,w$cited_by_count,w$country,tb$`Author Keywords`,tb$Authors),python=python)
  structure(list(engine="biblium",n_countries=as.integer(ans$n_countries),
    table=.bi_pyframe(ans$table)),class="biblio_geo")
}
