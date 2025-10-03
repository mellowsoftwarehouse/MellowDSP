package Plugins::MellowDSP::CamillaDSPHelper;

use strict;
use warnings;
use File::Spec::Functions qw(catdir catfile);
use Slim::Utils::Log;
use Slim::Utils::Prefs;

my $log = logger('plugin.mellowdsp');
my $prefs = preferences('plugin.mellowdsp');

sub getCamillaDSPPath {
    my $class = shift;
    my $pluginDir = Plugins::MellowDSP::Plugin->_pluginDataFor('basedir');
    my $camillaPath = catfile($pluginDir, 'Bin', 'camilladsp');
    return (-x $camillaPath) ? $camillaPath : undef;
}

sub isAvailable {
    my $class = shift;
    my $path = $class->getCamillaDSPPath();
    return defined($path) && -x $path;
}

sub getFIRMastersDir {
    my $class = shift;
    my $pluginDir = Plugins::MellowDSP::Plugin->_pluginDataFor('basedir');
    return catdir($pluginDir, 'FIR', 'masters');
}

sub getFIRConvertedDir {
    my $class = shift;
    my $pluginDir = Plugins::MellowDSP::Plugin->_pluginDataFor('basedir');
    return catdir($pluginDir, 'FIR', 'converted');
}

sub getConfigsDir {
    my $class = shift;
    my $pluginDir = Plugins::MellowDSP::Plugin->_pluginDataFor('basedir');
    return catdir($pluginDir, 'Configs');
}

sub convertFIR {
    my ($class, $inputFile, $outputFile, $targetRate) = @_;
    
    if (!-f $inputFile) {
        $log->error("FIR input file not found: $inputFile");
        return 0;
    }
    
    my $soxPath = $prefs->get('sox_path') || '/usr/bin/sox';
    my @cmd = ($soxPath, $inputFile, '-r', $targetRate, $outputFile);
    
    $log->info("Converting FIR: " . join(' ', @cmd));
    
    system(@cmd);
    
    if ($? != 0) {
        $log->error("FIR conversion failed");
        return 0;
    }
    
    return 1;
}

sub generateConfig {
    my ($class, $clientId, $samplerate, $leftFIR, $rightFIR) = @_;
    
    my $configDir = $class->getConfigsDir();
    my $configFile = catfile($configDir, "${clientId}.yml");
    
    my $config = <<"YAML";
---
devices:
  samplerate: $samplerate
  chunksize: 4096
  queuelimit: 4
  capture:
    type: Stdin
    channels: 2
    format: S24LE3
  playback:
    type: Stdout
    channels: 2
    format: S24LE3

filters:
  fir_left:
    type: Conv
    parameters:
      type: Wav
      filename: "$leftFIR"
  fir_right:
    type: Conv
    parameters:
      type: Wav
      filename: "$rightFIR"

pipeline:
  - type: Filter
    channel: 0
    names:
      - fir_left
  - type: Filter
    channel: 1
    names:
      - fir_right
YAML

    open(my $fh, '>', $configFile) or do {
        $log->error("Cannot write config: $configFile");
        return undef;
    };
    
    print $fh $config;
    close($fh);
    
    $log->info("Generated CamillaDSP config: $configFile");
    
    return $configFile;
}

1;
