package Plugins::MellowDSP::PlayerSettings;

use strict;
use warnings;
use base qw(Slim::Web::Settings);

use Slim::Utils::Prefs;
use Slim::Utils::Log;

my $prefs = preferences('plugin.mellowdsp');
my $log = logger('plugin.mellowdsp');

sub name {
    return 'PLUGIN_MELLOWDSP';
}

sub page {
    return 'plugins/MellowDSP/playersettings/basic.html';
}

sub prefs {
    my ($class, $client) = @_;
    return ($prefs->client($client), qw(
        enabled
        output_format
        output_samplerate
        phase_response
        fir_enabled
        fir_left
        fir_right
    ));
}

sub handler {
    my ($class, $client, $params) = @_;
    
    if ($params->{'saveSettings'}) {
    }
    
    $params->{output_formats} = [
        { value => 'wav',  label => 'WAV (Uncompressed)' },
        { value => 'flac', label => 'FLAC (Lossless)' },
    ];
    
    $params->{sample_rates} = [
        { value => '0',      label => 'No resampling' },
        { value => '44100',  label => '44.1 kHz' },
        { value => '48000',  label => '48 kHz' },
        { value => '88200',  label => '88.2 kHz' },
        { value => '96000',  label => '96 kHz' },
        { value => '176400', label => '176.4 kHz' },
        { value => '192000', label => '192 kHz' },
        { value => '352800', label => '352.8 kHz' },
        { value => '384000', label => '384 kHz' },
        { value => '705600', label => '705.6 kHz' },
        { value => '768000', label => '768 kHz' },
    ];
    
    $params->{phase_responses} = [
        { value => 'linear',       label => 'Linear Phase' },
        { value => 'intermediate', label => 'Intermediate Phase' },
        { value => 'minimum',      label => 'Minimum Phase' },
    ];
    
    return $class->SUPER::handler($client, $params);
}

1;
