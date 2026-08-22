test_that("native and biblionetwork coauthorship produce networks", {
  x<-as_biblio_project(example_biblio())
  g<-bibliographic_network(x,"coauthor",engine="native"); expect_gt(igraph::ecount(g),0); expect_gt(nrow(network_centrality(g)),0)
  if(requireNamespace("biblionetwork",quietly=TRUE)){b<-bibliographic_network(x,"coauthor",engine="biblionetwork"); expect_gt(igraph::ecount(b),0); expect_identical(attr(b,"engine"),"biblionetwork")}
})

test_that("Arrow roundtrip works when available", {
  skip_if_not_installed("arrow"); x<-as_biblio_project(example_biblio()); p<-tempfile(); biblio_store(x,p,"arrow"); y<-biblio_load(p,"arrow"); expect_equal(nrow(y$works),nrow(x$works))
})

test_that("DuckDB roundtrip and query work when available", {
  skip_if_not_installed("duckdb"); skip_if_not_installed("DBI"); x<-as_biblio_project(example_biblio()); p<-tempfile(fileext=".duckdb"); biblio_store(x,p,"duckdb"); expect_equal(nrow(biblio_load(p,"duckdb")$works),12); q<-biblio_query(p,"SELECT COUNT(*) AS n FROM works"); expect_equal(q$n,12)
})
