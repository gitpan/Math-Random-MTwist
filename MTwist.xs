#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdio.h>
#include <string.h>

#include "mtwist/mtwist.c"
#include "mtwist/randistrs.c"

/*
  We copy the seeds from an array reference to a buffer so that mtwist can
  copy the buffer to another buffer. No wonder that computer power must double
  every two years ...
*/
void get_seeds_from_av(AV* av_seeds, uint32_t* mt_seeds) {
  dTHX;

  int had_nz = 0;
  I32 i, top_index;
  SV** av_seed;
  uint32_t mt_seed;

  top_index = av_len(av_seeds);  // Top array index, not array length!
  if (top_index >= MT_STATE_SIZE)
    top_index = MT_STATE_SIZE - 1;

  for (i = 0; i <= top_index; i++) {
    av_seed = av_fetch(av_seeds, i, 0);
    mt_seed = (av_seed != NULL) ? (uint32_t)SvUV(*av_seed) : 0;
    mt_seeds[i] = mt_seed;
    if (mt_seed != 0)
      had_nz++;
  }

  if (! had_nz) {
    Safefree(mt_seeds);
    croak("seedfull(): Need at least one non-zero seed value");
  }
}

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

uint32_t
seed32(mt_state* state, uint32_t seed)
  CODE:
    mts_seed32new(state, seed);
    RETVAL = seed;
  OUTPUT:
    RETVAL

uint32_t
_seed32(uint32_t seed)
  CODE:
    mt_seed32new(seed);
    RETVAL = seed;
  OUTPUT:
    RETVAL

uint32_t
srand(mt_state* state, uint32_t seed = 0)
  CODE:
    if (items == 1)
      RETVAL = mts_seed(state);
    else {
      mts_seed32new(state, seed);
      RETVAL = seed;
    }
  OUTPUT:
    RETVAL

uint32_t
_srand(uint32_t seed = 0)
  CODE:
    if (items == 0)
      RETVAL = mt_seed();
    else {
      mt_seed32new(seed);
      RETVAL = seed;
    }
  OUTPUT:
    RETVAL

uint32_t
fastseed(mt_state* state)
  CODE:
    RETVAL = mts_seed(state);
  OUTPUT:
    RETVAL

uint32_t
_fastseed()
  CODE:
    RETVAL = mt_seed();
  OUTPUT:
    RETVAL

uint32_t
goodseed(mt_state* state)
  CODE:
    RETVAL = mts_goodseed(state);
  OUTPUT:
    RETVAL

uint32_t
_goodseed()
  CODE:
    RETVAL = mt_goodseed();
  OUTPUT:
    RETVAL

void
bestseed(mt_state* state)
  PPCODE:
    mts_bestseed(state);

void
_bestseed()
  PPCODE:
    mt_bestseed();

# The seeds come from XS_unpack_uint32_tPtr
void
seedfull(mt_state* state, AV* seeds)
  INIT:
    uint32_t mt_seeds[MT_STATE_SIZE] = { 0 };
  PPCODE:
    get_seeds_from_av(seeds, mt_seeds);
    mts_seedfull(state, mt_seeds);

void
_seedfull(AV* seeds)
  INIT:
    uint32_t mt_seeds[MT_STATE_SIZE] = { 0 };
  PPCODE:
    get_seeds_from_av(seeds, mt_seeds);
    mt_seedfull(mt_seeds);

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

uint64_t
_irand()
  ALIAS:
    _irand64 = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = mt_llrand();
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

uint32_t
_irand()
  ALIAS:
    _irand64 = 1
  CODE:
    if (ix == 0)
      RETVAL = mt_lrand(state);
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

uint32_t
_irand32()
  CODE:
    RETVAL = mt_lrand();
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

double
_rand(double bound = 1)
  ALIAS:
    _rand32 = 1
  CODE:
    if (bound == 0)
      bound = 1;
    RETVAL = (ix == 0 ? mt_ldrand() : mt_drand()) * bound;
  OUTPUT:
    RETVAL

double
rd_exponential(mt_state* state, double mean);
  ALIAS:
    rd_lexponential = 1
  CODE:
      RETVAL = (ix == 0) ? rds_exponential(state, mean)
                         : rds_lexponential(state, mean);
  OUTPUT:
    RETVAL

double
_rd_exponential(double mean);
  ALIAS:
    _rd_lexponential = 1
  CODE:
      RETVAL = (ix == 0) ? rd_exponential(mean)
                         : rd_lexponential(mean);
  OUTPUT:
    RETVAL

double
rd_erlang(mt_state* state, int k, double mean);
  ALIAS:
    rd_lerlang = 1
  CODE:
      RETVAL = (ix == 0) ? rds_erlang(state, k, mean)
                         : rds_lerlang(state, k, mean);
  OUTPUT:
    RETVAL

