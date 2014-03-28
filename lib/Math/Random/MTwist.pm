package Math::Random::MTwist;

use 5.010_000;
use strict;
use warnings;

use Exporter;
use Time::HiRes 'gettimeofday';
use XSLoader;

use constant {
  MT_TIMESEED => \0,
  MT_FASTSEED => \0,
  MT_GOODSEED => \0,
  MT_BESTSEED => \0,
};

our $VERSION = '0.04';

our @ISA = 'Exporter';
our @EXPORT = qw(MT_TIMESEED MT_FASTSEED MT_GOODSEED MT_BESTSEED);
our @EXPORT_OK = @EXPORT;
our %EXPORT_TAGS = (
  'seed' => [qw(seed32 seedfull timeseed fastseed goodseed bestseed)],
  'rand' => [qw(srand rand rand32 rand64 irand irand32 irand64)],
  'dist' => [qw(
                 rd_erlang rd_lerlang
                 rd_exponential rd_lexponential
                 rd_lognormal rd_llognormal
                 rd_normal rd_lnormal
                 rd_triangular rd_ltriangular
                 rd_weibull rd_lweibull
             )],
  'state' => [qw(savestate loadstate)],
);

XSLoader::load('Math::Random::MTwist', $VERSION);

sub import {
  my $this = shift;

  my $caller = caller;
  my $srand_called = 0;

  my $importable_subs = join '|', map @$_, values %EXPORT_TAGS;
  $importable_subs = qr/^(?:$importable_subs)$/;

  my @remaining_args;
  while (defined(my $arg = shift)) {
    if ($arg =~ /^:(.+)/ && exists $EXPORT_TAGS{$1}) {
      push @_, @{$EXPORT_TAGS{$1}};
    }
    elsif ($arg =~ $importable_subs) {
      no strict 'refs';
      *{"$caller\::$arg"} = \&{"$this\::_$arg"};
      _srand() if ! $srand_called++;
    }
    else {
      push @remaining_args, $arg;
    }
  }

  __PACKAGE__->export_to_level(1, $this, @remaining_args);
}

