#!/usr/bin/perl
package Plugins::MellowDSP::Plugin;

use strict;
use warnings;
use base qw(Slim::Plugin::Base);
use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Slim::Web::Pages;

my $log = logger('plugin.mellowdsp');
my $prefs = preferences('plugin.mellowdsp');

sub initPlugin {
    my $class = shift;
    
    $log->info("MellowDSP v2.1.0 initializing...");
    
    $prefs->init({
        enabled => 0,
        sox_path => '/usr/bin/sox',
        ffmpeg_path => '/usr/bin/ffmpeg',
        buffer_size => 8,
    });
    
    if (main::WEBUI) {
        require Plugins::MellowDSP::Settings;
        require Plugins::MellowDSP::PlayerSettings;
        require Plugins::MellowDSP::UploadHandler;
        
        Plugins::MellowDSP::Settings->new($class);
        Plugins::MellowDSP::PlayerSettings->new($class);
        
        Slim::Web::Pages->addRawFunction(
            'plugins/MellowDSP/upload',
            \&Plugins::MellowDSP::UploadHandler::handleUpload
        );
    }
    
    require Plugins::MellowDSP::SOXProcessor;
    require Plugins::MellowDSP::FIRProcessor;
    Plugins::MellowDSP::SOXProcessor->init();
    Plugins::MellowDSP::FIRProcessor->init();
    
    $class->SUPER::initPlugin(@_);
    $log->info("MellowDSP loaded successfully");
}

sub getDisplayName {
    return 'PLUGIN_MELLOWDSP';
}

1;
