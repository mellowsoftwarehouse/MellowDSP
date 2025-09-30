package Plugins::MellowDSP::TranscodingHelper;

use strict;
use warnings;
use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Slim::Player::TranscodingHelper;

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
    
    my @inputFormats = qw(flc aif alc);
    my @outputFormats = qw(wav flc);
    
    foreach my $inFmt (@inputFormats) {
        foreach my $outFmt (@outputFormats) {
            my $profile = "$inFmt-$outFmt-mellowdsp-*-*";
            
            my $command = "$soxPath -t $inFmt \$FILE\$ -t $outFmt -b 24";
            
            if ($outFmt eq 'flc') {
                $command .= " -C 0";
            }
            
            $command .= " -";
            
            $Slim::Player::TranscodingHelper::commandTable{$profile} = $command;
            
            $Slim::Player::TranscodingHelper::capabilities{$profile} = {
                'F' => 'F',
                'T' => 'F',
            };
            
            $log->info("Registered: $profile");
        }
    }
}

1;