sub new {
  my $class = shift;
  my $seed = shift;

  my $self = _mts_newstate($class);

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

sub timeseed {
  my ($sec, $usec) = gettimeofday();
  shift->seed32($sec * 1_000_000 + $usec);
}

sub savestate {
  my $self = shift;
  my $file = shift; # name or handle

  my $fh = ref $file eq 'GLOB' ? $file : do {
    open my $fh, '>', $file or return 0;
    $fh;
  };
  $self->mts_savestate($fh);
}

sub _savestate {
  my $file = shift; # name or handle

  my $fh = ref $file eq 'GLOB' ? $file : do {
    open my $fh, '>', $file or return 0;
    $fh;
  };
  mt_savestate($fh);
}

sub loadstate {
  my $self = shift;
  my $file = shift;

  my $fh = ref $file eq 'GLOB' ? $file : do {
    open my $fh, '<', $file or return 0;
    $fh;
  };
  $self->mts_loadstate($fh);
}

sub _loadstate {
  my $file = shift;

  my $fh = ref $file eq 'GLOB' ? $file : do {
    open my $fh, '<', $file or return 0;
    $fh;
  };
  mt_loadstate($fh);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Math::Random::MTwist - A fast stateful Mersenne Twister pseudo-random number
generator

=head1 SYNOPSIS

  # object-oriented inteface
  use Math::Random::MTwist;

  my $mt = Math::Random::MTwist->new();  # seed from /dev/urandom
  my $int = $mt->irand();                # [0 .. 2^64-1 or 2^32-1]
  my $double = $mt->rand(73);            # [0 .. 73)
  $mt->goodseed();                       # seed from /dev/random
  $mt->savestate("/tmp/foobar");         # save current state to file
  $mt->loadstate("/tmp/foobar");         # load past state from file
  my @dist = map $mt->rd_triangular(1, 3, 2), 1 .. 1e3;  # triangular dist.

  # function-oriented interface (OO interface may be used in parallel)
  use Math::Random::MTwist qw(seed32 seedfull
                              timeseed fastseed goodseed bestseed);
  use Math::Random::MTwist qw(:seed) # gives you all of the above

  use Math::Random::MTwist qw(srand rand rand32 irand irand32 irand64);
  use Math::Random::MTwist qw(:rand); # gives you all of the above

  use Math::Random::MTwist qw(rd_exponential rd_triangular rd_normal ...);
  use Math::Random::MTwist qw(:dist); # gives you alll of the above

  use Math::Random::MTwist qw(savestate loadstate);
  use Math::Random::MTwist qw(:state); # gives you alll of the above

=head1 DESCRIPTION

Math::Random::MTwist is a Perl interface to Geoff Kuenning's mtwist C
library. It provides several seeding methods, an independent state per OO
instance and various random number distributions.

All functions are available through a function-oriented interface and an
object-oriented interface. If you use the function-oriented interface the
generator maintains a single global state while with the OO interface each
instance has its individual state.

The function-oriented interface provides drop-in replacements for Perl's
built-in C<rand()> and C<srand()> functions. If you C<use> the module with an
import list C<srand()> is called once automatically. If you need the C<MT_>
constants too you must import them through the tag C<:DEFAULT>.

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
32-bit integer. Calls mtwist's C<mts_seed32new()>. Returns the seed.

=head2 srand($number)

Calls C<seed32> if C<$number> is given, C<fastseed()> otherwise. Returns the
seed.

=head2 seedfull($seeds)

Seeds the generator with up to 624 numbers from the I<array reference>
C<$seeds>. The values are coerced into unsigned 32-bit integers. Missing values
are padded with zeros, excess values are ignored. Calls mtwist's
C<mts_seedfull()>.

=head2 timeseed()

Seeds the generator from the current system time obtained with
C<gettimeofday()> by calculating C<seconds * 1e6 + microseconds> and coercing
the result into an unsigned 32-bit integer. Returns the seed.

This method is called by C<new(MT_TIMESEED)>.

It doesn't correspond to any of mtwist's functions. The rationale behind it is
that mtwist falls back to the system time if neither C</dev/urandom> nor
C</dev/random> is available. On Windows the time source chosen by mtwist has
only millisecond resolution in contrast to microseconds from
C<Time::HiRes::gettimeofday()>.

=head2 fastseed()

Seeds the generator with 4 bytes read from C</dev/urandom> if available,
otherwise from the system time (see details under C<timeseed()>). Calls
mtwist's C<mts_seed()>. Returns the seed.

This method is called by C<new(MT_FASTSEED)>.

=head2 goodseed()

Seeds the generator with 4 bytes read from C</dev/random> if available,
otherwise from the system time (see details under C<timeseed()>). Calls
mtwist's C<mts_goodseed()>. Returns the seed.

This method is called by C<new(MT_GOODSEED)>.

=head2 bestseed()

Seeds the generator with 642 integers read from C</dev/random> if
available. This might take a very long time and is probably not worth the
waiting. If C</dev/random> is unavailable or there was a reading error it falls
back to C<goodseed()>. Calls mtwist's C<mts_bestseed()>. Returns the seed.

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

The following methods come in two variants: C<B<rd_>xxx> and
C<B<rd_l>xxx>. They all return a double but the C<B<rd_>xxx> versions provide
32-bit precision while the C<B<rd_l>xxx> versions provide 52-bit precision at
the expense of speed.

Despite their names they call mtwist's C<rds_xxx> functions if used with the OO
interface.

=head2 rd_(l)exponential(double mean)

Generates an exponential distribution with the given mean.

=head2 rd_(l)erlang(int k, double mean)

Generates an Erlang-k distribution with the given mean.

=head2 rd_(l)weibull(double shape, double scale)

Generates a Weibull distribution with the given shape and scale.

=head2 rd_(l)normal(double mean, double sigma)

Generates a normal (Gaussian) distribution with the given mean and standard
deviation sigma.

=head2 rd_(l)lognormal(double shape, double scale)

Generates a log-normal distribution with the given shape and scale.

=head2 rd_(l)triangular(double lower, double upper, double mode)

Generates a triangular distribution in the range C<[lower, upper)> with the
given mode.

=head1 EXPORTS

The module exports the constants MT_TIMESEED, MT_FASTSEED, MT_GOODSEED and
MT_BESTSEED that can be used as an argument to the constructor.

=head1 SEE ALSO

L<http://www.cs.hmc.edu/~geoff/mtwist.html>

L<Math::Random::MT|https://metacpan.org/pod/Math::Random::MT> and
L<Math::Random::MT::Auto|https://metacpan.org/pod/Math::Random::MT::Auto> are
significantly slower than Math::Random::MTwist. On the other hand MRMA has some
additional sophisticated features.

=head1 AUTHOR

Carsten Gaebler (cgpan ʇɐ gmx ʇop de). I only accept encrypted e-mails, either
via L<SMIME|https://cpan.metacpan.org/authors/id/C/CG/CGPAN/cgpan-smime.crt> or
L<GPG|https://cpan.metacpan.org/authors/id/C/CG/CGPAN/cgpan-gpg.asc>.

=head1 COPYRIGHT

Perl and XS portion: Copyright © 2014 by Carsten Gaebler.

mtwist C library: Copyright © 2001, 2002, 2010, 2012, 2013 by Geoff Kuenning.

=head1 LICENSE

Perl and XS portion: L<Do What The Fuck You Want To Public
License|http://wtfpl.net/>.

mtwist C library: L<LGPL|https://gnu.org/licenses/lgpl.html>

=cut
