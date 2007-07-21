#!/usr/bin/perl
use strict; use warnings;
use Test::More tests => 61;
use sort 'stable';

BEGIN { use_ok( 'Math::BinPacking', ':all' ); }
use vars qw//;

# Carefully chosen list (almost) gives different solution for each of the eight methods
my @list = qw/2 2 5 5 6 3 2 4 5 2 6 4 5 3 5/;

my $i = 1;
my @hash = map +{ size => $_, idx => $i++ }, @list;

$i = 1;
my @array = map [$_, $i++], @list;


{ package SimpleObj;
  our @list;
  sub size { $list[${$_[0]} - 1] }
}
@SimpleObj::list = @list;

my @obj = map bless(\"$_", "SimpleObj"), 1..@list;

is( item_size($list[0]),  2, "item_size scalar" );
is( item_size($hash[0]),  2, "item_size hash" );
is( item_size($array[0]), 2, "item_size array" );
is( item_size($obj[0]),   2, "item_size object1" );


our $ff_size = [[qw/2 2 5/], [qw/5 3 2/], [qw/6 4/], [qw/5  2  3/], [qw/ 6  4/], [qw/ 5  5/]];
our $ff_idx  = [[qw/1 2 3/], [qw/4 6 7/], [qw/5 8/], [qw/9 10 14/], [qw/11 12/], [qw/13 15/]];
our $ffd_size= [[qw/6 4/], [qw/6 4/], [qw/5 5/], [qw/5 5/], [qw/5  3  2/], [qw/ 3  2  2  2/]];
our $ffd_idx = [[qw/1 8/], [qw/2 9/], [qw/3 4/], [qw/5 6/], [qw/7 10 12/], [qw/11 13 14 15/]];

our $nf_size = [[qw/2 2 5/], [qw/5/], [qw/6 3/], [qw/2 4/], [qw/5  2/], [qw/ 6  4/], [qw/ 5  3/], [qw/ 5/]];
our $nf_idx  = [[qw/1 2 3/], [qw/4/], [qw/5 6/], [qw/7 8/], [qw/9 10/], [qw/11 12/], [qw/13 14/], [qw/15/]];
our $nfd_size= [[qw/6/], [qw/6/], [qw/5 5/], [qw/5 5/], [qw/5 4/], [qw/4  3  3/], [qw/ 2  2  2  2/]];
our $nfd_idx = [[qw/1/], [qw/2/], [qw/3 4/], [qw/5 6/], [qw/7 8/], [qw/9 10 11/], [qw/12 13 14 15/]];

our $bf_size = [[qw/2 2 5/], [qw/5 2  2/], [qw/6 3/], [qw/4 5/], [qw/ 6  4/], [qw/ 5  3/], [qw/ 5/]];
our $bf_idx  = [[qw/1 2 3/], [qw/4 7 10/], [qw/5 6/], [qw/8 9/], [qw/11 12/], [qw/13 14/], [qw/15/]];
our $bfd_size= [[qw/6 4/], [qw/6 4/], [qw/5 5/], [qw/5 5/], [qw/5  3  2/], [qw/ 3  2  2  2/]];
our $bfd_idx = [[qw/1 8/], [qw/2 9/], [qw/3 4/], [qw/5 6/], [qw/7 10 12/], [qw/11 13 14 15/]];

our $wf_size = [[qw/2 2 5/], [qw/5 3  2/], [qw/6 2/], [qw/4 5/], [qw/ 6  4/], [qw/ 5  3/], [qw/ 5/]];
our $wf_idx  = [[qw/1 2 3/], [qw/4 6 10/], [qw/5 7/], [qw/8 9/], [qw/11 12/], [qw/13 14/], [qw/15/]];
our $wfd_size= [[qw/6 4/], [qw/6  3/], [qw/5 5/], [qw/5 5/], [qw/5 4/], [qw/ 3  2  2  2/], [qw/ 2/]];
our $wfd_idx = [[qw/1 9/], [qw/2 10/], [qw/3 4/], [qw/5 6/], [qw/7 8/], [qw/11 12 13 14/], [qw/15/]];

my %index_perm = qw/1 5 2 11 3 3 4 4 5 9 6 13 7 15 8 8 9 12 10 6 11 14 12 1 13 2 14 7 15 10/;
for ($ffd_idx, $nfd_idx, $bfd_idx, $wfd_idx) { for (@$_) { $_ = $index_perm{$_} for @$_ } }
our @bins;

my %t =
( ff  => \&pack_first_fit,
  ffd => \&pack_first_fit_decreasing,
  nf  => \&pack_next_fit,
  nfd => \&pack_next_fit_decreasing,
  bf  => \&pack_best_fit,
  bfd => \&pack_best_fit_decreasing,
  wf  => \&pack_worst_fit,
  wfd => \&pack_worst_fit_decreasing,
);

{ no strict 'refs';
  my ($name, $sub);
  while (($name, $sub) = each %t) {
    @bins = &$sub( 10, \@list );
    is_deeply( \@bins, ${"${name}_size"}, "$name - list; sizes" );

    @bins = &$sub( 10, \@hash );
    is_deeply( [map [map $_->{size}, @$_], @bins], ${"${name}_size"}, "$name - hash; sizes" );
    is_deeply( [map [map $_->{idx},  @$_], @bins], ${"${name}_idx"},  "$name - hash; indices" );

    @bins = &$sub( 10, \@array );
    is_deeply( [map [map $_->[0],    @$_], @bins], ${"${name}_size"}, "$name - array; sizes" );
    is_deeply( [map [map $_->[1],    @$_], @bins], ${"${name}_idx"},  "$name - array; indices" );

    @bins = &$sub( 10, \@obj );
    is_deeply( [map [map $_->size,   @$_], @bins], ${"${name}_size"}, "$name - object; sizes" );
    is_deeply( [map [map 0+$$_,      @$_], @bins], ${"${name}_idx"},  "$name - object; indices" );
  }
}
