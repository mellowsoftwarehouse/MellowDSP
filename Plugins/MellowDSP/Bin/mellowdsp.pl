#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use FindBin qw($Bin);
use File::Spec::Functions qw(catfile);

my $options = {};

GetOptions(
    'c=s' => \$options->{clientId},
    'i=s' => \$options->{inCodec},
    'o=s' => \$options->{outCodec},
    's=s' => \$options->{startSec},
    'w=s' => \$options->{durationSec},
    'r=s' => \$options->{samplerate},
    'f=s' => \$options->{firConfig},
);

my $file = $ARGV[0] || '-';

my %codecMap = (
    'flc' => 'flac',
    'aif' => 'aiff',
    'alc' => 'alac',
);

my $inFormat = $codecMap{$options->{inCodec}} || $options->{inCodec};
my $outFormat = $options->{outCodec} || 'wav';

my $soxPath = '/usr/bin/sox';

my @soxCmd = ($soxPath, '-t', $inFormat, $file);

if ($options->{startSec}) {
    push @soxCmd, 'trim', $options->{startSec};
    if ($options->{durationSec}) {
        push @soxCmd, $options->{durationSec};
    }
}

push @soxCmd, '-t', 'wav', '-b', '24', '-';

if ($options->{samplerate}) {
    push @soxCmd, 'rate', '-v', '-s', $options->{samplerate};
}

if ($options->{firConfig} && -f $options->{firConfig}) {
    
    my $camillaPath = '/usr/local/bin/camilladsp';
    
    if (!-x $camillaPath) {
        exec @soxCmd or die "Failed to exec SOX: $!";
    }
    
    my $soxCommand = join(' ', @soxCmd);
    
    if ($outFormat eq 'flac') {
        my $pipeline = "$soxCommand | $camillaPath $options->{firConfig} | $soxPath -t wav - -t flac -C 0 -b 24 -";
        exec $pipeline or die "Failed to exec pipeline: $!";
    } else {
        my $pipeline = "$soxCommand | $camillaPath $options->{firConfig}";
        exec $pipeline or die "Failed to exec pipeline: $!";
    }
    
} else {
    
    if ($outFormat eq 'flac') {
        my $soxCommand = join(' ', @soxCmd);
        my $pipeline = "$soxCommand | $soxPath -t wav - -t flac -C 0 -b 24 -";
        exec $pipeline or die "Failed to exec pipeline: $!";
    } else {
        exec @soxCmd or die "Failed to exec SOX: $!";
    }
}
