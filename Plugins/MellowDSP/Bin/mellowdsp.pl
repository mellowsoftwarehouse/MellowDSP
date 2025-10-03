#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

my $logfile = '/tmp/mellowdsp_wrapper.log';
open(my $log, '>>', $logfile) or die "Cannot open log: $!";
print $log "\n=== MellowDSP Wrapper v3.0.5 Called ===\n";
print $log "Time: " . localtime() . "\n";
print $log "Raw ARGV: " . join(' ', @ARGV) . "\n";

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

print $log "Parsed options:\n";
print $log "  clientId: " . ($options->{clientId} || 'NONE') . "\n";
print $log "  inCodec: " . ($options->{inCodec} || 'NONE') . "\n";
print $log "  samplerate: " . ($options->{samplerate} || 'NONE') . "\n";
print $log "  file: " . ($file || 'NONE') . "\n";

if (!$file || $file eq '') {
    print $log "ERROR: No input file specified\n";
    close($log);
    die "No input file specified\n";
}

if (!-f $file) {
    print $log "ERROR: File does not exist: $file\n";
    close($log);
    die "File does not exist: $file\n";
}

my %codecMap = (
    'flc' => 'flac',
    'aif' => 'aiff',
    'alc' => 'alac',
);

my $inFormat = $codecMap{$options->{inCodec}} || $options->{inCodec} || 'flac';
my $soxPath = '/usr/bin/sox';

my @cmd = ($soxPath, '-t', $inFormat, $file, '-t', 'wav', '-b', '24', '-');

if ($options->{samplerate} && $options->{samplerate} > 0) {
    push @cmd, 'rate', '-v', '-s', $options->{samplerate};
}

if ($options->{startSec}) {
    push @cmd, 'trim', $options->{startSec};
    if ($options->{durationSec}) {
        push @cmd, $options->{durationSec};
    }
}

print $log "Final SOX command: " . join(' ', @cmd) . "\n";
close($log);

exec @cmd or die "Failed to exec: $!";