double
_rd_erlang(int k, double mean);
  ALIAS:
    _rd_lerlang = 1
  CODE:
      RETVAL = (ix == 0) ? rd_erlang(k, mean)
                         : rd_lerlang(k, mean);
  OUTPUT:
    RETVAL

double
rd_weibull(mt_state* state, double shape, double scale);
  ALIAS:
    rd_lweibull = 1
    rd_lognormal = 2
    rd_llognormal = 3
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
_rd_weibull(double shape, double scale);
  ALIAS:
    _rd_lweibull = 1
    _rd_lognormal = 2
    _rd_llognormal = 3
  CODE:
    switch (ix) {
      case 0:  RETVAL = rd_weibull(shape, scale); break;
      case 1:  RETVAL = rd_lweibull(shape, scale); break;
      case 2:  RETVAL = rd_lognormal(shape, scale); break;
      default: RETVAL = rd_llognormal(shape, scale); break;
    }
  OUTPUT:
    RETVAL

double
rd_normal(mt_state* state, double mean, double sigma);
  ALIAS:
    rd_lnormal = 1
  CODE:
      RETVAL = (ix == 0) ? rds_normal(state, mean, sigma)
                         : rds_lnormal(state, mean, sigma);
  OUTPUT:
    RETVAL

double
_rd_normal(double mean, double sigma);
  ALIAS:
    _rd_lnormal = 1
  CODE:
      RETVAL = (ix == 0) ? rd_normal(mean, sigma)
                         : rd_lnormal(mean, sigma);
  OUTPUT:
    RETVAL

double
rd_triangular(mt_state* state, double lower, double upper, double mode);
  ALIAS:
    rd_ltriangular = 1
  CODE:
      RETVAL = (ix == 0) ? rds_triangular(state, lower, upper, mode)
                         : rds_ltriangular(state, lower, upper, mode);
  OUTPUT:
    RETVAL

double
_rd_triangular(double lower, double upper, double mode);
  ALIAS:
    _rd_ltriangular = 1
  CODE:
      RETVAL = (ix == 0) ? rd_triangular(lower, upper, mode)
                         : rd_ltriangular(lower, upper, mode);
  OUTPUT:
    RETVAL

#define MT_OPEN_FILE(file_sv, mode, pio, fh) {                       \
    if (! SvOK(file_sv)) {                                           \
      warn("File name or handle expected");                          \
    }                                                                \
    else if (SvROK(file_sv) && SvTYPE(SvRV(file_sv)) == SVt_PVGV) {  \
      pio = IoIFP(sv_2io(file_sv));                                  \
      fh = PerlIO_exportFILE(pio, NULL);                             \
    }                                                                \
    else {                                                           \
      fh = fopen(SvPV_nolen(file_sv), mode);                         \
    }                                                                \
}

int
savestate(mt_state* state, SV* file_sv)
  INIT:
    PerlIO* pio = NULL;
    FILE* fh = NULL;
  CODE:
    RETVAL = 0;
    MT_OPEN_FILE(file_sv, "w", pio, fh);
    if (fh) {
      RETVAL = mts_savestate(fh, state);
      if (pio) {
        fflush(fh);
        PerlIO_releaseFILE(pio, fh);
      }
      else
        fclose(fh);
    }
  OUTPUT:
    RETVAL

int
_savestate(SV* file_sv)
  INIT:
    PerlIO* pio = NULL;
    FILE* fh = NULL;
  CODE:
    RETVAL = 0;
    MT_OPEN_FILE(file_sv, "w", pio, fh);
    if (fh) {
      RETVAL = mt_savestate(fh);
      if (pio) {
        fflush(fh);
        PerlIO_releaseFILE(pio, fh);
      }
      else
        fclose(fh);
    }
  OUTPUT:
    RETVAL

int
loadstate(mt_state* state, SV* file_sv)
  INIT:
    PerlIO* pio = NULL;
    FILE* fh = NULL;
  CODE:
    RETVAL = 0;
    MT_OPEN_FILE(file_sv, "r", pio, fh);
    if (fh) {
      RETVAL = mts_loadstate(fh, state);
      if (pio)
        PerlIO_releaseFILE(pio, fh);
      else
        fclose(fh);
    }
  OUTPUT:
    RETVAL

int
_loadstate(SV* file_sv)
  INIT:
    PerlIO* pio = NULL;
    FILE* fh = NULL;
  CODE:
    RETVAL = 0;
    MT_OPEN_FILE(file_sv, "r", pio, fh);
    if (fh) {
      RETVAL = mt_loadstate(fh);
      if (pio)
        PerlIO_releaseFILE(pio, fh);
      else
        fclose(fh);
    }
  OUTPUT:
    RETVAL

