#' Define bibliometric groups
#'
#' Creates exclusive or overlapping document-group membership matrices.
#' @param x A `biblio_project`.
#' @param groups Factor/character vector, matrix/data frame, or function returning one.
#' @return A binary membership matrix with work IDs as row names.
#' @export
#' @examples
#' x <- as_biblio_project(example_biblio()); form_groups(x, ifelse(x$works$year<2022,"early","late"))
#' form_groups(x, cbind(old=x$works$year<=2021,recent=x$works$year>=2021))
#' form_groups(x, function(w) ifelse(w$year<2020,"older","newer"))
form_groups <- function(x, groups) {
  if (is.function(groups)) groups <- groups(x$works)
  m <- .bi_membership(groups,nrow(x$works)); if(nrow(m)!=nrow(x$works)) stop("Group membership must have one row per work.",call.=FALSE)
  rownames(m)=x$works$work_id; if(is.null(colnames(m))) colnames(m)=paste0("group",seq_len(ncol(m))); m
}

.bi_assoc_stat <- function(G,E) {
  O <- t(G) %*% E
  total <- sum(O); if(total==0) return(list(O=O,E=O,res=O,chi=0,V=0))
  expected <- outer(rowSums(O),colSums(O))/total
  chi <- sum(ifelse(expected>0,(O-expected)^2/expected,0))
  rp=rowSums(O)/total; cp=colSums(O)/total
  den=sqrt(expected * outer(1-rp,1-cp)); res=ifelse(den>0,(O-expected)/den,0)
  V=sqrt(chi/(total*max(1,min(nrow(O)-1,ncol(O)-1))))
  list(O=O,E=expected,res=res,chi=chi,V=V)
}

#' Compare user-defined bibliometric groups
#'
#' Tests group-entity association. For overlapping groups, the null distribution is
#' obtained by permuting complete membership rows, preserving each document's overlap
#' pattern. Standardized residuals identify the direction of local associations.
#' @param x A `biblio_project`.
#' @param groups Group definition accepted by [form_groups()].
#' @param entity Entity type, currently `"keyword"` or `"author"`.
#' @param permutations Number of random permutations. Use zero for asymptotic inference.
#' @param bootstrap Number of document-level bootstrap replicates for Cramer's V interval.
#' @param seed Random seed.
#' @param engine `"native"`, `"biblium"`, or `"auto"`.
#' @return A `biblio_group_comparison` list.
#' @export
#' @examples
#' x <- as_biblio_project(example_biblio()); g <- ifelse(x$works$year<2022,"early","late")
#' compare_groups(x,g,permutations=49,seed=1)
#' compare_groups(x,cbind(pre=x$works$year<=2021,post=x$works$year>=2021),permutations=49,seed=2)
#' compare_groups(x,g,entity="author",permutations=19,bootstrap=19,seed=3)
compare_groups <- function(x, groups, entity=c("keyword","author"), permutations=999, bootstrap=0, seed=NULL, engine=c("native","biblium","auto")) {
  entity=match.arg(entity); engine=match.arg(engine)
  if(engine!="native") {
    ok <- biblium_backend_status()$available
    if(engine=="biblium" && !ok) stop("Biblium backend is unavailable; run install_biblium_backend().",call.=FALSE)
    if(ok) return(biblium_compare_groups(x,groups,entity=entity,permutations=permutations,seed=seed))
  }
  G=form_groups(x,groups); E=.bi_entity_matrix(x,entity); if(ncol(E)<2) stop("At least two entities are required.",call.=FALSE)
  st=.bi_assoc_stat(G,E); overlap=any(rowSums(G)>1)
  if(!is.null(seed)) set.seed(seed)
  p=NA_real_
  if(permutations>0) { sims=replicate(permutations,{Gp=G[sample.int(nrow(G)),,drop=FALSE]; .bi_assoc_stat(Gp,E)$chi}); p=(1+sum(sims>=st$chi))/(permutations+1) }
  else if(!overlap) p=stats::pchisq(st$chi,df=(nrow(st$O)-1)*(ncol(st$O)-1),lower.tail=FALSE)
  ci=c(NA_real_,NA_real_)
  if(bootstrap>0){ bs=replicate(bootstrap,{i=sample.int(nrow(G),replace=TRUE); .bi_assoc_stat(G[i,,drop=FALSE],E[i,,drop=FALSE])$V}); ci=stats::quantile(bs,c(.025,.975),na.rm=TRUE,names=FALSE) }
  structure(list(engine="native",entity=entity,groups=G,observed=st$O,expected=st$E,residuals=st$res,chi_square=st$chi,p_value=p,cramers_v=st$V,cramers_v_ci=ci,overlap=overlap,permutations=permutations),class="biblio_group_comparison")
}

#' Print a group comparison
#' @param x A `biblio_group_comparison`.
#' @param ... Unused.
#' @return `x`, invisibly.
#' @export
print.biblio_group_comparison <- function(x,...) { cat("<biblio_group_comparison>",x$engine,"engine\nChi-square:",format(x$chi_square,digits=4)," p:",format(x$p_value,digits=4)," V:",format(x$cramers_v,digits=3),"\n"); invisible(x) }

