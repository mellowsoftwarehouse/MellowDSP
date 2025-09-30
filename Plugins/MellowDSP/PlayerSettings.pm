package Plugins::MellowDSP::PlayerSettings;

use strict;
use warnings;
use base qw(Slim::Web::Settings);
use Slim::Utils::Log;
use Slim::Utils::Prefs;

my $log = logger('plugin.mellowdsp.player');
my $prefs = preferences('plugin.mellowdsp');
my $plugin;

sub new {
    my $class = shift;
    $plugin = shift;
    
    $class->SUPER::new;
}

sub name {
    return Slim::Web::HTTP::CSRF->protectName('PLUGIN_MELLOWDSP_PLAYER');
}

sub needsClient {
    return 1;
}

sub page {
    return Slim::Web::HTTP::CSRF->protectURI('plugins/MellowDSP/playersettings/basic.html');
}

sub handler {
    my ($class, $client, $params, $callback, @args) = @_;
    
    return undef unless $client;
    
    my $clientPrefs = $prefs->client($client);
    
    if ($params->{saveSettings}) {
        $clientPrefs->set('player_enabled', $params->{pref_player_enabled} ? 1 : 0);
        $clientPrefs->set('fir_enabled', $params->{pref_fir_enabled} ? 1 : 0);
        $clientPrefs->set('fir_left', $params->{pref_fir_left} || '');
        $clientPrefs->set('fir_right', $params->{pref_fir_right} || '');
        $clientPrefs->set('target_rate', $params->{pref_target_rate} || '176400');
        $clientPrefs->set('phase_response', $params->{pref_phase_response} || 'linear');
        $clientPrefs->set('output_depth', $params->{pref_output_depth} || '24');
        $clientPrefs->set('dither_type', $params->{pref_dither_type} || 'none');
        $clientPrefs->set('dither_precision', $params->{pref_dither_precision} || '24');
        
        my @inputFormats = ();
        push @inputFormats, 'aiff' if $params->{pref_input_aiff};
        push @inputFormats, 'alac' if $params->{pref_input_alac};
        push @inputFormats, 'flac' if $params->{pref_input_flac};
        push @inputFormats, 'wav' if $params->{pref_input_wav};
        $clientPrefs->set('input_formats', join(',', @inputFormats));
        
        $log->info("Player settings saved for " . $client->name());
    }
    
    my $inputFormats = $clientPrefs->get('input_formats') || 'flac,wav';
    my @inputFormatList = split(',', $inputFormats);
    my %inputFormatsHash = map { $_ => 1 } @inputFormatList;
    
    $params->{prefs} = {
        player_enabled => $clientPrefs->get('player_enabled') || 0,
        fir_enabled => $clientPrefs->get('fir_enabled') || 0,
        fir_left => $clientPrefs->get('fir_left') || '',
        fir_right => $clientPrefs->get('fir_right') || '',
        target_rate => $clientPrefs->get('target_rate') || '176400',
        phase_response => $clientPrefs->get('phase_response') || 'linear',
        output_depth => $clientPrefs->get('output_depth') || '24',
        dither_type => $clientPrefs->get('dither_type') || 'none',
        dither_precision => $clientPrefs->get('dither_precision') || '24',
        input_aiff => $inputFormatsHash{'aiff'} || 0,
        input_alac => $inputFormatsHash{'alac'} || 0,
        input_flac => $inputFormatsHash{'flac'} || 1,
        input_wav => $inputFormatsHash{'wav'} || 1,
    };
    
    return $class->SUPER::handler($client, $params);
}

1;
