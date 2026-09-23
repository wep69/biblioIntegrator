#' Create an analysis plan
#'
#' @param source Data source label or file path.
#' @param analyses Character vector of requested analysis blocks.
#' @param network Network type.
#' @param group Optional group definition.
#' @param report Output report format.
#' @param seed Reproducibility seed.
#' @param engine Reserved for future native engines; Biblium blocks always use
#'   the Python backend when present.
#' @param strict If `TRUE` (default), a block whose backend is unavailable stops
#'   with an error; if `FALSE` it is skipped with a warning.
#' @param diversity List with `entity` and `level` for the diversity block.
#' @param representation List with `threshold` for the representativeness block.
#' @param mainpath List with `method` for the main path block.
#' @param means List with `metric` for the means comparison block.
#' @param crosstab List with `row` and optional `col` (defaults to the plan
#'   group labels) for the cross-tabulation block.
#' @param patterns List with `source`, `max_papers` and `min_age` for the
#'   citation patterns block.
#' @param concepts List with `n` and `top_n` for the native concepts block.
#' @return A `biblio_plan` list.
#' @export
#' @examples
#' form_plan()
#' form_plan(analyses=c("health","descriptive","network"),network="coauthor")
#' form_plan(source="scopus.csv",report="docx",seed=42)
#' form_plan(analyses=c("health","diversity","means"),group="g")
form_plan <- function(source=NULL,analyses=c("health","descriptive","temporal","network","text"),network="coauthor",group=NULL,report=c("markdown","html","docx","pdf"),seed=123,engine=c("auto","native","biblium"),strict=TRUE,diversity=list(entity="keyword",level="overall"),representation=list(threshold=1.0),mainpath=list(method="SPC"),means=list(metric="citations"),crosstab=list(row="source",col=NULL),patterns=list(source="estimated",max_papers=500L,min_age=3L),concepts=list(n=2L,top_n=30L)) {
  structure(list(source=source,analyses=unique(analyses),network=network,group=group,report=match.arg(report),seed=as.integer(seed),engine=match.arg(engine),strict=isTRUE(strict),diversity=diversity,representation=representation,mainpath=mainpath,means=means,crosstab=crosstab,patterns=patterns,concepts=concepts),class="biblio_plan")
}

#' Validate an analysis plan
#' @param plan A `biblio_plan`.
#' @return Plan invisibly; errors on invalid settings.
#' @export
#' @examples
#' validate_plan(form_plan())
#' validate_plan(form_plan(network="keyword"))
#' inherits(validate_plan(form_plan(report="html")),"biblio_plan")
validate_plan <- function(plan) {
  if(!inherits(plan,"biblio_plan"))stop("`plan` must be created by form_plan(). Note the argument order: run_plan(plan, data).",call.=FALSE)
  allowed=c("health","descriptive","temporal","network","text","groups","diversity","representation","mainpath","means","crosstab","patterns","concepts"); bad=setdiff(plan$analyses,allowed); if(length(bad))stop("Unknown analyses: ",paste(bad,collapse=", "),call.=FALSE)
  if(!plan$network%in%c("coauthor","keyword","citation"))stop("Invalid network type.",call.=FALSE)
  if("diversity"%in%plan$analyses) { if(!plan$diversity$entity%in%c("keyword","author","source"))stop("plan$diversity$entity must be keyword, author or source.",call.=FALSE); if(!plan$diversity$level%in%c("overall","temporal","group"))stop("plan$diversity$level must be overall, temporal or group.",call.=FALSE); if(identical(plan$diversity$level,"group")&&is.null(plan$group))stop("Diversity level 'group' requires plan$group.",call.=FALSE) }
  if("mainpath"%in%plan$analyses&&!plan$mainpath$method%in%c("SPC","SPLC","SPNP"))stop("plan$mainpath$method must be SPC, SPLC or SPNP.",call.=FALSE)
  if("means"%in%plan$analyses) { if(!plan$means$metric%in%c("citations","velocity","year"))stop("plan$means$metric must be citations, velocity or year.",call.=FALSE); if(is.null(plan$group))stop("Block 'means' requires plan$group.",call.=FALSE) }
  if("patterns"%in%plan$analyses&&!plan$patterns$source%in%c("estimated","openalex"))stop("plan$patterns$source must be estimated or openalex.",call.=FALSE)
  if("concepts"%in%plan$analyses&&as.integer(plan$concepts$n)[1L]<1L)stop("plan$concepts$n must be >= 1.",call.=FALSE)
  if("crosstab"%in%plan$analyses&&is.null(plan$crosstab$col)&&is.null(plan$group))stop("Block 'crosstab' needs plan$crosstab$col or plan$group.",call.=FALSE)
  invisible(plan)
}

