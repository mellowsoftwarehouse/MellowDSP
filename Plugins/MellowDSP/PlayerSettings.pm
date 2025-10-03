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
        player_enabled
        input_aiff
        input_alac
        input_flac
        input_wav
        target_rate
        phase_response
        output_depth
        dither_type
        dither_precision
        fir_enabled
        fir_left
        fir_right
        output_format
    ));
}

1;
