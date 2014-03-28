use 5.010_000;
# Why Perl 5.10? mtwist needs a fairly "modern" compiler (see mtwist.h). Now
# what's the oldest Perl shipped together with a sufficiently recent compiler?
# If it comes to "old", Debian is the first choice. The oldest Debian capable
# of compiling mtwist is Lenny. Lenny ships Perl 5.10.0.

use Config;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Math::Random::MTwist',
  VERSION_FROM => 'lib/Math/Random/MTwist.pm',
  PREREQ_PM    => { 'Test::More' => 0 },
  INC          => '-I.',
  OBJECT       => '$(O_FILES)',
);

my $int64_type = $Config{ivsize} > 4 ? 'T_IV' : 'T_NV';
(my $uint64_type = $int64_type) =~ tr/I/U/;
open my $TMAP, '>', 'typemap';
print $TMAP <<EOTM;
mt_state*  O_OBJECT
int32_t    T_IV
uint32_t   T_UV
uint32_t*  T_PACKEDARRAY
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