.bi_group_labels <- function(plan,x) {
  g=plan$group; if(is.null(g))return(NULL)
  if(is.function(g))g=g(x$works)
  if(is.matrix(g)||is.data.frame(g)) { if(ncol(g)!=1L)return(NULL); g=g[,1L] }
  if(length(g)!=nrow(x$works))return(NULL)
  as.character(g)
}

.bi_maybe <- function(plan,expr) {
  if(isTRUE(plan$strict)) return(eval(expr,parent.frame()))
  tryCatch(eval(expr,parent.frame()),error=function(e){warning("Skipping block: ",conditionMessage(e),call.=FALSE); NULL})
}

#' Execute an integrated bibliometric plan
#' @param plan A `biblio_plan`.
#' @param data Data frame or `biblio_project`; if missing, `plan$source` is imported.
#' @return Named list of analysis results.
#' @export
#' @examples
#' run_plan(form_plan(),example_biblio())
#' run_plan(form_plan(analyses=c("health","text")),as_biblio_project(example_biblio()))
#' names(run_plan(form_plan(analyses="network"),example_biblio()))
run_plan <- function(plan,data=NULL) {
  validate_plan(plan); sr=.bi_rng_get(); on.exit(.bi_rng_set(sr),add=TRUE); set.seed(plan$seed); x=if(is.null(data))biblio_import(plan$source) else as_biblio_project(data); out=list(project=x)
  if("health"%in%plan$analyses)out$health=biblio_health(x)
  if("descriptive"%in%plan$analyses)out$descriptive=describe_biblio(x)
  if("temporal"%in%plan$analyses)out$temporal=temporal_growth(x)
  if("network"%in%plan$analyses){out$network=bibliographic_network(x,plan$network);out$centrality=network_centrality(out$network)}
  if("text"%in%plan$analyses)out$terms=term_frequency(x)
  if("groups"%in%plan$analyses&&!is.null(plan$group))out$groups=compare_groups(x,plan$group,seed=plan$seed)
  if("diversity"%in%plan$analyses)out$diversity=.bi_maybe(plan,quote(biblium_diversity(x,entity=plan$diversity$entity,level=plan$diversity$level,groups=plan$group)))
  if("representation"%in%plan$analyses)out$representation=.bi_maybe(plan,quote(biblium_representativeness(x,threshold=plan$representation$threshold)))
  if("mainpath"%in%plan$analyses)out$mainpath=.bi_maybe(plan,quote(biblium_main_path(x,method=plan$mainpath$method)))
  if("means"%in%plan$analyses)out$means=.bi_maybe(plan,quote(biblium_compare_means(x,metric=plan$means$metric,groups=plan$group)))
  if("crosstab"%in%plan$analyses)out$crosstab=.bi_maybe(plan,quote(biblium_crosstab(x,row=plan$crosstab$row,col=if(is.null(plan$crosstab$col)).bi_group_labels(plan,x) else plan$crosstab$col)))
  if("patterns"%in%plan$analyses)out$patterns=.bi_maybe(plan,quote(biblium_citation_patterns(x,source=plan$patterns$source,max_papers=plan$patterns$max_papers,min_age=plan$patterns$min_age)))
  if("concepts"%in%plan$analyses)out$concepts=list(ngrams=utils::head(concept_ngrams(x,n=plan$concepts$n),20),cooccurrence=concept_cooccurrence(x,top_n=plan$concepts$top_n))
  class(out)=c("biblio_run","list"); out
}

.bi_md_table <- function(d,n=20) {
  if(is.null(d)||!NROW(d))return("_No data available._\n")
  d=as.data.frame(d); d=utils::head(d,n); vals=lapply(d,function(z)gsub("\\|","/",as.character(z))); d=as.data.frame(vals,stringsAsFactors=FALSE)
  paste0("| ",paste(names(d),collapse=" | ")," |\n| ",paste(rep("---",ncol(d)),collapse=" | ")," |\n",paste(apply(d,1,function(r)paste0("| ",paste(r,collapse=" | ")," |")),collapse="\n"),"\n")
}

