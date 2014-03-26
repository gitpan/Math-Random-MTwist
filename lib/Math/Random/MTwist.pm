package Math::Random::MTwist;

use 5.010_000;
use strict;
use warnings;

use Exporter 'import';
use Time::HiRes 'gettimeofday';

use constant {
  MT_TIMESEED => \0,
  MT_FASTSEED => \0,
  MT_GOODSEED => \0,
  MT_BESTSEED => \0,
};

our $VERSION = '0.02';

our %EXPORT_TAGS = ();
our @EXPORT = qw(
                  MT_TIMESEED
                  MT_FASTSEED
                  MT_GOODSEED
                  MT_BESTSEED
);
our @EXPORT_OK = @EXPORT;

require XSLoader;
XSLoader::load('Math::Random::MTwist', $VERSION);

sub new {
  my $class = shift;
  my $seed = shift;

  my $state = mts_newstate();
  my $self = bless \$state, $class;

  if (! defined $seed) {
    $self->fastseed();
  }
  elsif (! ref $seed) {
    $self->seed32($seed);
  }
  elsif (ref $seed eq 'ARRAY') {
    $self->seedfull($seed);
  }
  elsif ($seed == MT_TIMESEED) {
    $self->timeseed();
  }
  elsif ($seed == MT_FASTSEED) {
    $self->fastseed();
  }
  elsif ($seed == MT_GOODSEED) {
    $self->goodseed();
  }
  elsif ($seed == MT_BESTSEED) {
    $self->bestseed();
  }
  else { # WTF?
    $self->fastseed();
  }

  $self;
}

sub seed32 {
  mts_seed32new(${shift()}, shift);
}

sub seedfull {
  mts_seedfull(${shift()}, \@_);
}

sub timeseed {
  my ($sec, $usec) = gettimeofday();
  shift->seed32($sec * 1_000_000 + $usec);
}

sub fastseed {
  mts_seed(${shift()});
}

sub goodseed {
  mts_goodseed(${shift()});
}

sub bestseed {
  mts_bestseed(${shift()});
}

# Returns a 64-bit unsigned integer if the platform supports it (see irand64),
# otherwise a 32-bit one.
sub irand {
  mts_irand(${shift()});
}

# 32-bit unsigned integer pseudo-random number.
sub irand32 {
  mts_lrand(${shift()});
}

# 64-bit unsigned integer pseudo-random number.
# If Perl is 64-bit, returns a native integer (UV).
# If Perl is 32-bit but the OS knows the uint64_t type, returns a double (NV)
# Otherwise it returns undef.
sub irand64 {
  mts_llrand(${shift()});
}

# Random double in [0, $bound) generated from a random 64-bit int
sub rand {
  mts_ldrand(${shift()}) * (shift || 1);
}

# Random double in [0, $bound) generated from a random 32-bit int
# (faster than rand)
sub rand32 {
  mts_drand(${shift()}) * (shift || 1);
}

sub savestate {
  my $self = shift;
  my $file = shift; # name or handle

  my $fh = ref $file eq 'GLOB' ? $file : do {
    open my $fh, '>', $file or return 0;
    $fh;
  };
  mts_savestate($fh, $$self);
}

sub loadstate {
  my $self = shift;
  my $file = shift;

  my $fh = ref $file eq 'GLOB' ? $file : do {
    open my $fh, '<', $file or return 0;
    $fh;
  };
  mts_loadstate($fh, $$self);
}

sub rds_exponential {
  _rds_exponential(${shift()}, @_);
}

sub rds_lexponential {
  _rds_lexponential(${shift()}, @_);
}

sub rds_erlang {
  _rds_erlang(${shift()}, @_);
}

sub rds_lerlang {
  _rds_lerlang(${shift()}, @_);
}

sub rds_weibull {
  _rds_weibull(${shift()}, @_);
}

sub rds_lweibull {
  _rds_lweibull(${shift()}, @_);
}

