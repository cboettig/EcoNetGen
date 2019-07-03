#include <R.h>
#include <R_ext/Rdynload.h>
#include <Rversion.h>

void F77_SUB(rndstart)(void) { GetRNGstate(); }
void F77_SUB(rndend)(void) { PutRNGstate(); }
double F77_SUB(unifrnd)(void) { return unif_rand(); }

void F77_SUB(subnetgen)(int *, int *, int *, int *,double *, double *, double *, int *);
void F77_SUB(clusters)(int *, int *, int *, int *);
void F77_SUB(subsampling)(int *, int *, int *, int *, double *,
                          int *, int *, int *, int *, int *, int *, int *);

static R_FortranMethodDef R_FortranDef[] = {
  {"rndstart",  (DL_FUNC) &F77_SUB(rndstart),  0, NULL},
  {"rndend",  (DL_FUNC) &F77_SUB(rndend),  0, NULL},
  {"unifrnd",  (DL_FUNC) &F77_SUB(unifrnd),  0, NULL},
  {"subnetgen",  (DL_FUNC) &F77_SUB(subnetgen),  8, NULL},
  {"clusters",  (DL_FUNC) &F77_SUB(clusters),  4, NULL},
  {"subsampling",  (DL_FUNC) &F77_SUB(subsampling),  12, NULL},

  {NULL, NULL, 0, NULL}
};


void R_init_NetGen(DllInfo *dll) {
  R_registerRoutines(dll, NULL, NULL, R_FortranDef, NULL);
#if defined(R_VERSION) && R_VERSION >= R_Version(3, 3, 0)
  R_useDynamicSymbols(dll, FALSE);
#endif
}
