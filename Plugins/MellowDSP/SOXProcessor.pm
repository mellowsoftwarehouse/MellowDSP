package Plugins::MellowDSP::SOXProcessor;

use strict;
use warnings;
use Slim::Utils::Log;
use Slim::Utils::Prefs;

my $log = logger('plugin.mellowdsp.sox');
my $prefs = preferences('plugin.mellowdsp');

sub init {
    $log->info("SOX Processor initialized");
}

sub buildTranscodeCommand {
    my ($client, $inputFormat, $outputFormat, $inputFile, $outputFile) = @_;
    
    return '' unless $client;
    
    my $clientPrefs = $prefs->client($client);
    return '' unless $clientPrefs->get('player_enabled');
    
    my $soxPath = $prefs->get('sox_path') || '/usr/bin/sox';
    return '' unless (-f $soxPath && -x $soxPath);
    
    my $targetRate = $clientPrefs->get('target_rate') || '176400';
    my $phaseResponse = $clientPrefs->get('phase_response') || 'linear';
    my $bufferSize = $prefs->get('buffer_size') || 8;
    
    # Costruisci comando SOX
    my @cmd = ($soxPath);
    
    # Input
    push @cmd, '-t', $inputFormat if $inputFormat;
    push @cmd, $inputFile;
    
    # Output
    push @cmd, '-t', 'wav';
    push @cmd, '-b', '24';
    push @cmd, $outputFile;
    
    # Resampling con fase specifica
    if ($targetRate && $targetRate ne '44100') {
        push @cmd, 'rate', '-v';
        
        if ($phaseResponse eq 'minimum') {
            push @cmd, '-m';
        } elsif ($phaseResponse eq 'intermediate') {
            push @cmd, '-i';
        } else {
            push @cmd, '-s'; # linear phase (default high quality)
        }
        
        push @cmd, $targetRate;
    }
    
    # Buffer size
    push @cmd, 'buffer', $bufferSize * 1024;
    
    my $command = join(' ', map { /\s/ ? "\"$_\"" : $_ } @cmd);
    
    $log->info("SOX command for " . $client->name() . ": $command");
    
    return $command;
}

sub getSupportedFormats {
    my ($client) = @_;
    
    return [] unless $client;
    
    my $clientPrefs = $prefs->client($client);
    my $inputFormats = $clientPrefs->get('input_formats') || 'flac,wav';
    
    return [split(',', $inputFormats)];
}

sub getOutputRates {
    my ($client) = @_;
    
    return [] unless $client;
    
    my $clientPrefs = $prefs->client($client);
    my $outputRates = $clientPrefs->get('output_rates') || '44100,48000,88200,96000,176400,192000,352800,384000,705600,768000';
    
    return [split(',', $outputRates)];
}

1;
