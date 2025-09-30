package Plugins::MellowDSP::Plugin;

use strict;
use warnings;
use base qw(Slim::Plugin::Base);
use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Slim::Player::TranscodingHelper;

my $log = Slim::Utils::Log->addLogCategory({
    category     => 'plugin.mellowdsp',
    defaultLevel => 'INFO',
    description  => 'PLUGIN_MELLOWDSP',
});

my $prefs = preferences('plugin.mellowdsp');

sub initPlugin {
    my $class = shift;
    
    $log->info("MellowDSP Plugin initializing...");
    
    $prefs->init({
        enabled => 1,
        sox_path => '/usr/bin/sox',
        ffmpeg_path => '/usr/bin/ffmpeg',
        buffer_size => '16',
    });
    
    require Plugins::MellowDSP::SOXProcessor;
    require Plugins::MellowDSP::FIRProcessor;
    
    Plugins::MellowDSP::SOXProcessor->init();
    Plugins::MellowDSP::FIRProcessor->init();
    
    registerTranscoders();
    
    $class->SUPER::initPlugin(
        feed   => \&Plugins::MellowDSP::Settings::menu,
        tag    => 'mellowdsp',
    );
    
    $log->info("MellowDSP Plugin initialized successfully");
}

sub registerTranscoders {
    
    return unless $prefs->get('enabled');
    
    my $soxPath = $prefs->get('sox_path') || '/usr/bin/sox';
    
    $log->info("Registering MellowDSP transcoders...");
    
    my @conversions = (
        ['flc', 'wav'],
        ['aif', 'wav'],
        ['alc', 'wav'],
    );
    
    foreach my $conv (@conversions) {
        my ($from, $to) = @$conv;
        my $profile = "$from-$to-mellowdsp-*-*";
        
        my $command = "$soxPath -t $from \$FILE\$ -t $to -b 24 -";
        
        $Slim::Player::TranscodingHelper::commandTable{$profile} = $command;
        
        $Slim::Player::TranscodingHelper::capabilities{$profile} = {
            'T' => 'F',
        };
        
        $log->info("Registered: $profile -> $command");
    }
    
    $log->info("MellowDSP transcoders registered");
}

1;
