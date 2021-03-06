#' Compile a nClass.
#'
#' Generates C++ for the compilable data and methods of a nClass,
#' manages C++ compilation of them and returns a generator for obejcts
#' of the compiled class.
#'
#' @param NC A nClass generator (returned from a call to \code{\link{nClass}}).
#'
#' @param dir Directory where generated C++ will be written.
#'
#' @param cacheDir Directory to be used for Rcpp cache.
#' 
#' @param env Environment to be used for loading results of compilation.
#'
#' @param control List of control settings for compilation.  See...
#'
#' @return Generator of objects of the compiled version of class
#'     \code{NC}.  These will use C++ objects internally for compiled
#'     data and methods.
#' 
#' @export
nCompile_nClass <- function(NC,
                               dir = file.path(tempdir(), 'nCompiler_generatedCode'),
                               cacheDir = file.path(tempdir(), 'nCompiler_RcppCache'),
                               env = parent.frame(),
                               control = list(),
                               interface = c("full", "generic", "both"),
                               ...) {
    controlFull <- updateDefaults(
        get_nOption('compilerOptions'),
        control
    )
    ## Make a new compiler object
    NC_Compiler <- NC_CompilerClass$new(NC)
    ## Use the compiler to generate a cppDef
    NC_Compiler$createCpp(control = controlFull)
    ## Get the cppDef
    cppDef <- NC_Compiler$cppDef
    ##
    cppDef$buildSEXPgenerator()
    if(get_nOption('serialize'))
      cppDef$addSerialization()
    if(get_nOption('automaticDerivatives'))
      cppDef$addADclassContent()
    cppDef$addGenericInterface()
    if(NFcompilerMaybeStop('writeCpp', controlFull))
      return(cppDef)
    filebase <- controlFull$filename
    
    if(is.null(filebase))
      filebase <- Rname2CppName(cppDef$name)
    RcppPacket <- cppDefs_2_RcppPacket(cppDef,
                                       filebase = filebase)
    NCinternals(NC)$RcppPacket <- RcppPacket
    newCobjFun <- cpp_nCompiler(RcppPacket,
                            dir = dir,
                            cacheDir = cacheDir,
                            env = env,
                            write = !NFcompilerMaybeStop('writeCpp', controlFull),
                            compile = !NFcompilerMaybeStop('compileCpp', controlFull),
                            ...)
    if(NFcompilerMaybeStop('compileCpp', controlFull)) {
      return(newCobjFun)
    }
    interface <- match.arg(interface)
    if(interface == "generic")
      return(newCobjFun)
    ## To Do: Only "generic" works when more than one function will be returned from sourceCpp in cpp_nCompiler.  That occurs with serialization turned on.
    fullInterface <- build_compiled_nClass(NC, newCobjFun, env = env)
    if(interface == "full")
      return(fullInterface)
    ## interface is "both"
    return(list(full = fullInterface, generic = newCobjFun))
}
