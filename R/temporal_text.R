#' Annual bibliometric growth
#' @param x A `biblio_project`.
#' @return Annual documents, citations and year-over-year document growth.
#' @export
#' @examples
#' temporal_growth(as_biblio_project(example_biblio()))
#' tail(temporal_growth(as_biblio_project(example_biblio())),3)
#' summary(temporal_growth(as_biblio_project(example_biblio()))$documents)
temporal_growth <- function(x) {
  w=x$works; a=stats::aggregate(list(documents=w$work_id,citations=w$cited_by_count),list(year=w$year),function(z)if(is.character(z))length(z) else sum(z,na.rm=TRUE)); a=a[order(a$year),]; a$growth_pct=c(NA,100*diff(a$documents)/utils::head(a$documents,-1)); a
}

#' Topic trajectories by year
#' @param x A `biblio_project`.
#' @param min_total Minimum corpus-wide keyword frequency.
#' @return Long data frame of keyword counts by year.
#' @export
#' @examples
#' trend_topics(as_biblio_project(example_biblio()))
#' trend_topics(as_biblio_project(example_biblio()),min_total=2)
#' head(trend_topics(as_biblio_project(example_biblio())),4)
trend_topics <- function(x,min_total=1) {
  d=merge(x$keywords,x$works[,c("work_id","year")],by="work_id"); tot=table(d$keyword); d=d[d$keyword%in%names(tot)[tot>=min_total],]; stats::aggregate(list(n=d$work_id),list(year=d$year,keyword=d$keyword),length)
}

.bi_tokens <- function(text) {
  x=tolower(paste(text,collapse=" ")); x=gsub("[^[:alpha:][:digit:]'-]+"," ",x); z=unlist(strsplit(x,"\\s+")); z[nchar(z)>2]
}

#' N-gram frequency from titles or abstracts
#'
#' Native implementation; Biblium `extract_ngrams_tfidf()` can audit the
#' unigram counts through `term_frequency()`.
#' @param x A `biblio_project`.
#' @param n N-gram order (1 = unigrams).
#' @param field `"title"` or `"abstract"`.
#' @param stopwords Added to the default list, as in [term_frequency()].
#' @param min_freq Minimum corpus frequency.
#' @return Data frame with ngram and n.
#' @export
#' @examples
#' concept_ngrams(as_biblio_project(example_biblio()))
#' concept_ngrams(as_biblio_project(example_biblio()),n=1)
concept_ngrams <- function(x,n=2L,field=c("title","abstract"),stopwords=c("and","the","for","with","under","of","in","to"),min_freq=1L) {
  field=match.arg(field); n=as.integer(n)[1L]; if(n<1L)stop("`n` must be >= 1.",call.=FALSE)
  sw=tolower(unique(c(.bi_stopwords(),stopwords))); allgr=list()
  for(t in x$works[[field]]) {
    z=.bi_tokens(t); z=z[!z%in%sw]; if(length(z)<n)next
    g=vapply(seq_len(length(z)-n+1L),function(i)paste(z[i:(i+n-1L)],collapse=" "),character(1L))
    allgr[[length(allgr)+1L]]=g
  }
  s=sort(table(unlist(allgr)),decreasing=TRUE); s=s[s>=min_freq]
  data.frame(ngram=names(s),n=as.integer(s),row.names=NULL)
}

#' Term co-occurrence matrix
#'
#' Native implementation over the top terms; Biblium
#' `compute_cooccurrence_matrix()` is the external auditor.
#' @param x A `biblio_project`.
#' @param top_n Number of top terms (by [term_frequency()]).
#' @param field Text field.
#' @return Symmetric co-occurrence matrix (diagonal = document frequency).
#' @export
#' @examples
#' dim(concept_cooccurrence(as_biblio_project(example_biblio())))
concept_cooccurrence <- function(x,top_n=30L,field=c("title","abstract")) {
  field=match.arg(field); tf=term_frequency(x,field=field)
  terms=utils::head(tf$term,min(as.integer(top_n)[1L],nrow(tf)))
  docs=lapply(x$works[[field]],function(t)unique(.bi_tokens(t)))
  M=vapply(docs,function(z)as.integer(terms%in%z),integer(length(terms)))
  C=tcrossprod(M); dimnames(C)=list(terms,terms); C
}

