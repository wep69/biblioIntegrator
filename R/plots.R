#' Annual production barplot (base graphics, no extra packages)
#' @param x A `biblio_project`.
#' @return The plotted data, invisibly.
#' @export
#' @examples
#' biblio_plot_annual(as_biblio_project(example_biblio()))
biblio_plot_annual <- function(x) {
  x=as_biblio_project(x); t=as.data.frame(table(x$works$year),stringsAsFactors=FALSE)
  names(t)=c("year","n"); graphics::barplot(stats::setNames(t$n,t$year),main="Annual production",xlab="Year",ylab="Works",col="steelblue"); invisible(t)
}

#' Top terms barplot
#' @param x A `biblio_project`.
#' @param top_n Number of terms.
#' @param field `"title"` or `"abstract"`.
#' @return The plotted data, invisibly.
#' @export
#' @examples
#' biblio_plot_terms(as_biblio_project(example_biblio()))
biblio_plot_terms <- function(x,top_n=15L,field=c("title","abstract")) {
  t=utils::head(term_frequency(x,field=match.arg(field)),as.integer(top_n)[1L])
  graphics::barplot(rev(stats::setNames(t$n,t$term)),horiz=TRUE,las=1,main="Top terms",xlab="Works",col="steelblue",cex.names=0.8); invisible(t)
}

#' Top sources barplot
#' @param x A `biblio_project`.
#' @param top_n Number of sources.
#' @return The plotted data, invisibly.
#' @export
#' @examples
#' biblio_plot_sources(as_biblio_project(example_biblio()))
biblio_plot_sources <- function(x,top_n=15L) {
  x=as_biblio_project(x); s=sort(table(x$works$source),decreasing=TRUE); s=utils::head(s,as.integer(top_n)[1L])
  graphics::barplot(rev(s),horiz=TRUE,las=1,main="Top sources",xlab="Works",col="steelblue",cex.names=0.8)
  invisible(data.frame(source=names(s),n=as.integer(s),row.names=NULL))
}

#' Citation distribution histogram
#' @param x A `biblio_project`.
#' @return The histogram object, invisibly.
#' @export
#' @examples
#' biblio_plot_citations(as_biblio_project(example_biblio()))
biblio_plot_citations <- function(x) {
  x=as_biblio_project(x); h=graphics::hist(x$works$cited_by_count,main="Citation distribution",xlab="Citations",col="steelblue"); invisible(h)
}
