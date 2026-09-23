test_that("plan executes core workflow", {
  r<-run_plan(form_plan(),example_biblio()); expect_s3_class(r$project,"biblio_project"); expect_true(all(c("health","descriptive","temporal","network","terms")%in%names(r)))
})

test_that("markdown report and exports work", {
  x<-as_biblio_project(example_biblio()); f<-tempfile(fileext=".md"); biblio_report(x,f); expect_true(file.exists(f)); expect_true(any(grepl("Provenance",readLines(f))))
  p<-tempfile();export_biblio(x,p,"csv");expect_true(file.exists(file.path(p,"works.csv")))
})

test_that("temporal and text analyses work", {
  x<-as_biblio_project(example_biblio()); expect_gt(nrow(temporal_growth(x)),0); expect_gt(nrow(term_frequency(x)),0); expect_gt(nrow(tfidf_terms(x)),0)
})

test_that("plan defaults stay backward compatible", {
  p<-form_plan(); expect_equal(p$analyses,c("health","descriptive","temporal","network","text")); expect_true(p$strict)
  expect_error(validate_plan(form_plan(analyses=c("health","nope"))),"Unknown analyses")
  expect_error(validate_plan(form_plan(analyses="diversity",diversity=list(entity="x",level="overall"))),"entity")
  expect_error(validate_plan(form_plan(analyses="means")),"plan\\$group")
})

test_that("run_plan skips unavailable blocks when strict=FALSE", {
  g<-ifelse(as_biblio_project(example_biblio())$works$year<2022,"early","late")
  p<-form_plan(analyses=c("health","diversity","means","mainpath"),group=g,strict=FALSE)
  expect_warning(r<-run_plan(p,example_biblio()),"Skipping block")
  expect_true(all(c("health","project")%in%names(r))); expect_null(r$mainpath)
  if(isTRUE(tryCatch(biblium_backend_status()$available,error=function(e)FALSE))) {
    expect_s3_class(r$diversity,"biblio_diversity"); expect_s3_class(r$means,"biblio_means_comparison")
  }
})

test_that("run_plan strict stops on missing references", {
  g<-ifelse(as_biblio_project(example_biblio())$works$year<2022,"early","late")
  p<-form_plan(analyses="mainpath",group=g,strict=TRUE)
  testthat::skip_if_not(isTRUE(tryCatch(biblium_backend_status()$available,error=function(e)FALSE)),"needs backend to reach the references check")
  expect_error(run_plan(p,example_biblio()),"references")
})

test_that("backend_status lists biblium and llm", {
  b<-backend_status(); expect_true(all(c("biblium","llm")%in%b$backend)); expect_true(is.logical(b$available))
})

test_that("report mirrors executed run blocks", {  g<-ifelse(as_biblio_project(example_biblio())$works$year<2022,"early","late")
  p<-form_plan(analyses=c("health","descriptive","diversity","means"),group=g,strict=FALSE)
  r<-suppressWarnings(run_plan(p,example_biblio())); f<-tempfile(fileext=".md"); biblio_report(r,f)
  txt<-paste(readLines(f),collapse="\n")
  expect_true(grepl("Optional backends",txt)); expect_true(grepl("Corpus summary",txt))
  if(!is.null(r$diversity)) expect_true(grepl("Diversity",txt))
})

test_that("wave2 blocks run through the plan", {
  g<-ifelse(as_biblio_project(example_biblio())$works$year<2022,"early","late")
  p<-form_plan(analyses=c("health","crosstab","patterns","concepts"),group=g,strict=FALSE)
  r<-suppressWarnings(run_plan(p,example_biblio()))
  expect_true(!is.null(r$concepts)&&nrow(r$concepts$ngrams)>=1)
  if(isTRUE(tryCatch(biblium_backend_status()$available,error=function(e)FALSE))) {
    expect_s3_class(r$crosstab,"biblio_crosstab"); expect_s3_class(r$patterns,"biblio_citation_patterns")
  }
  f<-tempfile(fileext=".md"); biblio_report(r,f); txt<-paste(readLines(f),collapse="\n")
  expect_true(grepl("Concepts",txt))
})

test_that("crosstab block validates its inputs", {
  expect_error(validate_plan(form_plan(analyses="crosstab")),"crosstab")
  expect_error(validate_plan(form_plan(analyses="patterns",patterns=list(source="x"))),"source")
})