#' Extract standardized association residuals
#' @param x A `biblio_group_comparison`.
#' @param min_abs Minimum absolute residual retained.
#' @return Long data frame of group-entity residuals.
#' @export
#' @examples
#' z <- compare_groups(as_biblio_project(example_biblio()),rep(c("a","b"),6),permutations=19)
#' association_residuals(z)
#' head(association_residuals(z,min_abs=1))
#' subset(association_residuals(z), residual>0)
association_residuals <- function(x,min_abs=0) {
  r=x$residuals; d=expand.grid(group=rownames(r),entity=colnames(r),stringsAsFactors=FALSE); d$residual=as.vector(r); d$observed=as.vector(x$observed); d$expected=as.vector(x$expected); d[abs(d$residual)>=min_abs,,drop=FALSE]
}

#' Correspondence analysis of group-entity associations
#' @param x A `biblio_group_comparison`.
#' @param ndim Number of dimensions.
#' @return Row/column coordinates and singular values.
#' @export
#' @examples
#' z <- compare_groups(as_biblio_project(example_biblio()),rep(c("a","b"),6),permutations=19)
#' group_ca(z)
#' group_ca(z,ndim=1)$rows
#' group_ca(z)$singular_values
 group_ca <- function(x,ndim=2) {
  O=x$observed; N=sum(O); P=O/N; r=rowSums(P); c=colSums(P); S=(P-outer(r,c))/sqrt(outer(r,c)); S[!is.finite(S)]=0
  sv=svd(S); k=min(ndim,length(sv$d)); rows=sweep(sv$u[,seq_len(k),drop=FALSE],1,sqrt(r),"/") %*% diag(sv$d[seq_len(k)],k); cols=sweep(sv$v[,seq_len(k),drop=FALSE],1,sqrt(c),"/") %*% diag(sv$d[seq_len(k)],k)
  rownames(rows)=rownames(O); rownames(cols)=colnames(O); list(rows=rows,columns=cols,singular_values=sv$d)
}

#' Multiple correspondence analysis of group and entity presence
#' @param x A `biblio_project`.
#' @param groups Group definition.
#' @param entity Entity type.
#' @param ncp Number of dimensions.
#' @return A `FactoMineR::MCA` result.
#' @export
#' @examples
#' \donttest{
#' x <- as_biblio_project(example_biblio()); g <- rep(c("a","b"),6)
#' if (requireNamespace("FactoMineR",quietly=TRUE)) group_mca(x,g,ncp=2)
#' if (requireNamespace("FactoMineR",quietly=TRUE)) group_mca(x,cbind(a=1:12<=7,b=1:12>=5),ncp=1)
#' if (requireNamespace("FactoMineR",quietly=TRUE)) names(group_mca(x,g,ncp=2))
#' }
group_mca <- function(x,groups,entity=c("keyword","author"),ncp=2) {
  if(!requireNamespace("FactoMineR",quietly=TRUE)) stop("Install 'FactoMineR' for MCA.",call.=FALSE)
  G=form_groups(x,groups); E=.bi_entity_matrix(x,match.arg(entity)); d=as.data.frame(cbind(G,E)); d[]=lapply(d,function(z)factor(ifelse(z>0,"yes","no"))); FactoMineR::MCA(d,ncp=ncp,graph=FALSE)
}

#' Sensitivity analysis for entity-frequency thresholds
#' @param x A `biblio_project`.
#' @param groups Group definition.
#' @param thresholds Minimum entity frequencies.
#' @param entity Entity type.
#' @param permutations Number of permutations per threshold.
#' @param seed Seed.
#' @return A data frame with effect sizes and p-values by threshold.
#' @export
#' @examples
#' x <- as_biblio_project(example_biblio()); g <- rep(c("a","b"),6)
#' sensitivity_analysis(x,g,thresholds=1:2,permutations=19,seed=1)
#' sensitivity_analysis(x,g,thresholds=c(1,3),permutations=9,seed=2)
#' subset(sensitivity_analysis(x,g,1:2,permutations=9), entities>1)
sensitivity_analysis <- function(x,groups,thresholds=c(1,2,3),entity=c("keyword","author"),permutations=99,seed=NULL) {
  entity=match.arg(entity); G=form_groups(x,groups); E0=.bi_entity_matrix(x,entity); if(!is.null(seed)) set.seed(seed)
  do.call(rbind,lapply(thresholds,function(t){ E=E0[,colSums(E0)>=t,drop=FALSE]; if(ncol(E)<2)return(data.frame(threshold=t,entities=ncol(E),cramers_v=NA,p_value=NA)); st=.bi_assoc_stat(G,E); sims=replicate(permutations,.bi_assoc_stat(G[sample.int(nrow(G)),,drop=FALSE],E)$chi); data.frame(threshold=t,entities=ncol(E),cramers_v=st$V,p_value=(1+sum(sims>=st$chi))/(permutations+1)) }))
}