#' Generate an automated bibliometric report
#'
#' Produces an auditable report with corpus health, descriptive metrics, annual
#' growth, leading terms, network centrality, backend availability and provenance.
#' When `x` is a `biblio_run` (see [run_plan()]), only the executed blocks are
#' reported, including the Biblium engines (diversity, representativeness,
#' main path, means comparison).
#' @param x A data frame, `biblio_project` or `biblio_run`.
#' @param output_file Destination file.
#' @param format `"markdown"`, `"html"`, `"docx"`, or `"pdf"`.
#' @param title Report title.
#' @return Normalized report path.
#' @export
#' @examples
#' f<-tempfile(fileext=".md"); biblio_report(example_biblio(),f); file.exists(f)
#' f <- tempfile(fileext = ".md")
#' x <- as_biblio_project(example_biblio())
#' biblio_report(x, f, title = "Agronomy map")
#' \donttest{
#' if (requireNamespace("rmarkdown", quietly = TRUE)) {
#'   f <- tempfile(fileext = ".html")
#'   biblio_report(example_biblio(), f, "html")
#' }
#' }
biblio_report <- function(x,output_file="biblio-report.md",format=c("markdown","html","docx","pdf"),title="Bibliometric Analysis Report") {
  format=match.arg(format); if(inherits(x,"biblio_run"))return(.bi_report_run(x,output_file,format,title))
  x=as_biblio_project(x); h=biblio_health(x); d=describe_biblio(x); t=temporal_growth(x); terms=term_frequency(x); g=tryCatch(bibliographic_network(x,"coauthor"),error=function(e)NULL); cent=if(!is.null(g)&&igraph::vcount(g))network_centrality(g) else data.frame(); prov=audit_biblio(x); back=backend_status()
  md=c(paste0("# ",title),"",paste0("Generated: ",Sys.time()),"","## Corpus summary",paste0("Documents: **",d$n_documents,"**  "),paste0("Total citations: **",d$total_citations,"**  "),paste0("Years: **",paste(d$years,collapse="-"),"**"),"","## Data quality",.bi_md_table(h),"## Annual production",.bi_md_table(t),"## Leading terms",.bi_md_table(terms),"## Coauthorship centrality",.bi_md_table(cent),"## Optional backends",.bi_md_table(back),"## Provenance",.bi_md_table(prov),"## Interpretation notes","The report separates descriptive counts from inferential procedures. Citation indicators depend on database coverage and observation window. Network measures depend on counting and threshold choices; sensitivity or stability analysis should accompany substantive conclusions.")
  if(format=="markdown"){writeLines(md,output_file,useBytes=TRUE);return(normalizePath(output_file,winslash="/",mustWork=TRUE))}
  if(!requireNamespace("rmarkdown",quietly=TRUE))stop("Install 'rmarkdown' for rendered reports.",call.=FALSE)
  rmd=tempfile(fileext=".Rmd"); yaml=paste0("---\ntitle: ",dQuote(title),"\noutput: ",switch(format,html="html_document",docx="word_document",pdf="pdf_document"),"\n---\n\n"); writeLines(c(yaml,md[-1]),rmd,useBytes=TRUE); rmarkdown::render(rmd,output_format=switch(format,html="html_document",docx="word_document",pdf="pdf_document"),output_file=normalizePath(output_file,winslash="/",mustWork=FALSE),quiet=TRUE,envir=new.env(parent=globalenv())); normalizePath(output_file,winslash="/",mustWork=TRUE)
}

