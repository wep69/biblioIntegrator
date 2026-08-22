#' Create an analysis plan
#'
#' @param source Data source label or file path.
#' @param analyses Character vector of requested analysis blocks.
#' @param network Network type.
#' @param group Optional group definition.
#' @param report Output report format.
#' @param seed Reproducibility seed.
#' @return A `biblio_plan` list.
#' @export
#' @examples
#' form_plan()
#' form_plan(analyses=c("health","descriptive","network"),network="coauthor")
#' form_plan(source="scopus.csv",report="docx",seed=42)
form_plan <- function(source=NULL,analyses=c("health","descriptive","temporal","network","text"),network="coauthor",group=NULL,report=c("markdown","html","docx","pdf"),seed=123) {
  structure(list(source=source,analyses=unique(analyses),network=network,group=group,report=match.arg(report),seed=as.integer(seed)),class="biblio_plan")
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
  if(!inherits(plan,"biblio_plan"))stop("`plan` must be created by form_plan().",call.=FALSE)
  allowed=c("health","descriptive","temporal","network","text","groups"); bad=setdiff(plan$analyses,allowed); if(length(bad))stop("Unknown analyses: ",paste(bad,collapse=", "),call.=FALSE)
  if(!plan$network%in%c("coauthor","keyword","citation"))stop("Invalid network type.",call.=FALSE); invisible(plan)
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
  validate_plan(plan); set.seed(plan$seed); x=if(is.null(data))biblio_import(plan$source) else as_biblio_project(data); out=list(project=x)
  if("health"%in%plan$analyses)out$health=biblio_health(x)
  if("descriptive"%in%plan$analyses)out$descriptive=describe_biblio(x)
  if("temporal"%in%plan$analyses)out$temporal=temporal_growth(x)
  if("network"%in%plan$analyses){out$network=bibliographic_network(x,plan$network);out$centrality=network_centrality(out$network)}
  if("text"%in%plan$analyses)out$terms=term_frequency(x)
  if("groups"%in%plan$analyses&&!is.null(plan$group))out$groups=compare_groups(x,plan$group,seed=plan$seed)
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
#' @param x A data frame or `biblio_project`.
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
  format=match.arg(format); x=as_biblio_project(x); h=biblio_health(x); d=describe_biblio(x); t=temporal_growth(x); terms=term_frequency(x); g=tryCatch(bibliographic_network(x,"coauthor"),error=function(e)NULL); cent=if(!is.null(g)&&igraph::vcount(g))network_centrality(g) else data.frame(); prov=audit_biblio(x); back=backend_status()
  md=c(paste0("# ",title),"",paste0("Generated: ",Sys.time()),"","## Corpus summary",paste0("Documents: **",d$n_documents,"**  "),paste0("Total citations: **",d$total_citations,"**  "),paste0("Years: **",paste(d$years,collapse="-"),"**"),"","## Data quality",.bi_md_table(h),"## Annual production",.bi_md_table(t),"## Leading terms",.bi_md_table(terms),"## Coauthorship centrality",.bi_md_table(cent),"## Optional backends",.bi_md_table(back),"## Provenance",.bi_md_table(prov),"## Interpretation notes","The report separates descriptive counts from inferential procedures. Citation indicators depend on database coverage and observation window. Network measures depend on counting and threshold choices; sensitivity or stability analysis should accompany substantive conclusions.")
  if(format=="markdown"){writeLines(md,output_file,useBytes=TRUE);return(normalizePath(output_file,winslash="/",mustWork=TRUE))}
  if(!requireNamespace("rmarkdown",quietly=TRUE))stop("Install 'rmarkdown' for rendered reports.",call.=FALSE)
  rmd=tempfile(fileext=".Rmd"); yaml=paste0("---\ntitle: ",dQuote(title),"\noutput: ",switch(format,html="html_document",docx="word_document",pdf="pdf_document"),"\n---\n\n"); writeLines(c(yaml,md[-1]),rmd,useBytes=TRUE); rmarkdown::render(rmd,output_format=switch(format,html="html_document",docx="word_document",pdf="pdf_document"),output_file=normalizePath(output_file,winslash="/",mustWork=FALSE),quiet=TRUE,envir=new.env(parent=globalenv())); normalizePath(output_file,winslash="/",mustWork=TRUE)
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
