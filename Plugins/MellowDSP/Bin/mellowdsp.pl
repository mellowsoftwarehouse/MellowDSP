#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use File::Spec::Functions qw(catfile);

my $logfile = '/tmp/mellowdsp_wrapper.log';
open(my $log, '>>', $logfile) or die "Cannot open log: $!";
print $log "\n=== MellowDSP Wrapper v3.1.0 Called ===\n";
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
    'fir'  => \$options->{firEnabled},
    'fir-left=s' => \$options->{firLeft},
    'fir-right=s' => \$options->{firRight},
);

my $file = shift @ARGV;

print $log "Parsed options:\n";
print $log "  clientId: " . ($options->{clientId} || 'NONE') . "\n";
print $log "  inCodec: " . ($options->{inCodec} || 'NONE') . "\n";
print $log "  outCodec: " . ($options->{outCodec} || 'NONE') . "\n";
print $log "  samplerate: " . ($options->{samplerate} || 'NONE') . "\n";
print $log "  firEnabled: " . ($options->{firEnabled} ? 'YES' : 'NO') . "\n";
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
my $outFormat = $options->{outCodec} || 'wav';
my $soxPath = '/usr/bin/sox';

my @soxCmd = ($soxPath, '-t', $inFormat, $file, '-t', 'wav', '-b', '24', '-');

if ($options->{samplerate} && $options->{samplerate} > 0) {
    push @soxCmd, 'rate', '-v', '-s', $options->{samplerate};
}

if ($options->{startSec}) {
    push @soxCmd, 'trim', $options->{startSec};
    if ($options->{durationSec}) {
        push @soxCmd, $options->{durationSec};
    }
}

if ($options->{firEnabled} && $options->{firLeft} && $options->{firRight}) {
    print $log "FIR filtering enabled\n";
    print $log "  Left: " . $options->{firLeft} . "\n";
    print $log "  Right: " . $options->{firRight} . "\n";
    
    my $pluginDir = $ENV{MELLOWDSP_PLUGIN_DIR} || '/var/daphile/mediaserver/cache/InstalledPlugins/Plugins/MellowDSP';
    my $camillaPath = catfile($pluginDir, 'Bin', 'camilladsp');
    my $configPath = catfile($pluginDir, 'Configs', $options->{clientId} . '.yml');
    
    print $log "CamillaDSP path: $camillaPath\n";
    print $log "Config path: $configPath\n";
    
    if (!-x $camillaPath) {
        print $log "ERROR: CamillaDSP not found or not executable\n";
        close($log);
        die "CamillaDSP not available\n";
    }
    
    print $log "Pipeline: SOX → CamillaDSP → output\n";
    print $log "SOX command: " . join(' ', @soxCmd) . "\n";
    
    open(my $sox, '-|', @soxCmd) or die "Cannot start SOX: $!";
    open(my $camilla, '|-', $camillaPath, $configPath) or die "Cannot start CamillaDSP: $!";
    
    while (read($sox, my $buffer, 65536)) {
        print $camilla $buffer;
    }
    
    close($sox);
    close($camilla);
    
    print $log "Pipeline completed\n";
    close($log);
    exit 0;
}

print $log "Direct SOX processing (no FIR)\n";
print $log "Final SOX command: " . join(' ', @soxCmd) . "\n";
close($log);

exec @soxCmd or die "Failed to exec: $!";
