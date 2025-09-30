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
    my ($class, $client, $inputFormat, $outputFormat, $inputFile, $outputFile) = @_;
    
    return '' unless $client;
    
    my $clientPrefs = $prefs->client($client);
    return '' unless $clientPrefs->get('player_enabled');
    
    my $soxPath = $prefs->get('sox_path') || '/usr/bin/sox';
    return '' unless (-f $soxPath && -x $soxPath);
    
    my $targetRate = $clientPrefs->get('target_rate') || '176400';
    my $phaseResponse = $clientPrefs->get('phase_response') || 'linear';
    my $outputDepth = $clientPrefs->get('output_depth') || '24';
    my $outputFmt = $clientPrefs->get('output_format') || 'wav';
    my $bufferSize = $prefs->get('buffer_size') || 8;
    
    my @cmd = ($soxPath);
    
    push @cmd, '-t', $inputFormat if $inputFormat;
    push @cmd, $inputFile;
    
    push @cmd, '-t', $outputFmt;
    push @cmd, '-b', $outputDepth;
    
    if ($outputFmt eq 'flac') {
        push @cmd, '-C', '0';
    }
    
    push @cmd, $outputFile;
    
    if ($targetRate && $targetRate ne '44100') {
        push @cmd, 'rate', '-v';
        
        if ($phaseResponse eq 'minimum') {
            push @cmd, '-m';
        } elsif ($phaseResponse eq 'intermediate') {
            push @cmd, '-i';
        } else {
            push @cmd, '-s';
        }
        
        push @cmd, $targetRate;
    }
    
    push @cmd, 'buffer', $bufferSize * 1024;
    
    my $command = join(' ', map { /\s/ ? "\"$_\"" : $_ } @cmd);
    
    $log->info("SOX command for " . $client->name() . ": $command");
    
    return $command;
}

1;
