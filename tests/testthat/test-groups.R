test_that("exclusive and overlapping group inference works", {
  x<-as_biblio_project(example_biblio())
  a<-compare_groups(x,rep(c("a","b"),6),permutations=49,seed=1)
  expect_s3_class(a,"biblio_group_comparison"); expect_true(is.finite(a$cramers_v)); expect_false(a$overlap)
  G<-cbind(old=x$works$year<=2021,recent=x$works$year>=2021)
  b<-compare_groups(x,G,permutations=49,seed=2)
  expect_true(b$overlap); expect_true(b$p_value>=0 && b$p_value<=1)
  expect_true(nrow(association_residuals(b))>0)
})

test_that("CA and sensitivity work", {
  x<-as_biblio_project(example_biblio()); z<-compare_groups(x,rep(c("a","b"),6),permutations=9,seed=1)
  expect_true(length(group_ca(z)$singular_values)>0)
  s<-sensitivity_analysis(x,rep(c("a","b"),6),1:2,permutations=9,seed=1)
  expect_equal(nrow(s),2)
})