.bi_report_run <- function(run,output_file,format,title) {
  md=c(paste0("# ",title),"",paste0("Generated: ",Sys.time()))
  if(!is.null(run$descriptive)){d=run$descriptive; md=c(md,"","## Corpus summary",paste0("Documents: **",d$n_documents,"**  "),paste0("Total citations: **",d$total_citations,"**  "),paste0("Years: **",paste(d$years,collapse="-"),"**"))}
  if(!is.null(run$health))md=c(md,"","## Data quality",.bi_md_table(run$health))
  if(!is.null(run$temporal))md=c(md,"","## Annual production",.bi_md_table(run$temporal))
  if(!is.null(run$terms))md=c(md,"","## Leading terms",.bi_md_table(run$terms))
  if(!is.null(run$centrality))md=c(md,"","## Coauthorship centrality",.bi_md_table(run$centrality))
  if(!is.null(run$groups)){g=run$groups; md=c(md,"","## Group comparison",paste0("Engine: **",g$engine,"**  "),paste0("Chi-square: **",round(g$chi_square,2),"**, p = **",signif(g$p_value,3),"**, Cramer's V = **",round(g$cramers_v,3),"**"))}
  if(!is.null(run$diversity)){v=run$diversity; md=c(md,"","## Diversity (Biblium)",paste0("Entity: **",v$entity,"**, level: **",v$level,"**"),.bi_md_table(v$indices))}
  if(!is.null(run$representation)){r=run$representation; md=c(md,"","## Representativeness vs OpenAlex",paste0("Years ",r$years[1],"-",r$years[2],", threshold +/-",r$threshold," pp"),.bi_md_table(utils::head(r$table,20)))}
  if(!is.null(run$mainpath)){p=run$mainpath; md=c(md,"","## Main path (Biblium)",paste0("Method: **",p$method,"**, path length: **",p$path_length,"**"),paste0("Path: ",paste(p$global_main_path,collapse=" > ")))}
  if(!is.null(run$means)){m=run$means; md=c(md,"","## Means comparison (Biblium)",paste0("Metric: **",m$metric,"**, recommended: **",m$recommended_test,"**"),.bi_md_table(m$tests))}
  if(!is.null(run$crosstab)){c=run$crosstab; md=c(md,"","## Cross-tabulation (Biblium)",paste0("Chi-square: **",round(c$chi_squared$statistic,2),"**, p = **",signif(c$chi_squared$p_value,3),"**, Cramer's V = **",round(c$effect_size$cramers_v,3),"**"),.bi_md_table(c$observed))}
  if(!is.null(run$patterns)){p=run$patterns; md=c(md,"","## Citation patterns (Biblium)",paste0("Source: **",p$data_source,"**, analyzed: **",p$n_analyzed,"**"),.bi_md_table(p$summary))}
  if(!is.null(run$concepts)){k=run$concepts; md=c(md,"","## Concepts (native)",.bi_md_table(k$ngrams))}
  md=c(md,"","## Optional backends",.bi_md_table(backend_status()),"## Provenance",.bi_md_table(audit_biblio(run$project)),"## Interpretation notes","The report separates descriptive counts from inferential procedures. Citation indicators depend on database coverage and observation window. Network measures depend on counting and threshold choices; sensitivity or stability analysis should accompany substantive conclusions.")
  if(format=="markdown"){writeLines(md,output_file,useBytes=TRUE);return(normalizePath(output_file,winslash="/",mustWork=TRUE))}
  if(!requireNamespace("rmarkdown",quietly=TRUE))stop("Install 'rmarkdown' for rendered reports.",call.=FALSE)
  rmd=tempfile(fileext=".Rmd"); yaml=paste0("---\ntitle: ",dQuote(title),"\noutput: ",switch(format,html="html_document",docx="word_document",pdf="pdf_document"),"\n---\n\n"); writeLines(c(yaml,md[-1]),rmd,useBytes=TRUE); rmarkdown::render(rmd,output_format=switch(format,html="html_document",docx="word_document",pdf="pdf_document"),output_file=normalizePath(output_file,winslash="/",mustWork=FALSE),quiet=TRUE,envir=new.env(parent=globalenv())); normalizePath(output_file,winslash=TRUE)
}

