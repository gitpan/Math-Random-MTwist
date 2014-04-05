#!/usr/bin/perl

use strict;
use warnings;
use Math::Random::MTwist qw(:rand :seed :dist);
use Test::More tests => 17;

srand(1_000_686_894);

# If you change the order of the tests the expected results will change!

ok(irand32() == 2_390_553_143, 'irand32');
{
  my $i = irand64();
  ok(!defined $i || $i == 5_527_845_158, 'irand64');
}
ok(rand()   =~ /^0\.9457734/, 'rand');
ok(rand32() =~ /^0\.3981395/, 'rand32');

ok(rd_erlang(2, 1)  =~ /^1\.2556495/, 'rd_erlang');
ok(rd_lerlang(2, 1) =~ /^0\.3129639/, 'rd_lerlang');

ok(rd_exponential(1)  =~ /^1\.3165971/, 'rd_exponential');
ok(rd_lexponential(1) =~ /^0\.3011559/, 'rd_lexponential');

ok(rd_lognormal(1, 0)  =~ /^0\.8843699/, 'rd_lognormal');
ok(rd_llognormal(1, 0) =~ /^1\.2886502/, 'rd_llognormal');

ok(rd_normal(5, 1)  =~ /^3\.4375795/, 'rd_normal');
ok(rd_lnormal(5, 1) =~ /^4\.8138142/, 'rd_lnormal');

ok(rd_triangular(0, 2, 1)  =~ /^1\.0779715/, 'rd_triangular');
ok(rd_ltriangular(0, 2, 1) =~ /^1\.3103709/, 'rd_ltriangular');

ok(rd_weibull(1.5, 1)  =~ /^0\.7575942/, 'rd_weibull');
ok(rd_lweibull(1.5, 1) =~ /^0\.5284899/, 'rd_lweibull');

ok(rd_double() =~ /^8.6196948.+e-145$/, 'rd_double');

