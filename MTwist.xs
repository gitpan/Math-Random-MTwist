#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdio.h>

#include "mtwist/mtwist.c"
#include "mtwist/randistrs.c"

MODULE = Math::Random::MTwist		PACKAGE = Math::Random::MTwist		

PROTOTYPES: ENABLE

mt_state*
_mts_newstate(char* CLASS)
  CODE:
    Newxz(RETVAL, 1, mt_state);
    if (RETVAL == NULL)
      croak("Could not allocate state memory");
  OUTPUT:
    RETVAL

void
DESTROY(mt_state* state)
  PPCODE:
    Safefree(state);

void
seed32(mt_state* state, uint32_t seed)
  PPCODE:
    mts_seed32new(state, seed);

uint32_t
fastseed(mt_state* state)
  CODE:
    RETVAL = mts_seed(state);
  OUTPUT:
    RETVAL

uint32_t
goodseed(mt_state* state)
  CODE:
    RETVAL = mts_goodseed(state);
  OUTPUT:
    RETVAL

void
bestseed(mt_state* state)
  PPCODE:
    mts_bestseed(state);

void
seedfull(mt_state* state, AV* seeds)
  INIT:
    int had_nz = 0;
    I32 i, top_index;
    SV** seed;
    uint32_t mt_seed;
    uint32_t mt_seeds[MT_STATE_SIZE];
  PPCODE:
     top_index = av_len(seeds);
     for (i = 0; i < MT_STATE_SIZE; i++) {
       if (i <= top_index) {
         seed = av_fetch(seeds, i, 0);
         mt_seed = (seed != NULL) ? (uint32_t)SvUV(*seed) : 0;
         mt_seeds[i] = mt_seed;
         if (mt_seed != 0)
           had_nz++;
       }
       else {
         mt_seeds[i] = 0;
       }
     }
     if (! had_nz)
       croak("Need at least one non-zero seed value");
     mts_seedfull(state, mt_seeds);

#if defined(UINT64_MAX)
uint64_t
irand(mt_state* state)
  ALIAS:
    irand64 = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = mts_llrand(state);
  OUTPUT:
    RETVAL

#else
uint32_t
irand(mt_state* state)
  ALIAS:
    irand64 = 1
  CODE:
    if (ix == 0)
      RETVAL = mts_lrand(state);
    else
      XSRETURN_UNDEF;
  OUTPUT:
    RETVAL

#endif

uint32_t
irand32(mt_state* state)
  CODE:
    RETVAL = mts_lrand(state);
  OUTPUT:
    RETVAL

double
rand(mt_state* state, double bound = 1)
  ALIAS:
    rand32 = 1
  CODE:
    if (bound == 0)
      bound = 1;
    RETVAL = (ix == 0 ? mts_ldrand(state) : mts_drand(state)) * bound;
  OUTPUT:
    RETVAL

int
mts_savestate(mt_state* state, PerlIO* pio)
  INIT:
    FILE* file = PerlIO_exportFILE(pio, NULL);
  CODE:
    RETVAL = mts_savestate(file, state);
    fflush(file);
    PerlIO_releaseFILE(pio, file);
  OUTPUT:
    RETVAL

int
mts_loadstate(mt_state* state, PerlIO* pio)
  INIT:
    FILE* file = PerlIO_exportFILE(pio, NULL);
  CODE:
    RETVAL = mts_loadstate(file, state);
    PerlIO_releaseFILE(pio, file);
  OUTPUT:
    RETVAL

double
rds_exponential(mt_state* state, double mean);
  ALIAS:
    rds_lexponential = 1
  CODE:
      RETVAL = (ix == 0) ? rds_exponential(state, mean)
                         : rds_lexponential(state, mean);
  OUTPUT:
    RETVAL

double
rds_erlang(mt_state* state, int k, double mean);
  ALIAS:
    rds_lerlang = 1
  CODE:
      RETVAL = (ix == 0) ? rds_erlang(state, k, mean)
                         : rds_lerlang(state, k, mean);
  OUTPUT:
    RETVAL

double
rds_weibull(mt_state* state, double shape, double scale);
  ALIAS:
    rds_lweibull = 1
    rds_lognormal = 2
    rds_llognormal = 3
  CODE:
    switch (ix) {
      case 0:  RETVAL = rds_weibull(state, shape, scale); break;
      case 1:  RETVAL = rds_lweibull(state, shape, scale); break;
      case 2:  RETVAL = rds_lognormal(state, shape, scale); break;
      default: RETVAL = rds_llognormal(state, shape, scale); break;
    }
  OUTPUT:
    RETVAL

double
rds_normal(mt_state* state, double mean, double sigma);
  ALIAS:
    rds_lnormal = 1
  CODE:
      RETVAL = (ix == 0) ? rds_normal(state, mean, sigma)
                         : rds_lnormal(state, mean, sigma);
  OUTPUT:
    RETVAL

double
rds_triangular(mt_state* state, double lower, double upper, double mode);
  ALIAS:
    rds_ltriangular = 1
  CODE:
      RETVAL = (ix == 0) ? rds_triangular(state, lower, upper, mode)
                         : rds_ltriangular(state, lower, upper, mode);
  OUTPUT:
    RETVAL
