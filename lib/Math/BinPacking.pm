package Math::BinPacking;
use Carp; use strict; use warnings;
our $VERSION = 0.1;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS =
  ( packers  => [qw/ pack_next_fit   pack_next_fit_decreasing
                     pack_first_fit  pack_first_fit_decreasing
                     pack_best_fit   pack_best_fit_decreasing
                     pack_worst_fit  pack_worst_fit_decreasing
                     pack_items
               /],
    util     => [qw/ sprint_bins print_bins sprint_bin print_bin /],
    internal => [qw/ item_size rsortitems /],
  );
our @EXPORT_OK = map @$_, values %EXPORT_TAGS;
$EXPORT_TAGS{all} = \@EXPORT_OK;

use List::Util qw/ sum max shuffle /;

sub item_size {
  return $_[0]         unless ref($_[0]);
  return $_[0]->{size}     if ref($_[0]) eq 'HASH';
  return $_[0]->[0]        if ref($_[0]) eq 'ARRAY';
  return $_[0]->size;
}

sub rsortitems { map $$_[1], sort { $$b[0] <=> $$a[0] } map [item_size($_), $_], @{$_[0]} }
sub ceil($) { my $x = shift; return ($x == int $x) ? $x : ($x > 0) ? int( $x+1 ) : int($x) }


=pod

=head1 NAME

Math::BinPacking - Several simple bin packing algorithms

=head1 SYNOPSIS

 use strict;
 use Math::BinPacking qw/ pack_first_fit print_bins /;

 my @bins = pack_first_fit( 10, \@items );
 print_bins @bins;

=head1 DESCRIPTION



=head1 USAGE

=head2 :packers

=cut



=head3 pack_first_fit

=head3 pack_first_fit_decreasing

 @bins = pack_first_fit $size, \@items;


Note: We have tight bounds for FFD() num bins from first-fit-decreasing and
OPT() num bins optimal of:

   FFD(L) ≤ 11/9 ⋅ OPT(L) + 6/9

Dósa, György and Li, Rongheng and Han, Xin and Tuza, Zsolt, "Tight absolute
bound for First Fit Decreasing bin-packing: FFD(L) ≤ 11/9 OPT(L) + 6/9",
Theoretical Computer Science Volume 510, 28 October 2013, Pages 13-61

=cut

sub pack_first_fit_decreasing {
  pack_first_fit($_[0], [rsortitems $_[1]])
}

