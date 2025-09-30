package Plugins::MellowDSP::TranscodingHelper;

use strict;
use warnings;
use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Slim::Player::TranscodingHelper;

my $log = logger('plugin.mellowdsp');
my $prefs = preferences('plugin.mellowdsp');

sub init {
    my $class = shift;
    
    $log->info("TranscodingHelper initializing...");
    
    registerConverters();
    
    $log->info("TranscodingHelper initialized");
}

sub registerConverters {
    
    return unless $prefs->get('enabled');
    
    my $soxPath = $prefs->get('sox_path') || '/usr/bin/sox';
    
    my @conversions = (
        ['flc', 'wav'],
        ['aif', 'wav'],
        ['alc', 'wav'],
    );
    
    foreach my $conv (@conversions) {
        my ($from, $to) = @$conv;
        my $profile = "$from-$to-mellowdsp-*-*";
        
        # Comando base SOX
        my $command = "$soxPath -t $from \$FILE\$ -t $to -b 24 -";
        
        # Registra il comando
        $Slim::Player::TranscodingHelper::commandTable{$profile} = $command;
        
        # Capabilities deve essere un hash ref, non una stringa!
        $Slim::Player::TranscodingHelper::capabilities{$profile} = {
            'T' => 'F',  # Transcode from File to stream
        };
        
        $log->info("Registered converter: $profile");
    }
}

1;
