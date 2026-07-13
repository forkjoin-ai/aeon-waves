#!/usr/bin/env perl
# becky.pl -- GG compiler in Perl.
# Perl's regex engine is the ANCESTOR of PCRE. The teacher races the student.
# Hash for O(1) lookup. The original web language.

use strict;
use warnings;
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC);

my $EDGE_RE = qr/\(([^)]+)\)\s*-\[:([A-Z]+)(?:\s*\{([^}]+)\})?\]->\s*\(([^)]+)\)/;
my $NODE_RE = qr/\(([^:)\s|]+)(?:\s*:\s*([^){\s]+))?(?:\s*\{([^}]+)\})?\)/;

sub strip_comments {
    my ($source) = @_;
    my @lines;
    for (split /\n/, $source) {
        s|//.*||;
        s/^\s+|\s+$//g;
        push @lines, $_ if length;
    }
    return join("\n", @lines);
}

sub parse_properties {
    my ($raw) = @_;
    my %props;
    return \%props unless $raw;
    for (split /,/, $raw) {
        if (/^\s*(\w+)\s*:\s*(.+?)\s*$/) {
            my ($k, $v) = ($1, $2);
            $v =~ s/^['"]|['"]$//g;
            $props{$k} = $v if length($k) && length($v);
        }
    }
    return \%props;
}

sub split_pipe {
    my ($raw) = @_;
    my @ids;
    for (split /\|/, $raw) {
        s/^\s*\(?|\)?\s*$//g;
        s/[:{\s].*//;
        s/^\s+|\s+$//g;
        push @ids, $_ if length;
    }
    return \@ids;
}

sub parse_gg {
    my ($source) = @_;
    my $cleaned = strip_comments($source);
    my %nodes;
    my @edges;

    while ($cleaned =~ /$EDGE_RE/g) {
        my $src_ids = split_pipe($1);
        my $tgt_ids = split_pipe($4);
        my $props = parse_properties($3 // '');
        push @edges, { sourceIds => $src_ids, targetIds => $tgt_ids, type => $2, properties => $props };
        for (@$src_ids, @$tgt_ids) {
            $nodes{$_} //= { id => $_, labels => [], properties => {} };
        }
    }

    for (split /\n/, $cleaned) {
        next if /-\[:/;
        while (/$NODE_RE/g) {
            my $id = $1;
            next if !length($id) || $id =~ /\|/;
            unless (exists $nodes{$id}) {
                my $label = defined($2) ? $2 : '';
                $label =~ s/^\s+|\s+$//g;
                my @labels = length($label) ? ($label) : ();
                $nodes{$id} = { id => $id, labels => \@labels, properties => parse_properties($3 // '') };
            }
        }
    }

    return { nodes => \%nodes, edges => \@edges };
}

sub compute_beta1 {
    my ($prog) = @_;
    my $b1 = 0;
    for my $e (@{$prog->{edges}}) {
        my $s = scalar @{$e->{sourceIds}};
        my $t = scalar @{$e->{targetIds}};
        my $type = $e->{type};
        if ($type eq 'FORK') { $b1 += $t - 1 }
        elsif ($type =~ /^(?:FOLD|COLLAPSE|OBSERVE)$/) { $b1 = $b1 - ($s - 1); $b1 = 0 if $b1 < 0 }
        elsif ($type =~ /^(?:RACE|SLIVER)$/) { my $d = $s - $t; $d = 0 if $d < 0; $b1 -= $d; $b1 = 0 if $b1 < 0 }
        elsif ($type eq 'VENT') { $b1--; $b1 = 0 if $b1 < 0 }
    }
    return $b1;
}

sub compute_void {
    my ($prog) = @_;
    my $d = 0;
    for (@{$prog->{edges}}) { $d += scalar @{$_->{targetIds}} if $_->{type} eq 'FORK' }
    return $d;
}

sub compute_heat {
    my ($prog) = @_;
    my $h = 0;
    for (@{$prog->{edges}}) {
        if ($_->{type} =~ /^(?:FOLD|COLLAPSE|OBSERVE)$/ && scalar @{$_->{sourceIds}} > 1) {
            $h += log(scalar @{$_->{sourceIds}}) / log(2);
        }
    }
    return $h;
}

sub compute_deficit {
    my ($prog) = @_;
    my (%out, %in);
    for my $e (@{$prog->{edges}}) {
        $out{$_} += scalar @{$e->{targetIds}} for @{$e->{sourceIds}};
        $in{$_} += scalar @{$e->{sourceIds}} for @{$e->{targetIds}};
    }
    my $total = 0;
    $total += abs(($out{$_} // 0) - ($in{$_} // 0)) for keys %{$prog->{nodes}};
    return $total;
}

# CLI
my ($beta1_only, $summary, $bench_iters, $filepath) = (0, 0, 0, undef);
while (@ARGV) {
    my $arg = shift;
    if ($arg eq '--beta1') { $beta1_only = 1 }
    elsif ($arg eq '--summary') { $summary = 1 }
    elsif ($arg eq '--bench') { $bench_iters = shift }
    else { $filepath = $arg }
}
die "usage: perl becky.pl [--beta1|--summary|--bench N] <file.gg>\n" unless $filepath;

open my $fh, '<', $filepath or die "becky.pl: cannot read $filepath: $!\n";
my $source = do { local $/; <$fh> };
close $fh;

if ($bench_iters > 0) {
    parse_gg($source) for 1..10; # warmup
    my $start = clock_gettime(CLOCK_MONOTONIC);
    parse_gg($source) for 1..$bench_iters;
    my $elapsed = clock_gettime(CLOCK_MONOTONIC) - $start;
    my $us = $elapsed * 1e6 / $bench_iters;
    my $p = parse_gg($source);
    printf "%.1fus/iter | %d iterations | %d nodes %d edges | b1=%d | void=%d heat=%.3f deficit=%d\n",
        $us, $bench_iters, scalar keys %{$p->{nodes}}, scalar @{$p->{edges}},
        compute_beta1($p), compute_void($p), compute_heat($p), compute_deficit($p);
    exit;
}

my $p = parse_gg($source);
my $b1 = compute_beta1($p);
if ($beta1_only) { print "$b1\n" }
elsif ($summary) {
    printf "%s: %d nodes, %d edges, b1=%d, void=%d, heat=%.3f, deficit=%d\n",
        $filepath, scalar keys %{$p->{nodes}}, scalar @{$p->{edges}},
        $b1, compute_void($p), compute_heat($p), compute_deficit($p);
} else {
    printf '{"nodes":%d,"edges":%d,"beta1":%d}' . "\n",
        scalar keys %{$p->{nodes}}, scalar @{$p->{edges}}, $b1;
}
