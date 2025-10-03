#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use File::Spec::Functions qw(catfile catdir);

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
    'fir-config=s' => \$options->{firConfig},
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
my $samplerate = $options->{samplerate} || 0;

if ($options->{firEnabled} && $options->{firConfig} && -f $options->{firConfig}) {
    print $log "FIR filtering enabled\n";
    print $log "  Config: " . $options->{firConfig} . "\n";
    
    my $pluginDir = $ENV{MELLOWDSP_PLUGIN_DIR} || '/var/daphile/mediaserver/cache/InstalledPlugins/Plugins/MellowDSP';
    my $camillaPath = catfile($pluginDir, 'Bin', 'camilladsp');
    
    print $log "CamillaDSP path: $camillaPath\n";
    
    if (!-x $camillaPath) {
        print $log "ERROR: CamillaDSP not found or not executable\n";
        close($log);
        die "CamillaDSP not available\n";
    }
    
    my @soxCmd = ($soxPath, '-t', $inFormat, $file, '-t', 'raw', '-b', '24', '-e', 'signed-integer', '-L', '-c', '2', '-');
    
    if ($samplerate > 0) {
        push @soxCmd, 'rate', '-v', '-s', $samplerate;
    }
    
    print $log "Pipeline: SOX → CamillaDSP → output\n";
    print $log "SOX command: " . join(' ', @soxCmd) . "\n";
    
    my $soxPid = open(my $sox, '-|', @soxCmd) or die "Cannot start SOX: $!";
    my $camillaPid = open(my $camilla, '|-', $camillaPath, $options->{firConfig}) or die "Cannot start CamillaDSP: $!";
    
    my $buffer;
    while (read($sox, $buffer, 65536)) {
        print $camilla $buffer;
    }
    
    close($sox);
    close($camilla);
    
    print $log "Pipeline completed\n";
    close($log);
    exit 0;
}

print $log "Direct SOX processing (no FIR)\n";

my @cmd = ($soxPath, '-t', $inFormat, $file, '-t', 'wav', '-b', '24', '-');

if ($samplerate > 0) {
    push @cmd, 'rate', '-v', '-s', $samplerate;
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
