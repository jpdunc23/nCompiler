## cpp_nClassBaseClass defines commonalities between cpp_nFunctionClass and cpp_nCompilerListClass, both of which are classes in.nCompiler
cpp_nClassBaseClass <- R6::R6Class(
    'cpp_nClassBaseClass',
    inherit = cppClassClass,##'cppNamedObjectsClass',
    portable = FALSE,
    public = list(
        ## Inherits a functionDefs list for member functions
        ## Inherits an objectDefs list for member data
       ## SEXPmemberInterfaceFuns = 'ANY', ## List of SEXP interface functions, one for each member function
        Compiler = NULL,
        ##nimCompProc = 'ANY', ## nfProcessing or nlProcessing object, needed to get the member data symbol table post-compilation
        
        ##Rgenerator = 'ANY' , ## function to generate and wrap a new object from an R object
        ##CmultiInterface = 'ANY', ## object for interfacing multiple C instances when a top-level interface is not needed
        built = NULL,
        loaded = NULL,
        Cwritten = NULL,
        cpp_nFunctionDefs = list(),
        getDefs = function() {
            super$getDefs()
        },
        getHincludes = function() {
            super$getHincludes()
        },
        getCPPincludes = function() {
            super$getCPPincludes()
        },
        getCPPusings = function() {
            super$getCPPusings()
        },
        initialize = function(Compiler,
                              debugCpp = FALSE,
                              fromModel = FALSE, ...) {
            usingEigen <- TRUE
            pluginIncludes <- if(usingEigen) {
                                 nCompiler_Eigen_plugin()$includes
                              } else {
                                  nCompiler_plugin()$includes
                              }
            self$Hpreamble <- pluginIncludes
            self$CPPpreamble <- pluginIncludes

            self$Hincludes <- c(self$Hincludes,
                                "<Rinternals.h>",
                              nCompilerIncludeFile("nCompiler_Eigen.h"))
            CPPincludes <<- list()
            usingEigen <- TRUE
            ## The following need to be here, not just in cpp_nFunction, in case there is a nClass with no methods.
            if(usingEigen) {
                checkPackage <- find.package(c("RcppEigenAD", "Rcereal"),
                                             quiet = TRUE)
                if(length(checkPackage)!=2) {
                    stop("Packages RcppEigenAD and Rcereal must be installed.")
                }
                ##                require(RcppEigenAD)
                ##                require(Rcereal)
              self$CPPusings <- c(self$CPPusings,
                                  "using namespace Rcpp;",
                                  "// [[Rcpp::plugins(nCompiler_Eigen_plugin)]]",
                                  "// [[Rcpp::depends(RcppEigenAD)]]",
                                  "// [[Rcpp::depends(nCompiler)]]",
                                  "// [[Rcpp::depends(Rcereal)]]")
            } else {
              self$CPPusings <- c(self$CPPusings,
                                  "using namespace Rcpp;",
                                  "// [[Rcpp::plugins(nCompiler_plugin)]]",
                                  "// [[Rcpp::depends(nCompiler)]]")
            }
            
            super$initialize(...) ## must call this first because it sets objectDefs to list()
            if(!missing(Compiler))
                process_Compiler(Compiler,
                                 debugCpp = debugCpp,
                                 fromModel = fromModel)
            if(length(name)==0)
                name <<- Compiler$name
            built <<- FALSE
            loaded <<- FALSE
            Cwritten <<- FALSE
        },
        process_Compiler = function(InputCompiler,
                                    debugCpp = FALSE,
                                    fromModel = FALSE) {
            ##ncp$cppDef <- .self
            Compiler <<- InputCompiler
            ##genNeededTypes(debugCpp = debugCpp, fromModel = fromModel)
            symbolTable <<- symbolTable2cppSymbolTable(Compiler$symbolTable)
            variableNamesForInterface <<- symbolTable$getSymbolNames()
        },
        buildAll = function(where = where) {
            ##            makeCppNames()
            ## buildConstructorFunctionDef()
            buildSEXPgenerator()
        },
        ## buildRgenerator = function() {message('whoops, base class version of buildRgenerator')},
        makeCppNames = function() {
            Rnames2CppNames <<- as.list(Rname2CppName(symbolTable$getSymbolNames()))
            names(Rnames2CppNames) <<- symbolTable$getSymbolNames()
        }##,
    )
    )