sub pack_first_fit {
  my ($size, $list) = @_;
  my @bins = ([]);
  my @free = ($size);
  for my $item (@$list) {
    my $s = item_size($item);
    croak "Item ($s) too large for any bin (size $size)!" if $s > $size;
    my $i;
    for (0..$#free) { if ($free[$_] >= $s) { $i = $_; last; } }
    if (defined $i) {
      push @{$bins[$i]}, $item;
      $free[$i] -= $s;
    } else {
      push @bins, [$item];
      push @free, $size-$s;
    }
  }
  return @bins;
}


=head3 pack_best_fit

=head3 pack_best_fit_decreasing

 @bins = pack_best_fit $size, \@items;

=cut

sub pack_best_fit_decreasing {
  pack_best_fit($_[0], [rsortitems $_[1]])
}

sub pack_best_fit {
  my ($size, $list) = @_;
  my @bins = ([]);
  my @free = ($size);
  for my $item (@$list) {
    my $s = item_size($item);
    croak "Item ($s) too large for any bin (size $size)!" if $s > $size;
    my $i = [-1, 1+$size];
    for (0..$#free) {
      next unless $free[$_] >= $s;
      @$i = ($_, $free[$_]) if $free[$_] < $$i[1];
    }
    $i = $$i[0];
    if ($i >= 0) {
      push @{$bins[$i]}, $item;
      $free[$i] -= $s;
    } else {
      push @bins, [$item];
      push @free, $size-$s;
    }
  }
  return @bins;
}


=head3 pack_worst_fit

=head3 pack_worst_fit_decreasing

 @bins = pack_worst_fit $size, \@items;

=cut

sub pack_worst_fit_decreasing {
  pack_worst_fit($_[0], [rsortitems $_[1]])
}

sub pack_worst_fit {
  my ($size, $list) = @_;
  my @bins = ([]);
  our @free = ($size);
  for my $item (@$list) {
    my $s = item_size($item);
    croak "Item ($s) too large for any bin (size $size)!" if $s > $size;
    my $i = 0;
    for (1..$#free) { $i = $_ if $free[$_] > $free[$i]; }
    if ($free[$i] >= $s) {
      push @{$bins[$i]}, $item;
      $free[$i] -= $s;
    } else {
      push @bins, [$item];
      push @free, $size-$s;
    }
  }
  return @bins;
}


=head3 pack_next_fit

=head3 pack_next_fit_decreasing

 @bins = pack_next_fit $size, \@items;

=cut

sub pack_next_fit_decreasing {
  pack_next_fit($_[0], [rsortitems $_[1]])
}

sub pack_next_fit {
  my ($size, $list) = @_;
  my @bins = ([]);
  my $free = $size;
  for my $item (@$list) {
    my $s = item_size($item);
    croak "Item ($s) too large for any bin (size $size)!" if $s > $size;
    if ($free >= $s) {
      push @{$bins[-1]}, $item;
      $free -= $s;
    } else {
      push @bins, [$item];
      $free = $size-$s;
    }
  }
  return @bins;
}


=head2 :util

=cut

=head3 pack_items

 @bins = pack_items( $bin_size, \@items, $max_nr_randomizations, $skip_decreasing )

Try all algorithms, attempting to pack items into minimal number of bins.
Item list will be randomized (alters the C<@items> list) if
C<$max_nr_randomizations> and greater than zero. The "decreasing"
algorithms will not be attempted if C<$skip_decreasing> is true.

 # Return first minimal packing of NF, FF, WF, BF, NFD, FFD, WFD, BFD (no randomizations)
 @bins = pack_items( $bin_size, \@items )

 # Return first minimal packing of NF, FF, WF, BF, NFD, FFD, WFD, BFD,
 # or NF, FF, WF, BF applied to (up to) two randomizations of C<@items>.
 @bins = pack_items( $bin_size, \@items, 2 )

 # Return first minimal packing of NF, FF, WF, BF (Note: order never altered)
 @bins = pack_items( $bin_size, \@items, 0, 1 )

=cut

# Note: randomizing is rarely useful, decreasing is frequently useful
sub pack_items {
  my ($size, $items, $randomizations, $tried_decreasing) = @_;

  # Simplistic lower-bounds:
  #  1) # bins >= total size to pack / bin size
  #  2) # bins >= number of items filling more than half a bin
  #     a) can extend this slightly by adding .5 bins each time an item
  #        with size = 1/2 bin size is encountered.
  my ($min_bins, $total_size, $half_size) = (0,0,$size/2);
  for (@$items) {
    my $s = item_size($_);

    if    ($s  < $half_size) { 1; }# The common case
    elsif ($s  > $half_size) { $min_bins++ }
    elsif ($s == $half_size) { $min_bins += .5 }

    $total_size += $s;
  }
  $min_bins = ceil max( $min_bins, $total_size / $size );
  $randomizations ||= 0;

  my (@bins, @best, $i);
 BP_LOOP:
  for $i (0..$randomizations) {
    for (\&pack_next_fit, \&pack_first_fit, \&pack_worst_fit, \&pack_best_fit) {
      @bins = &$_($size, $items);
      @best = @bins if !@best or @best > @bins;
      last BP_LOOP  if @best == $min_bins;
    }

    if (!$tried_decreasing) {
      $tried_decreasing = 1;
      my @ritems = rsortitems $items;
      for (\&pack_next_fit, \&pack_first_fit, \&pack_worst_fit, \&pack_best_fit) {
        @bins = &$_($size, \@ritems);
        @best = @bins if !@best or @best > @bins;
        last BP_LOOP  if @best == $min_bins;
      }
    }
  } continue {
    @$items = shuffle(@$items) if $i < $randomizations;
  }

  return @best;
}

sub print_bins  { print sprint_bins(@_) }
sub sprint_bins { join "\n", sprintf("BINS: %d", 0+@_), map(sprint_bin($_), @_), ""; }

sub print_bin  { print sprint_bin @_ }
sub sprint_bin {
  my $bin = shift;
  my $text = sprintf "(%4d): ", sum @$bin;
  for (@$bin) {
    if    ((length($_)+2) <= $_) { $text .= "[".ctext($_, $_)."]" }
    elsif ((length($_))   <  $_) { $text .= $_ . "_" }
    elsif ((length($_))   == $_) { $text .= $_ }
    else { die }
  }
  return $text;
}


=head2 :internal

=cut

=head3 item_size

 my $size = item_size( $item )

Returns $item iteself if it is not a reference. Returns
C<$item-E<gt>{size}> if it is a hashref, C<$item-E<gt>[0]> if it is an
arrayref, and C<$item-E<gt>size()> otherwise.

=head3 rsortitems

 my @decreasing = rsortitems \@items;

Sorts items in decreasing order as compared by their output from
C<item_size()>.

=head3 ctext

=cut

sub ctext {
  my ($text, $width) = @_;
  my $l = length($text);
  return unless $width >= $l;
  my $res = ' ' x int(($width-$l)/2) . $text;
  $res .= ' ' x ($width-length($res));
  return $res;
}




1;

__END__
Created: 10 Apr 2007

=head1 SEE ALSO

 Algorithm::BinPack

=head1 AUTHOR

 Dean Serenevy
 dean@serenevy.net
 http://dean.serenevy.net/

=head1 COPYRIGHT

This software is hereby placed into the public domain. If you use this
code, a simple comment in your code giving credit and an email letting
me know that you find it useful would be courteous but is not required.

The software is provided "as is" without warranty of any kind, either
expressed or implied including, but not limited to, the implied warranties
of merchantability and fitness for a particular purpose. In no event shall
the authors or copyright holders be liable for any claim, damages or other
liability, whether in an action of contract, tort or otherwise, arising
from, out of or in connection with the software or the use or other
dealings in the software.

=head1 SEE ALSO

perl(1).