sub rds_normal {
  _rds_normal(${shift()}, @_);
}

sub rds_lnormal {
  _rds_lnormal(${shift()}, @_);
}

sub rds_lognormal {
  _rds_lognormal(${shift()}, @_);
}

sub rds_llognormal {
  _rds_llognormal(${shift()}, @_);
}

sub rds_triangular {
  _rds_triangular(${shift()}, @_);
}

sub rds_ltriangular {
  _rds_ltriangular(${shift()}, @_);
}

sub DESTROY {
  mts_freestate(${shift()});
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Math::Random::MTwist - A fast stateful Mersenne Twister pseudo-random number
generator

=head1 SYNOPSIS

  use Math::Random::MTwist;

  my $mt = Math::Random::MTwist->new();  # seed from /dev/urandom
  my $int = $mt->irand();                # [0 .. 2^64-1 or 2^32-1]
  my $double = $mt->rand(73);            # [0 .. 73)
  $mt->goodseed();                       # seed from /dev/random
  $mt->savestate("/tmp/foobar");         # save current state to file
  $mt->loadstate("/tmp/foobar");         # load past state from file
  my @dist = map $mt->rds_triangular(1, 3, 2), 1 .. 1e3;  # triangular dist.

=head1 DESCRIPTION

Math::Random::MTwist is an object-oriented Perl interface to Geoff Kuenning's
mtwist C library. It provides several seeding methods, an independent state per
instance and various random number distributions.

Random number generation is significantly faster than with Math::Random::MT
(kudos to Geoff).

This module is not C<fork()/clone()> aware, i.e. you have to take care of
re-seeding/re-instantiating in new processes/threads yourself.

=head1 CONSTRUCTOR

=head2 new()

Takes an optional argument specifying the seed. The seed can be a number (will
be coerced into an unsigned 32-bit integer), an array reference holding up to
624 such numbers (missing values are padded with zeros, excess values are
ignored) or one of the special values C<MT_TIMESEED>, C<MT_FASTSEED>,
C<MT_GOODSEED> or C<MT_BESTSEED> that choose one of the corresponding seeding
methods (see below). If no seed is given, C<MT_FASTSEED> is assumed.

Each instance maintains an individual PRNG state allowing multiple independent
random number streams.

=head1 SEEDING

=head2 seed32($number)

Seeds the generator with C<$number>. The value will be coerced into an unsigned
32-bit integer. Calls mtwist's C<mts_seed32new()>.

=head2 seedfull($arrayref)

Seeds the generator with up to 624 numbers from C<$arrayref>. The values are
coerced into unsigned 32-bit integers. Missing values are padded with zeros,
excess values are ignored. Calls mtwist's C<mts_seedfull()>.

=head2 timeseed()

Seeds the generator from the current system time obtained with
C<gettimeofday()> by calculating C<seconds * 1e6 + microseconds> and coercing
the result into an unsigned 32-bit integer.

This method is called by C<new(MT_TIMESEED)>.

It doesn't correspond to any of mtwist's functions. The rationale behind it is
that mtwist falls back to the system time if neither C</dev/urandom> nor
C</dev/random> is available. On Windows the time source chosen by mtwist has
only millisecond resolution in contrast to microseconds from
C<Time::HiRes::gettimeofday()>.

=head2 fastseed()

Seeds the generator with 4 bytes read from C</dev/urandom> if available,
otherwise from the system time (see details under C<timeseed()>). Calls
mtwist's C<mts_seed()>.

This method is called by C<new(MT_FASTSEED)>.

=head2 goodseed()

Seeds the generator with 4 bytes read from C</dev/random> if available,
otherwise from the system time (see details under C<timeseed()>). Calls
mtwist's C<mts_goodseed()>.

This method is called by C<new(MT_GOODSEED)>.

=head2 bestseed()

Seeds the generator with 642 integers read from C</dev/random> if
available. This might take a very long time and is probably not worth the
waiting. If C</dev/random> is unavailable or there was a reading error it falls
back to C<goodseed()>. Calls mtwist's C<mts_bestseed()>.

This method is called by C<new(MT_BESTSEED)>.

=head1 STATE HANDLING

=head2 savestate($filename or $filehandle)

Saves the current state of the generator to a file given either by a filename
(file will be truncated) or an open Perl file handle.

Returns 1 on success, 0 on error (you might want to check C<$!> in this case).

=head2 loadstate($filename or $filehandle)

Loads the state of the generator from a file given either by a filename or an
open Perl file handle.

Returns 1 on success, 0 on error (you might want to check C<$!> in this case).

=head1 UNIFORMLY DISTRIBUTED RANDOM NUMBERS

=head2 irand()

Returns a random unsigned integer, 64-bit if your system supports it (see
C<irand64()>), 32-bit otherwise.

=head2 irand32()

Returns a random unsigned 32-bit integer. Calls mtwist's C<mts_lrand()>.

=head2 irand64()

If your Perl is 64-bit, returns a 64-bit unsigned integer. If your Perl is
32-bit but your OS knows the C<uint64_t> type, returns a 64-bit unsigned
integer coerced into a double (so it's the full 64-bit range but with only
52-bit precision). Otherwise it returns undef. Calls mtwist's C<mts_llrand()>.

=head2 rand($bound)

Returns a random double with 52-bit precision in the range C<[0, $bound)>.
Calls mtwist's C<mts_ldrand()>.

C<$bound> may be negative. If C<$bound> is omitted or zero it defaults to 1.

=head2 rand32($bound)

Returns a random double with 32-bit precision in the range C<[0, $bound)>.
Slightly faster than rand(). Calls mtwist's C<mts_drand()>.

C<$bound> may be negative. If C<$bound> is omitted or zero it defaults to 1.

=head1 NON-UNIFORMLY DISTRIBUTED RANDOM NUMBERS

The following methods come in two variants: C<B<rds_>xxx> and
C<B<rds_l>xxx>. They all return a double but the C<B<rds_>xxx> versions provide
32-bit precision while the C<B<rds_l>xxx> versions provide 52-bit precision at
the expense of speed.

=head2 rds_(l)exponential(double mean)

Generates an exponential distribution with the given mean.

=head2 rds_(l)erlang(int p, double mean)

Generates a p-Erlang distribution with the given mean.

=head2 rds_(l)weibull(double shape, double scale)

Generates a Weibull distribution with the given shape and scale.

=head2 rds_(l)normal(double mean, double sigma)

Generates a normal (Gaussian) distribution with the given mean and standard
deviation sigma.

=head2 rds_(l)lognormal(double shape, double scale)

Generates a log-normal distribution with the given shape and scale.

=head2 rds_(l)triangular(double lower, double upper, double mode)

Generates a triangular distribution in the range C<[lower, upper)> with the
given mode.

=head1 EXPORTS

The module exports the constants MT_TIMESEED, MT_FASTSEED, MT_GOODSEED and
MT_BESTSEED that can be used as an argument to the constructor.

=head1 SEE ALSO

L<http://www.cs.hmc.edu/~geoff/mtwist.html>

=head1 AUTHOR

Carsten Gaebler (cgpan ʇɐ gmx ʇop de). I only accept encrypted e-mails, either
via L<SMIME|http://cpan.org/authors/id/C/CG/CGPAN/cgpan-smime.crt> or
L<GPG|http://cpan.org/authors/id/C/CG/CGPAN/cgpan-gpg.asc>.

=head1 COPYRIGHT

Perl and XS portion: Copyright © 2014 by Carsten Gaebler.

mtwist C library: Copyright © 2001, 2002, 2010, 2012, 2013 by Geoff Kuenning.

=head1 LICENSE

Perl and XS portion: L<Do What The Fuck You Want To Public
License|http://wtfpl.net/>.

mtwist C library: L<LGPL|https://gnu.org/licenses/lgpl.html>

=cut