cpp_nClassClass <- R6::R6Class(
    'cpp_nClassClass',
    inherit = cpp_nClassBaseClass,
    portable = FALSE,
    public = list(
        ##NC_Compiler = NULL, 
        ##parentsSizeAndDims = 'ANY',
        getDefs = function() {
            c(super$getDefs()
              ##, SEXPmemberInterfaceFuns
              ) 
        },
        getHincludes = function() {
            c(super$getHincludes()
              ## , unlist(lapply(
              ##     SEXPmemberInterfaceFuns, function(x) x$getHincludes()),
              ##     recursive = FALSE)
              ##
              )
        },
        getCPPincludes = function() {
            c(super$getCPPincludes()
              ##, unlist(lapply(SEXPmemberInterfaceFuns, function(x) x$getCPPincludes()), recursive = FALSE)
              )
        },
        getCPPusings = function() {
            CPPuse <- unique(c(super$getCPPusings()
                               ##, unlist(lapply(SEXPmemberInterfaceFuns, function(x) x$getCPPusings()))
                               ))
            CPPuse
        },
        initialize = function(Compiler,
                              isNode = FALSE,
                              debugCpp = FALSE,
                              fromModel = FALSE,
                              ...) {
            super$initialize(Compiler,
                             debugCpp,
                             fromModel,
                             ...)
            if(!missing(Compiler))
                process_NC_Compiler(Compiler,
                                    debugCpp = debugCpp,
                                    fromModel = fromModel)
            if(isNode) {
                inheritance <<- inheritance[inheritance != 'NamedObjects']
                baseClassObj <- environment(nfProc$nfGenerator)$contains
                if(is.null(baseClassObj)) {
                    inheritance <<- c(inheritance, 'nodeFun')
                    parentsSizeAndDims <<- environment(nfProc$nfGenerator)$parentsSizeAndDims
                }
            }
        },
        process_NC_Compiler = function(Compiler, debugCpp = FALSE, fromModel = FALSE) {
##            nfProc <<- NC_Compiler
            buildFunctionDefs()
            ## This is slightly klugey
            ## The objectDefs here are for the member data
            ## We need them to be the parentST for each member function
            ## However the building of the cpp objects is slightly out of order, with the
            ## member functions already having been built during nfProcessing.
            for(i in seq_along(cppFunctionDefs)) {
                cppFunctionDefs[[i]]$args$setParentST(symbolTable)
            }
            ##SEXPmemberInterfaceFuns <<- lapply(functionDefs, function(x) x$SEXPinterfaceFun)
            ##nimCompProc <<- nfProc
        },
        buildFunctionDefs = function() {
            for(i in seq_along(Compiler$NFcompilers)) {
                RCname <- names(Compiler$NFcompilers)[i]
                cppFunctionDefs[[RCname]] <<- cpp_nFunctionClass$new(classMethod = TRUE) 
                cppFunctionDefs[[RCname]]$buildFunction(Compiler$NFcompilers[[RCname]])
                self$functionNamesForInterface <<- c(self$functionNamesForInterface, RCname)
               ## cppFunctionDefs[[RCname]]$buildSEXPinterfaceFun(className = nfProc$name)
               ## RCfunDefs[[RCname]] <<- functionDefs[[RCname]]
            }
        },
        addTypeTemplateFunction = function( funName ) {
            newFunName <- paste0(funName, '_AD_')
            regularFun <- cppFunctionDefs[[funName]]
            cppFunctionDefs[[newFunName]] <<- makeTypeTemplateFunction(newFunName, regularFun)
            invisible(NULL)
        },
addADtapingFunction = function( funName, 
                                independentVarNames, 
                                dependentVarNames ) {
  ADfunName <- paste0(funName, '_AD_')
  regularFun <- cppFunctionDefs[[funName]]
  newFunName <- paste0(funName, '_callForADtaping_')
  cppFunctionDefs[[newFunName]] <<- makeADtapingFunction(newFunName, 
                                                         regularFun, 
                                                         ADfunName, 
                                                         independentVarNames, 
                                                         dependentVarNames, 
                                                         isNode = FALSE, ##nfProc$isNode,
                                                         cppFunctionDefs)
  invisible(NULL)
},
addADmethodMacros = function(funName, args) {
  ## fun will be named foo_derivs_.
  newName <- paste0(funName, "_derivs_")
  cppFunctionDefs[[newName]] <<- cppADmethodMacroClass$new(name = newName,
                                                           base_name = funName,
                                                           args = args)
  self$functionNamesForInterface <<- c(self$functionNamesForInterface, newName)
  invisible(NULL)
},
        addADargumentTransferFunction = function( funName, independentVarNames ) {
            newFunName <- paste0(funName, '_ADargumentTransfer_')
            regularFun <- cppFunctionDefs[[funName]]
            funIndex <- which(NCinternals(self$Compiler$NCgenerator)$enableDerivs == funName) ## needed for correct index for allADtapePtrs_
            cppFunctionDefs[[newFunName]] <<- makeADargumentTransferFunction(newFunName,
                                                                          regularFun, 
                                                                          independentVarNames, 
                                                                          funIndex 
                                                                          #, parentsSizeAndDims #was relevant to nodeFuns
                                                                          )
        },
        addStaticInitClass = function() {
            neededCppDefs[['staticInitClass']] <<- makeStaticInitClass(self,
                                                                        NCinternals(self$Compiler$NCgenerator)$enableDerivs) ##
            invisible(NULL)
        },
        addADclassContentOneFun = function(funName) {
            outSym <- self$Compiler$NFcompilers[[funName]]$returnSymbol
            checkADargument(funName, outSym, returnType = TRUE)
            if(length(self$Compiler$NFcompilers[[funName]]$nameSubList) == 0)
              stop(paste0('Derivatives cannot be enabled for method ', 
                          funName, 
                          ', since this method has no arguments.'))
            ## Not updated:
            if(FALSE) {
              if(!nfProc$isNode){
                for(iArg in seq_along(functionDefs[[funName]]$args$symbols)){
                  arg <- functionDefs[[funName]]$args$symbols[[iArg]]
                  argSym <- nfProc$RCfunProcs[[funName]]$compileInfo$origLocalSymTab$getSymbolObject(arg$name)
                  argName <- names(nfProc$RCfunProcs[[funName]]$nameSubList)[iArg]
                  checkADargument(funName, argSym, argName = argName)
                }
              }
            }
            addTypeTemplateFunction(funName)
            independentVarNames <- self$cppFunctionDefs[[funName]]$args$getSymbolNames() ## Is this the right layer?
            if(FALSE)
              if(nfProc$isNode) independentVarNames <- independentVarNames[-1]  ## remove ARG1_INDEXEDNODEINFO__ from independentVars
            
            addADtapingFunction(funName,
                                independentVarNames = independentVarNames,
                                dependentVarNames = 'ANS_' )
            addADargumentTransferFunction(funName,
                                          independentVarNames = independentVarNames)
            addADmethodMacros(funName,
                              self$cppFunctionDefs[[funName]]$args)
        },
        checkADargument = function(funName, 
                                   argSym, 
                                   argName = NULL,
                                   returnType = FALSE){
            argTypeText <- if(returnType) 
            'returnType'
            else
              'argument'
            if(argSym$type != 'double')
                stop(paste0('The ', argName, ' ', argTypeText, ' of the ', funName, ' method is not a double.  Therefore this method cannot have derivatives enabled.'))
            if(!(argSym$nDim %in% c(0,1)))
                stop(paste0('The ', argName, ' ', argTypeText, ' of the ', funName, ' method must be a double scalar or double vector for derivatives to be enabled.'))
            if((argSym$nDim == 1) && is.na(argSym$size)) stop(paste0('To enable derivatives, size must be given for the ', argName, ' ', argTypeText, ' of the ', funName,
                                                                     ' method,  e.g. double(1, 3) for a length 3 vector.' ))
        },

        addADclassContent = function() {
           ## self$CPPincludes <- c("<cppad/cppad.hpp>", self$CPPincludes)
            self$Hincludes <- c(##"<cppad/cppad.hpp>",
                               nCompilerIncludeFile("nCompiler_CppAD.h"), Hincludes)
          ##  addInheritance("nFunctionCppADbase")
            self$symbolTable$addSymbol(cppVectorOfADFunPtr(name = 'allADtapePtrs_', static = TRUE))
            self$symbolTable$addSymbol(cppADinfo(name = 'ADtapeSetup'))
            for(adEnabledFun in NCinternals(self$Compiler$NCgenerator)$enableDerivs){
                addADclassContentOneFun(adEnabledFun)
            }
            ## static declaration in the class definition
            ## globals to hold the global static definition
            globals <- cppGlobalObjectClass$new(name = paste0('staticGlobals_', name),
                                                staticMembers = TRUE)
            globals$symbolTable$addSymbol(cppVectorOfADFunPtr(name = paste0(name,'::allADtapePtrs_')))
            neededCppDefs[['allADtapePtrs_']] <<- globals
            addStaticInitClass()
            invisible(NULL)
        },
        buildAll = function(where = where) {
            super$buildAll(where)
        }
    )
)

