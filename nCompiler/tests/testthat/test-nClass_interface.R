context("nClass interface")

test_that(
  "Basic and full interfaces work",
  {
    nc1 <- nClass(
      Rpublic = list(
        Rv = NULL,
        Rfoo = function(x) x+1
      ),
      Cpublic = list(
        Cv = 'numericScalar',
        Cfoo = nFunction(
          fun = function(x) {
            return(x+1)
          },
          argTypes = list(x = 'numericScalar'),
          returnType = 'numericScalar')
      )
    )
    ans <- nCompile_nClass(nc1, interface = "generic")
    obj <- ans()
    value(obj, 'Cv') <- 2.3
    check <- value(obj, 'Cv')
    expect_equal(check, 2.3, info = "value() and `value<-()`")

    check <- method(obj, 'Cfoo')(3.4)
    expect_equal(check, 4.4, info = "method()")

    nc1c <- build_compiled_nClass(nc1)
    test <- nc1c$new(obj)
    test$Cv <- 5.6
    check <- test$Cv
    expect_equal(check, 5.6, info = "full interface active binding")
    test$Rv <- 6.7
    check <- test$Rv
    expect_equal(check, 6.7, info = "full interface R field")
    check <- test$Rfoo(7.8)
    expect_equal(check, 8.8, info = "full interface R method")
    check <- test$Cfoo(8.9)
    expect_equal(check, 9.9, info = "full interface R method")
  })

test_that(
  "interface = \"full\" works",
  {
    nc1 <- nClass(
      Rpublic = list(
        Rv = NULL,
        Rfoo = function(x) x+1
      ),
      Cpublic = list(
        Cv = 'numericScalar',
        Cfoo = nFunction(
          fun = function(x) {
            return(x+1)
          },
          argTypes = list(x = 'numericScalar'),
          returnType = 'numericScalar')
      )
    )
    ans <- nCompile_nClass(nc1, interface = "full")
    expect_true(isCompiledNCgenerator(ans))
    obj <- ans$new()
    expect_true(inherits(obj, "nClass"))
    obj$Cv <- 2.3
    check <- obj$Cv
    expect_equal(check, 2.3, info = "set and get from a full interface")

    check <- obj$Cfoo(3.4)
    expect_equal(check, 4.4, info = "method from a full interface")
  })
