package Plugins::MellowDSP::PlayerSettings;

use strict;
use warnings;
use base qw(Slim::Web::Settings);
use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Plugins::MellowDSP::FIRProcessor;

my $log = logger('plugin.mellowdsp.player');
my $prefs = preferences('plugin.mellowdsp');

sub name {
    return 'PLUGIN_MELLOWDSP_PLAYER';
}

sub page {
    return 'plugins/MellowDSP/playersettings/basic.html';
}

sub needsClient {
    return 1;
}

sub prefs {
    return ($prefs, qw(player_enabled input_formats max_pcm_rate output_rates target_rate phase_response fir_left fir_right fir_enabled));
}

sub playerSettings {
    my ($client, $params) = @_;
    
    return unless $client;
    
    my $clientPrefs = $prefs->client($client);
    
    if ($params->{saveSettings}) {
        # Salva impostazioni player
        $clientPrefs->set('player_enabled', $params->{pref_player_enabled} ? 1 : 0);
        $clientPrefs->set('fir_enabled', $params->{pref_fir_enabled} ? 1 : 0);
        $clientPrefs->set('fir_left', $params->{pref_fir_left} || '');
        $clientPrefs->set('fir_right', $params->{pref_fir_right} || '');
        $clientPrefs->set('max_pcm_rate', $params->{pref_max_pcm_rate} || '768000');
        $clientPrefs->set('target_rate', $params->{pref_target_rate} || '176400');
        $clientPrefs->set('phase_response', $params->{pref_phase_response} || 'linear');
        
        # Salva formati input (checkbox multiple)
        my @inputFormats = ();
        push @inputFormats, 'aiff' if $params->{pref_input_aiff};
        push @inputFormats, 'alac' if $params->{pref_input_alac};
        push @inputFormats, 'flac' if $params->{pref_input_flac};
        push @inputFormats, 'wav' if $params->{pref_input_wav};
        $clientPrefs->set('input_formats', join(',', @inputFormats));
        
        # Salva frequenze output (checkbox multiple)
        my @outputRates = ();
        push @outputRates, '44100' if $params->{pref_output_44100};
        push @outputRates, '48000' if $params->{pref_output_48000};
        push @outputRates, '88200' if $params->{pref_output_88200};
        push @outputRates, '96000' if $params->{pref_output_96000};
        push @outputRates, '176400' if $params->{pref_output_176400};
        push @outputRates, '192000' if $params->{pref_output_192000};
        push @outputRates, '352800' if $params->{pref_output_352800};
        push @outputRates, '384000' if $params->{pref_output_384000};
        push @outputRates, '705600' if $params->{pref_output_705600};
        push @outputRates, '768000' if $params->{pref_output_768000};
        $clientPrefs->set('output_rates', join(',', @outputRates));
        
        # Aggiorna filtri FIR se cambiato target rate
        if ($clientPrefs->get('fir_enabled')) {
            Plugins::MellowDSP::FIRProcessor->updateFIRForClient(
                $client,
                $clientPrefs->get('target_rate')
            );
        }
        
        $log->info("Player settings saved for " . $client->name());
    }
    
    # Prepara parametri per template
    my $inputFormats = $clientPrefs->get('input_formats') || 'flac,wav';
    my @inputFormatList = split(',', $inputFormats);
    my %inputFormatsHash = map { $_ => 1 } @inputFormatList;
    
    my $outputRates = $clientPrefs->get('output_rates') || '44100,48000,88200,96000,176400,192000,352800,384000,705600,768000';
    my @outputRateList = split(',', $outputRates);
    my %outputRatesHash = map { $_ => 1 } @outputRateList;
    
    $params->{client_name} = $client->name();
    $params->{prefs} = {
        player_enabled => $clientPrefs->get('player_enabled') || 0,
        fir_enabled => $clientPrefs->get('fir_enabled') || 0,
        fir_left => $clientPrefs->get('fir_left') || '',
        fir_right => $clientPrefs->get('fir_right') || '',
        max_pcm_rate => $clientPrefs->get('max_pcm_rate') || '768000',
        target_rate => $clientPrefs->get('target_rate') || '176400',
        phase_response => $clientPrefs->get('phase_response') || 'linear',
        input_aiff => $inputFormatsHash{'aiff'} || 0,
        input_alac => $inputFormatsHash{'alac'} || 0,
        input_flac => $inputFormatsHash{'flac'} || 1,
        input_wav => $inputFormatsHash{'wav'} || 1,
        output_44100 => $outputRatesHash{'44100'} || 1,
        output_48000 => $outputRatesHash{'48000'} || 1,
        output_88200 => $outputRatesHash{'88200'} || 1,
        output_96000 => $outputRatesHash{'96000'} || 1,
        output_176400 => $outputRatesHash{'176400'} || 1,
        output_192000 => $outputRatesHash{'192000'} || 1,
        output_352800 => $outputRatesHash{'352800'} || 1,
        output_384000 => $outputRatesHash{'384000'} || 1,
        output_705600 => $outputRatesHash{'705600'} || 1,
        output_768000 => $outputRatesHash{'768000'} || 1,
    };
    
    return Slim::Web::HTTP::filltemplatefile(
        'plugins/MellowDSP/playersettings/basic.html',
        $params
    );
}

1;
