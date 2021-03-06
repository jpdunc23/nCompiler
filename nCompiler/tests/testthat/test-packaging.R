context("Test writePackage and buildPackage")

test_that("writePackage and buildPackage work for nFunction", 
          {
            nCompiler:::nFunctionIDMaker(reset = TRUE)
            nCompiler:::nClassIDMaker(reset = TRUE)
            
            foo <- nFunction(
              name = "foo",
              fun = function(x = double()) {
                ans <- x+1
                return(ans)
                returnType(double())
              }
            )
            
            writePackage(foo, package.name = "fooPackage", clean = TRUE)
            ans <- buildPackage("fooPackage")
            ## Need to get this name fixed
            expect_equal(fooPackage::objs_oB_oB1_cB_cB_NFID_1(2), 3)
          })

test_that("writePackage and buildPackage work for nClass", 
          {
            nCompiler:::nFunctionIDMaker(reset = TRUE)
            nCompiler:::nClassIDMaker(reset = TRUE)
            
            nc1 <- nClass(
              classname = "nc1",
              Rpublic = list(
                p1 = function(x) x+1
              ),
              Cpublic = list(
                x = 'numericScalar',
                cp1 = nFunction(
                  fun = function(x = double()) {
                    ans <- x+1
                    return(ans)
                    returnType(double())
                  }
                )
              )
            )
            writePackage(
              nc1, package.name = "nc1Package", clean = TRUE,
              nClass_full_interface = FALSE
            )
            buildPackage("nc1Package", dir = ".", lib = "test_package_nc1Package_lib")
            expect_true(require("nc1Package", lib.loc = "test_package_nc1Package_lib"))
            expect_true(is.function(nc1Package::new_nc1))
            obj <- nc1Package::new_nc1()
            expect_equal(method(obj, 'cp1')(2), 3)
          })

test_that("writePackage and buildPackage work for nClass with full interface",
{
  nCompiler:::nFunctionIDMaker(reset = TRUE)
  nCompiler:::nClassIDMaker(reset = TRUE)

  nc2 <- nClass(
    classname = "nc2",
    Rpublic = list(
      p1 = function(x) x+1
    ),
    Cpublic = list(
      x = 'numericScalar',
      cp1 = nFunction(
        fun = function(x = double()) {
          ans <- x+1
          return(ans)
          returnType(double())
        }
      )
    )
  )
  writePackage(
    nc2, package.name = "nc2Package", clean = TRUE
  )
  expect_true(buildPackage("nc2Package", dir = ".", lib = "test_package_nc2Package_lib"))
  expect_true(isCompiledNCgenerator(nc2Package::nc2))
  obj <- nc2Package::nc2$new()
  expect_true(inherits(obj, "nClass"))
  expect_equal(obj$cp1(2), 3)
})
