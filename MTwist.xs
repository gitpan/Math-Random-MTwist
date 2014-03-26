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
mts_newstate()
  INIT:
    mt_state* state = NULL;
  CODE:
    Newxz(state, 1, mt_state);
    if (state == NULL)
      croak("Could not allocate state memory");
    RETVAL = state;
  OUTPUT:
    RETVAL

void
mts_freestate(mt_state* state)
  PPCODE:
    Safefree(state);

void
mts_seed32new(mt_state* state, uint32_t seed)

uint32_t
mts_seed(mt_state* state)

uint32_t
mts_goodseed(mt_state* state)

void
mts_bestseed(mt_state* state)

void
mts_seedfull(mt_state* state, AV* seeds)
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

uint32_t
mts_lrand(mt_state* state)

#if defined(UINT64_MAX)
uint64_t
mts_llrand(mt_state* state)

uint64_t
mts_irand(mt_state* state)
  CODE:
    RETVAL = mts_llrand(state);
  OUTPUT:
    RETVAL

#else
void
mts_llrand(mt_state* state)
  PPCODE:

uint32_t
mts_irand(mt_state* state)
  CODE:
    RETVAL = mts_lrand(state);
  OUTPUT:
    RETVAL

#endif

double
mts_drand(mt_state* state)

double
mts_ldrand(mt_state* state)

int
mts_savestate(PerlIO* pio, mt_state* state)
  INIT:
    FILE* file = PerlIO_exportFILE(pio, NULL);
  CODE:
    RETVAL = mts_savestate(file, state);
    fflush(file);
    PerlIO_releaseFILE(pio, file);
  OUTPUT:
    RETVAL

int
mts_loadstate(PerlIO* pio, mt_state* state)
  INIT:
    FILE* file = PerlIO_exportFILE(pio, NULL);
  CODE:
    RETVAL = mts_loadstate(file, state);
    PerlIO_releaseFILE(pio, file);
  OUTPUT:
    RETVAL

double
_rds_exponential(mt_state* state, double mean);
  ALIAS:
    _rds_lexponential = 1
  CODE:
      RETVAL = (ix == 0) ? rds_exponential(state, mean)
                         : rds_lexponential(state, mean);
  OUTPUT:
    RETVAL

double
_rds_erlang(mt_state* state, int p, double mean);
  ALIAS:
    _rds_lerlang = 1
  CODE:
      RETVAL = (ix == 0) ? rds_erlang(state, p, mean)
                         : rds_lerlang(state, p, mean);
  OUTPUT:
    RETVAL

double
_rds_weibull(mt_state* state, double shape, double scale);
  ALIAS:
    _rds_lweibull = 1
    _rds_lognormal = 2
    _rds_llognormal = 3
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
_rds_normal(mt_state* state, double mean, double sigma);
  ALIAS:
    _rds_lnormal = 1
  CODE:
      RETVAL = (ix == 0) ? rds_normal(state, mean, sigma)
                         : rds_lnormal(state, mean, sigma);
  OUTPUT:
    RETVAL

double
_rds_triangular(mt_state* state, double lower, double upper, double mode);
  ALIAS:
    _rds_ltriangular = 1
  CODE:
      RETVAL = (ix == 0) ? rds_triangular(state, lower, upper, mode)
                         : rds_ltriangular(state, lower, upper, mode);
  OUTPUT:
    RETVAL