.bi_diversity_native <- function(counts) {
  p=as.numeric(counts)/sum(counts); n=length(p)
  sh=-sum(p*log(p[p>0])); si=1-sum(p^2)
  gi=if(n<2L)0 else sum(abs(outer(p,p,"-")))/(2*n)
  c(shannon=sh,simpson=si,gini=gi,rao=si)
}

#' Reference diversity (native, with Rao-Stirling)
#'
#' Shannon/Simpson/Gini over reference sources or years, plus the Rao-Stirling
#' index (uniform disparity, hence equal to Simpson; Biblium
#' `compute_rao_stirling()` audits it).
#' @param x A `biblio_project`.
#' @param by `"source"` or `"year"`.
#' @return One-row data frame with the indices.
#' @export
#' @examples
#' reference_diversity(as_biblio_project(example_biblio()))
reference_diversity <- function(x,by=c("source","year")) {
  by=match.arg(by); v=x$works[[by]]; v=v[!is.na(v)]; if(!length(v))stop("No values for '",by,"'.",call.=FALSE)
  s=table(v); d=.bi_diversity_native(as.integer(s))
  data.frame(entity=by,n_categories=length(s),shannon=d[["shannon"]],simpson=d[["simpson"]],gini=d[["gini"]],rao_stirling=d[["rao"]],row.names=NULL)
}

#' Term frequency from titles or abstracts
#' @param x A `biblio_project`.
#' @param field `"title"` or `"abstract"`.
#' @param stopwords Termos removidos antes da contagem. Sao ACRESCENTADOS a lista
#'   padrao (artigos e preposicoes do ingles), e nao a substituem: na versao
#'   anterior, informar `stopwords` descartava a lista padrao e as palavras
#'   funcionais voltavam para a contagem.
#' @return Term-frequency data frame.
#' @export
#' @examples
#' term_frequency(as_biblio_project(example_biblio()))
#' head(term_frequency(as_biblio_project(example_biblio()),stopwords=c("and","the")),5)
#' term_frequency(as_biblio_project(example_biblio()),field="abstract")
term_frequency <- function(x,field=c("title","abstract"),stopwords=c("and","the","for","with","under","of","in","to")) {
  field=match.arg(field)
  if (!any(nzchar(trimws(as.character(x$works[[field]])))))
    warning("O campo '", field, "' esta vazio no acervo: a contagem de termos sera vazia.",
            call.=FALSE)
  z=.bi_tokens(x$works[[field]]); z=z[!z%in%tolower(unique(c(.bi_stopwords(), stopwords)))]; s=sort(table(z),decreasing=TRUE); data.frame(term=names(s),n=as.integer(s),row.names=NULL)
}

#' TF-IDF terms by grouping stratum
#' @param x A `biblio_project`.
#' @param group Column of `x$works` used as stratum: `"year"` (default), `"source"`, or any other column of `x$works`.
#' @param field Text field.
#' @return Long data frame with term frequency and TF-IDF.
#' @export
#' @examples
#' head(tfidf_terms(as_biblio_project(example_biblio())),6)
#' head(tfidf_terms(as_biblio_project(example_biblio()),group="source"),6)
#' subset(tfidf_terms(as_biblio_project(example_biblio())), tfidf>0)[1:3,]
tfidf_terms <- function(x,group=c("year","source"),field=c("title","abstract")) {
  if(length(group)>1)group=group[1]; field=match.arg(field); w=x$works; if(!group%in%names(w))stop("'group' must name a column of x$works (e.g. 'year' or 'source').",call.=FALSE); rows=list()
  for(i in seq_len(nrow(w))){z=unique(.bi_tokens(w[[field]][i])); if(length(z))rows[[i]]=data.frame(group=as.character(w[[group]][i]),term=z,stringsAsFactors=FALSE)}
  d=do.call(rbind,rows); if(is.null(d))return(data.frame()); n=stats::aggregate(list(n=rep(1,nrow(d))),list(group=d$group,term=d$term),sum); docs=length(unique(n$group)); df=stats::aggregate(list(df=n$group),list(term=n$term),function(z)length(unique(z))); n=merge(n,df,by="term"); n$tfidf=n$n*log(docs/pmax(1,n$df)); n[order(-n$tfidf),]
}

