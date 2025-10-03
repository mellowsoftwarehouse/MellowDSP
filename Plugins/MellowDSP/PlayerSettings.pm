package Plugins::MellowDSP::PlayerSettings;

use strict;
use warnings;
use base qw(Slim::Web::Settings);
use Slim::Utils::Log;
use Slim::Utils::Prefs;
use File::Spec::Functions qw(catfile catdir);
use File::Copy;

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
        my $needsReload = 0;
        
        my $oldFirEnabled = $clientPrefs->get('fir_enabled') || 0;
        my $oldTargetRate = $clientPrefs->get('target_rate') || '';
        my $oldOutputFormat = $clientPrefs->get('output_format') || 'wav';
        
        $clientPrefs->set('player_enabled', $params->{pref_player_enabled} ? 1 : 0);
        $clientPrefs->set('fir_enabled', $params->{pref_fir_enabled} ? 1 : 0);
        $clientPrefs->set('target_rate', $params->{pref_target_rate} || '176400');
        $clientPrefs->set('phase_response', $params->{pref_phase_response} || 'linear');
        $clientPrefs->set('output_depth', $params->{pref_output_depth} || '24');
        $clientPrefs->set('dither_type', $params->{pref_dither_type} || 'none');
        $clientPrefs->set('dither_precision', $params->{pref_dither_precision} || '24');
        $clientPrefs->set('output_format', $params->{pref_output_format} || 'wav');
        
        my $pluginDir = Plugins::MellowDSP::Plugin->_pluginDataFor('basedir');
        my $firDir = catdir($pluginDir, 'FIR', 'masters');
        mkdir($firDir) unless -d $firDir;
        
        if ($params->{pref_fir_left_upload} && $params->{pref_fir_left_upload} ne '') {
            my $filename = 'left_' . $client->id() . '.wav';
            my $filepath = catfile($firDir, $filename);
            
            open(my $fh, '>', $filepath) or $log->error("Cannot write FIR left: $!");
            binmode($fh);
            print $fh $params->{pref_fir_left_upload};
            close($fh);
            
            $clientPrefs->set('fir_left', $filepath);
            $log->info("Uploaded left FIR: $filepath");
            $needsReload = 1;
        } elsif ($params->{pref_fir_left}) {
            $clientPrefs->set('fir_left', $params->{pref_fir_left});
        }
        
        if ($params->{pref_fir_right_upload} && $params->{pref_fir_right_upload} ne '') {
            my $filename = 'right_' . $client->id() . '.wav';
            my $filepath = catfile($firDir, $filename);
            
            open(my $fh, '>', $filepath) or $log->error("Cannot write FIR right: $!");
            binmode($fh);
            print $fh $params->{pref_fir_right_upload};
            close($fh);
            
            $clientPrefs->set('fir_right', $filepath);
            $log->info("Uploaded right FIR: $filepath");
            $needsReload = 1;
        } elsif ($params->{pref_fir_right}) {
            $clientPrefs->set('fir_right', $params->{pref_fir_right});
        }
        
        my @inputFormats = ();
        push @inputFormats, 'aiff' if $params->{pref_input_aiff};
        push @inputFormats, 'alac' if $params->{pref_input_alac};
        push @inputFormats, 'flac' if $params->{pref_input_flac};
        push @inputFormats, 'wav' if $params->{pref_input_wav};
        $clientPrefs->set('input_formats', join(',', @inputFormats));
        
        my $newFirEnabled = $clientPrefs->get('fir_enabled') || 0;
        my $newTargetRate = $clientPrefs->get('target_rate') || '';
        my $newOutputFormat = $clientPrefs->get('output_format') || 'wav';
        
        if ($oldFirEnabled != $newFirEnabled || $oldTargetRate ne $newTargetRate || $oldOutputFormat ne $newOutputFormat) {
            $needsReload = 1;
        }
        
        if ($needsReload) {
            Plugins::MellowDSP::Plugin::_setupTranscoderForClient($client);
            
            if ($client->isPlaying() || $client->isPaused()) {
                my $songIndex = Slim::Player::Source::songIndex($client);
                $client->execute(['playlist', 'index', $songIndex, 'noplay:1']);
                $client->execute(['playlist', 'index', $songIndex + 1]);
                
                $log->info("Settings changed, reloading transcoder and skipping track for: " . $client->name());
            }
        }
        
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
        output_format => $clientPrefs->get('output_format') || 'wav',
        input_aiff => $inputFormatsHash{'aiff'} || 0,
        input_alac => $inputFormatsHash{'alac'} || 0,
        input_flac => $inputFormatsHash{'flac'} || 1,
        input_wav => $inputFormatsHash{'wav'} || 1,
    };
    
    return $class->SUPER::handler($client, $params);
}

1;
