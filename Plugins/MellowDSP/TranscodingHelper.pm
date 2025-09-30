package Plugins::MellowDSP::TranscodingHelper;

use strict;
use warnings;
use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Slim::Player::TranscodingHelper;
use Slim::Player::Client;

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
    
    my $soxPath = $prefs->get('sox_path') || '/usr/bin/sox';
    
    my @clients = Slim::Player::Client::clients();
    
    foreach my $client (@clients) {
        my $macaddress = $client->id();
        
        my @inputFormats = qw(flc aif alc);
        my @outputFormats = qw(pcm);
        
        foreach my $inFmt (@inputFormats) {
            foreach my $outFmt (@outputFormats) {
                
                my $profile = "$inFmt-$outFmt-*-$macaddress";
                
                my $command = "$soxPath -t $inFmt \$FILE\$ -t wav -b 24 -";
                
                $Slim::Player::TranscodingHelper::commandTable{$profile} = $command;
                
                $Slim::Player::TranscodingHelper::capabilities{$profile} = {
                    F => 'noArgs',
                    R => 'noArgs',
                    I => 'noArgs',
                };
                
                $log->info("Registered: $profile for " . $client->name());
            }
        }
    }
}

1;
