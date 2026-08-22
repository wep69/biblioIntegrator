test_that("project harmonization and health work", {
  x <- as_biblio_project(example_biblio())
  expect_s3_class(x,"biblio_project")
  expect_equal(nrow(x$works),12)
  expect_true(all(c("check","n") %in% names(biblio_health(x))))
  expect_equal(nrow(to_bibliometrix(x)),12)
})

test_that("deduplication is auditable", {
  d <- rbind(example_biblio(),example_biblio()[1,])
  x <- deduplicate_biblio(as_biblio_project(d))
  expect_equal(nrow(x$works),12)
  expect_equal(nrow(attr(x,"dedup_log")),1)
  expect_true(any(audit_biblio(x)$operation=="deduplicate_biblio"))
})

test_that("descriptive metrics are finite", {
  x<-as_biblio_project(example_biblio())
  s<-describe_biblio(x); expect_equal(s$n_documents,12); expect_true(s$total_citations>0)
  m<-biblio_metrics(x); expect_true(all(m$h_index>=0)); expect_true(nrow(normalized_citations(x))==12)
})