#' Interactive bibliometric workbench
#'
#' @param data Optional initial data frame or `biblio_project`.
#' @return A Shiny application object.
#' @export
#' @examples
#' \dontrun{
#' biblio_app()
#' biblio_app(example_biblio())
#' shiny::runApp(biblio_app(as_biblio_project(example_biblio())))
#' }
biblio_app <- function(data=NULL) {
  if(!requireNamespace("shiny",quietly=TRUE))stop("Install 'shiny'.",call.=FALSE)
  ui=shiny::navbarPage("biblioIntegrator",
    shiny::tabPanel("Data",shiny::sidebarLayout(shiny::sidebarPanel(shiny::fileInput("file","CSV/TSV/JSON"),shiny::actionButton("demo","Load agronomy demo")),shiny::mainPanel(shiny::verbatimTextOutput("summary"),shiny::tableOutput("health")))),
    shiny::tabPanel("Explore",shiny::fluidRow(shiny::column(6,shiny::h4("Annual production"),shiny::plotOutput("annual")),shiny::column(6,shiny::h4("Top terms"),shiny::tableOutput("terms")))),
    shiny::tabPanel("Networks",shiny::sidebarLayout(shiny::sidebarPanel(shiny::selectInput("ntype","Network",c("coauthor","keyword")),shiny::numericInput("minw","Minimum weight",1,min=1)),shiny::mainPanel(shiny::tableOutput("centrality")))),
    shiny::tabPanel("Compare",shiny::p("Use compare_groups() in scripted workflows for permutation inference, overlapping groups, residuals and effect sizes."),shiny::verbatimTextOutput("backends")),
    shiny::tabPanel("Report",shiny::downloadButton("report","Download report"),shiny::h4("Provenance"),shiny::tableOutput("provenance")))
  server=function(input,output,session){ rv=shiny::reactiveVal(if(is.null(data))NULL else as_biblio_project(data)); shiny::observeEvent(input$demo,rv(as_biblio_project(example_biblio()))); shiny::observeEvent(input$file,{shiny::req(input$file);rv(biblio_import(input$file$datapath))}); output$summary=shiny::renderPrint({shiny::req(rv());print(rv());print(describe_biblio(rv()))}); output$health=shiny::renderTable({shiny::req(rv());biblio_health(rv())}); output$annual=shiny::renderPlot({shiny::req(rv());a=temporal_growth(rv());plot(a$year,a$documents,type="b",xlab="Year",ylab="Documents")}); output$terms=shiny::renderTable({shiny::req(rv());utils::head(term_frequency(rv()),15)}); output$centrality=shiny::renderTable({shiny::req(rv());utils::head(network_centrality(bibliographic_network(rv(),input$ntype,min_weight=input$minw)),20)}); output$backends=shiny::renderPrint(backend_status()); output$provenance=shiny::renderTable({shiny::req(rv());audit_biblio(rv())}); output$report=shiny::downloadHandler(filename=function()"biblio-report.html",content=function(file){shiny::req(rv());biblio_report(rv(),file,"html")}) }
  shiny::shinyApp(ui,server)
}

#' Export harmonized bibliographic tables
#' @param x A `biblio_project`.
#' @param path Output directory.
#' @param format `"csv"`, `"json"`, or `"parquet"`.
#' @return Output directory invisibly.
#' @export
#' @examples
#' p<-tempfile();export_biblio(as_biblio_project(example_biblio()),p);list.files(p)
#' p<-tempfile();export_biblio(as_biblio_project(head(example_biblio())),p,"json");list.files(p)
#' \donttest{
#' if (requireNamespace("arrow", quietly = TRUE)) {
#'   p <- tempfile()
#'   x <- as_biblio_project(example_biblio())
#'   export_biblio(x, p, "parquet")
#'   list.files(p)
#' }
#' }
export_biblio <- function(x,path,format=c("csv","json","parquet")) {
  format=match.arg(format); dir.create(path,recursive=TRUE,showWarnings=FALSE); tabs=c("works","authors","authorships","keywords","references","provenance")
  for(n in tabs){f=file.path(path,paste0(n,".",if(format=="parquet")"parquet" else format)); if(format=="csv")utils::write.csv(x[[n]],f,row.names=FALSE) else if(format=="json")jsonlite::write_json(x[[n]],f,pretty=TRUE,na="null") else {if(!requireNamespace("arrow",quietly=TRUE))stop("Install 'arrow'.",call.=FALSE);arrow::write_parquet(x[[n]],f)}}; invisible(path)
}

#' Export a network for VOSviewer
#' @param graph An igraph network.
#' @param path Output network text file.
#' @return Output path invisibly.
#' @export
#' @examples
#' x <- as_biblio_project(example_biblio())
#' g <- bibliographic_network(x, "coauthor")
#' f <- tempfile()
#' export_vosviewer(g, f)
#' file.exists(f)
#' g <- bibliographic_network(x, "keyword")
#' f <- tempfile()
#' export_vosviewer(g, f)
#' readLines(f, n = 2)
#' g <- bibliographic_network(x, "coauthor")
#' f <- tempfile()
#' invisible(export_vosviewer(g, f))
export_vosviewer <- function(graph,path) { e=igraph::as_data_frame(graph,what="edges"); if(!"weight"%in%names(e))e$weight=1; utils::write.table(e[,c("from","to","weight")],path,sep="\t",row.names=FALSE,quote=FALSE); invisible(path) }
