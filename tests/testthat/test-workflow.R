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
