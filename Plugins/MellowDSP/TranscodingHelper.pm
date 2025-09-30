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
            
            my $profile_file = "$inFmt-$outFmt-mellowdsp-file-*";
            my $command_file = "$soxPath -t $inFmt \$FILE\$ -t $outFmt -b 24";
            if ($outFmt eq 'flc') {
                $command_file .= " -C 0";
            }
            $command_file .= " -";
            
            $Slim::Player::TranscodingHelper::commandTable{$profile_file} = $command_file;
            $Slim::Player::TranscodingHelper::capabilities{$profile_file} = {
                'F' => 'F',
                'T' => 'F',
            };
            $log->info("Registered: $profile_file (File)");
            
            my $profile_stream = "$inFmt-$outFmt-mellowdsp-stream-*";
            my $command_stream = "$soxPath -t $inFmt - -t $outFmt -b 24";
            if ($outFmt eq 'flc') {
                $command_stream .= " -C 0";
            }
            $command_stream .= " -";
            
            $Slim::Player::TranscodingHelper::commandTable{$profile_stream} = $command_stream;
            $Slim::Player::TranscodingHelper::capabilities{$profile_stream} = {
                'F' => 'R',
                'T' => 'F',
            };
            $log->info("Registered: $profile_stream (Remote stream)");
        }
    }
}

1;
