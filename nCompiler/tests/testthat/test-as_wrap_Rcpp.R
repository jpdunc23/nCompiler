context("nCompiler's extensions to as<> and wrap<> templates")
library(Rcpp)
test_that("basic use of as<> and wrap<> work",{
  cppfile <- system.file(file.path('tests', 'testthat', 'cpp', 'as_wrap_tests.cpp'), package = 'nCompiler')
  test <- sourceCpp(cppfile)
  sofile <- {
    files <- list.files(test$buildDirectory)
    files[grepl("sourceCpp", files)][1]
  }
  dyn.load(file.path(test$buildDirectory, sofile))
  x <- array(rnorm(8), dim = c(2,2,2))
  xcopy <- .Call("tensor2D_by_copy", x)
  expect_identical(x, xcopy)
})