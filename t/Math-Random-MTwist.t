#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
BEGIN { use_ok('Math::Random::MTwist') };

my $mt = Math::Random::MTwist->new(1_000_686_894);

cmp_ok($mt->irand32(), '==',  2_390_553_143, 'irand32');
cmp_ok($mt->irand64(), '==',  5_527_845_158, 'irand64');
like($mt->rand(),   qr/^0\.9457734/, 'rand');
like($mt->rand32(), qr/^0\.3981395/, 'rand32');
