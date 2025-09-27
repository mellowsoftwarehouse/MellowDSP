#!/usr/bin/perl
package Plugins::MellowDSP::Plugin;

use strict;
use warnings;
use base qw(Slim::Plugin::Base);
use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Slim::Web::Pages;
use Plugins::MellowDSP::PlayerSettings;
use Plugins::MellowDSP::Settings;
use Plugins::MellowDSP::SOXProcessor;
use Plugins::MellowDSP::FIRProcessor;

my $log = logger('plugin.mellowdsp');
my $prefs = preferences('plugin.mellowdsp');

sub initPlugin {
    my $class = shift;
    
    $log->info("MellowDSP v2.0.0 initializing...");
    
    # Preferenze globali
    $prefs->init({
        enabled => 0,
        sox_path => '/usr/bin/sox',
        ffmpeg_path => '/usr/bin/ffmpeg',
        buffer_size => 8,
    });
    
    # Registra pagina Advanced Settings
    Slim::Web::Pages->addPageFunction(
        'plugins/MellowDSP/settings/advanced.html',
        \&Plugins::MellowDSP::Settings::advancedSettings
    );
    
    # Registra pagina Player Settings
    Slim::Web::Pages->addPageFunction(
        'plugins/MellowDSP/playersettings/basic.html',
        \&Plugins::MellowDSP::PlayerSettings::playerSettings
    );
    
    # Inizializza moduli
    Plugins::MellowDSP::SOXProcessor->init();
    Plugins::MellowDSP::FIRProcessor->init();
    
    $class->SUPER::initPlugin(@_);
    $log->info("MellowDSP loaded successfully");
}

sub getDisplayName {
    return 'PLUGIN_MELLOWDSP';
}

sub settingsClass {
    return 'Plugins::MellowDSP::Settings';
}

1;
