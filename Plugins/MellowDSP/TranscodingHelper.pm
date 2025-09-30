package Plugins::MellowDSP::TranscodingHelper;

use strict;
use warnings;
use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Slim::Player::TranscodingHelper;
use Plugins::MellowDSP::SOXProcessor;
use Plugins::MellowDSP::FIRProcessor;

my $log = logger('plugin.mellowdsp.transcoding');
my $prefs = preferences('plugin.mellowdsp');

sub init {
    my $class = shift;
    
    $log->info("TranscodingHelper initializing...");
    
    registerConverters();
    
    $log->info("TranscodingHelper initialized");
}

sub registerConverters {
    
    return unless $prefs->get('enabled');
    
    my @inputFormats = qw(flc aif alc wav);
    my $outputFormat = 'wav';
    
    foreach my $inputFormat (@inputFormats) {
        my $profile = "$inputFormat-$outputFormat-mellowdsp-*-*";
        
        my $command = buildCommandTemplate($inputFormat, $outputFormat);
        
        $Slim::Player::TranscodingHelper::commandTable{$profile} = $command;
        
        $Slim::Player::TranscodingHelper::capabilities{$profile} = {'T' => 'F'};
        
        $log->info("Registered converter: $profile");
    }
}

sub buildCommandTemplate {
    my ($inputFormat, $outputFormat) = @_;
    
    my $soxPath = $prefs->get('sox_path') || '/usr/bin/sox';
    
    my $command = "$soxPath -t $inputFormat \$FILE\$ -t $outputFormat -b 24 -";
    
    $log->debug("Command template: $command");
    
    return $command;
}

sub getCommand {
    my ($client, $song, $format) = @_;
    
    return undef unless $client;
    return undef unless $prefs->client($client)->get('player_enabled');
    
    my $url = $song->currentTrack()->url;
    my $inputFormat = Slim::Music::Info::contentType($url);
    
    my $command = Plugins::MellowDSP::SOXProcessor->buildTranscodeCommand(
        $client,
        $inputFormat,
        'wav',
        '-',
        '-'
    );
    
    if ($prefs->client($client)->get('fir_enabled')) {
        my $leftFIR = Plugins::MellowDSP::FIRProcessor->getFIRPath($client, 'left');
        my $rightFIR = Plugins::MellowDSP::FIRProcessor->getFIRPath($client, 'right');
        
        if ($leftFIR || $rightFIR) {
            $command = addFIRProcessing($command, $leftFIR, $rightFIR);
        }
    }
    
    $log->info("Transcoding command: $command");
    
    return $command;
}

sub addFIRProcessing {
    my ($baseCommand, $leftFIR, $rightFIR) = @_;
    
    return $baseCommand unless ($leftFIR || $rightFIR);
    
    my $soxPath = $prefs->get('sox_path') || '/usr/bin/sox';
    
    my $firCommand = " | $soxPath - -t wav -";
    
    if ($leftFIR && $rightFIR) {
        $firCommand .= " remix 1 2";
        $firCommand .= " fir \"$leftFIR\" \"$rightFIR\"";
    } elsif ($leftFIR) {
        $firCommand .= " remix 1 1";
        $firCommand .= " fir \"$leftFIR\"";
    } elsif ($rightFIR) {
        $firCommand .= " remix 2 2";
        $firCommand .= " fir \"$rightFIR\"";
    }
    
    return $baseCommand . $firCommand;
}

1;
