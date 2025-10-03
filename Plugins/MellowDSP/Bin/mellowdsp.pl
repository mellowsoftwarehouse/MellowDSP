#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my $options = {};

GetOptions(
    'c=s' => \$options->{clientId},
    'i=s' => \$options->{inCodec},
    'o=s' => \$options->{outCodec},
    's=s' => \$options->{startSec},
    'w=s' => \$options->{durationSec},
    'r=s' => \$options->{samplerate},
);

my $file = shift @ARGV;

if (!$file || $file eq '') {
    die "No input file specified\n";
}

my %codecMap = (
    'flc' => 'flac',
    'aif' => 'aiff',
    'alc' => 'alac',
);

my $inFormat = $codecMap{$options->{inCodec}} || $options->{inCodec} || 'flac';
my $outFormat = $options->{outCodec} || 'wav';
my $soxPath = '/usr/bin/sox';

my @cmd = ($soxPath, '-t', $inFormat, $file, '-t', 'wav', '-b', '24');

if ($options->{samplerate}) {
    push @cmd, 'rate', '-v', '-s', $options->{samplerate};
}

if ($options->{startSec}) {
    push @cmd, 'trim', $options->{startSec};
    if ($options->{durationSec}) {
        push @cmd, $options->{durationSec};
    }
}

if ($outFormat eq 'flac') {
    push @cmd, '-t', 'flac', '-C', '0', '-';
} else {
    push @cmd, '-';
}

exec @cmd or die "Failed to exec: $!";
