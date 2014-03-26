use 5.010_000;
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
mt_state*  T_PTR
int32_t    T_IV
uint32_t   T_UV
int64_t    $int64_type
uint64_t   $uint64_type
EOTM
