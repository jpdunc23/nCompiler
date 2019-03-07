#include <nCompiler/nCompiler_class_interface.h>
#include <nCompiler/shared_ptr_holder.h>
#include <Rcpp.h>

inline genericInterfaceBaseC *get_genericInterfaceBaseC(SEXP Xptr) {
  return reinterpret_cast<genericInterfaceBaseC*>(
						  reinterpret_cast<shared_ptr_holder_base*>(R_ExternalPtrAddr(Xptr))->get_ptr()
						  );
}

// This is completely generic, good for all derived classes
// [[Rcpp::export]]
SEXP get_value(SEXP Xptr, const std::string &name) {
  genericInterfaceBaseC *obj =
    get_genericInterfaceBaseC(Xptr);
  //  std::cout << name << std::endl;
  return(obj->get_value( name ));
}

// This is completely generic, good for all derived classes
// [[Rcpp::export]]
SEXP set_value(SEXP Xptr, const std::string &name, SEXP Svalue) {
  genericInterfaceBaseC *obj =
    get_genericInterfaceBaseC(Xptr);
  //std::cout << name << std::endl;
  obj->set_value( name, Svalue );
  return(R_NilValue);
}

// This is completely generic, good for all derived classes
// [[Rcpp::export]]
SEXP call_method(SEXP Xptr, const std::string &name, SEXP Sargs) {
  genericInterfaceBaseC *obj =
    get_genericInterfaceBaseC(Xptr);
  //  std::cout << name << std::endl;
  return(obj->call_method( name, Sargs ));
}
