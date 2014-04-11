use 5.010_000;  # see README
use Config;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Math::Random::MTwist',
  AUTHOR        => 'Carsten Gaebler',
  ABSTRACT_FROM => 'lib/Math/Random/MTwist.pm',
  VERSION_FROM  => 'lib/Math/Random/MTwist.pm',
  MIN_PERL_VERSION => '5.010000',
  PREREQ_PM     => { 'Time::HiRes' => 0 },
  TEST_REQUIRES => { 'Test::More' => 0 },
  INC           => '-I.',
  OBJECT        => '$(O_FILES)',
  dist          => { TARFLAGS => '--numeric-owner -cvpf' },
);

my $int64_type = $Config{ivsize} > 4 ? 'T_IV' : 'T_NV';
(my $uint64_type = $int64_type) =~ tr/I/U/;
open my $TMAP, '>', 'typemap';
print $TMAP <<EOTM;
mt_state*  O_OBJECT
int32_t    T_IV
uint32_t   T_UV
int64_t    $int64_type
uint64_t   $uint64_type
EOTM

print $TMAP q(
OUTPUT
O_OBJECT
  sv_setref_pv( $arg, CLASS, (void*)$var );

INPUT
O_OBJECT
  if( sv_isobject($arg) && (SvTYPE(SvRV($arg)) == SVt_PVMG) )
    $var = ($type)SvIV((SV*)SvRV( $arg ));
  else {
    warn( \"${Package}::$func_name() -- $var is not a blessed SV reference\" );
    XSRETURN_UNDEF;
  }
);