#' Reference publication year spectroscopy
#' @param reference_years Numeric vector of cited-reference publication years.
#' @param window Running-median half-window.
#' @return Year counts, baseline and deviations.
#' @export
#' @examples
#' rpys(c(1990,1990,1991,2000,2000,2000,2001))
#' rpys(sample(1990:2020,100,replace=TRUE),window=2)
#' subset(rpys(c(rep(2000,10),1995:2005)), deviation>0)
rpys <- function(reference_years,window=2) {
  y=as.integer(reference_years); y=y[is.finite(y)]; all=seq(min(y),max(y)); n=tabulate(match(y,all),nbins=length(all)); base=vapply(seq_along(n),function(i)stats::median(n[max(1,i-window):min(length(n),i+window)]),numeric(1)); data.frame(year=all,n=n,baseline=base,deviation=n-base)
}

#' Citation trajectory
#' @param x A `biblio_project`.
#' @param current_year Reference year.
#' @return Work-level age, citations and velocity.
#' @export
#' @examples
#' citation_trajectory(as_biblio_project(example_biblio()))
#' head(citation_trajectory(as_biblio_project(example_biblio())),3)
#' citation_trajectory(as_biblio_project(example_biblio()),current_year=2026)
citation_trajectory <- function(x,current_year=as.integer(format(Sys.Date(),"%Y"))) { w=x$works; age=pmax(1,current_year-w$year+1); data.frame(work_id=w$work_id,title=w$title,year=w$year,age=age,citations=w$cited_by_count,velocity=w$cited_by_count/age,stringsAsFactors=FALSE) }

#' Disruption index from citation relations
#'
#' Uses the CD-style definition `(N_i - N_j)/(N_i + N_j + N_k)`, where
#' `N_i` cites the focal work but not its references, `N_j` cites both, and
#' `N_k` cites focal references but not the focal work.
#' @param focal_id Focal work identifier.
#' @param citation_edges Data frame with `citing_id` and `cited_id`.
#' @param focal_references IDs cited by the focal work.
#' @return A one-row data frame.
#' @export
#' @examples
#' e <- data.frame(
#'   citing_id = c("a", "b", "b", "c"),
#'   cited_id = c("f", "f", "r1", "r1")
#' )
#' disruption_index("f", e, "r1")
#' disruption_index("f",e,c("r1","r2"))
#' disruption_index("f",data.frame(citing_id="a",cited_id="f"),character())
disruption_index <- function(focal_id,citation_edges,focal_references) {
  a=citation_edges; if(!all(c("citing_id","cited_id")%in%names(a))) stop("citation_edges must have columns 'citing_id' and 'cited_id'.",call.=FALSE)
  cit_f=unique(a$citing_id[a$cited_id==focal_id]); cit_r=unique(a$citing_id[a$cited_id%in%focal_references])
  # N_k exclui o proprio focal: ele cita as proprias referencias por construcao
  # e nao e obra subsequente; sem isso, N_k vinha inflado em 1 (cf. Biblium).
  ni=length(setdiff(cit_f,cit_r)); nj=length(intersect(cit_f,cit_r)); nk=length(setdiff(cit_r,union(cit_f,focal_id))); den=ni+nj+nk
  # casos-limite devolvem NA, e nao um numero com aparencia de resultado:
  #   - ninguem cita o focal: o indice nao esta definido (0 ou 1 seriam falsos)
  #   - focal_references vazio: sem referencias declaradas nao ha consolidacao
  if (!length(cit_f)) {
    warning("Nenhum citante do focal '", focal_id,
            "' na tabela de arestas: o indice de disrupcao nao esta definido.",
            call.=FALSE)
    return(data.frame(focal_id=focal_id,N_i=NA_integer_,N_j=NA_integer_,N_k=NA_integer_,disruption=NA_real_))
  }
  if (!length(focal_references))
    warning("'focal_references' esta vazio: sem referencias declaradas, N_j e N_k sao zero por construcao.",
            call.=FALSE)
  data.frame(focal_id=focal_id,N_i=ni,N_j=nj,N_k=nk,disruption=if(den) (ni-nj)/den else NA_real_)
}
