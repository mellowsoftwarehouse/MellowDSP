package Plugins::MellowDSP::Settings;

use strict;
use warnings;
use base qw(Slim::Web::Settings);
use Slim::Utils::Log;
use Slim::Utils::Prefs;

my $log = logger('plugin.mellowdsp.settings');
my $prefs = preferences('plugin.mellowdsp');

sub name {
    return 'PLUGIN_MELLOWDSP';
}

sub page {
    return 'plugins/MellowDSP/settings/advanced.html';
}

sub prefs {
    return ($prefs, qw(enabled sox_path ffmpeg_path buffer_size));
}

sub advancedSettings {
    my ($client, $params) = @_;
    
    if ($params->{saveSettings}) {
        $prefs->set('enabled', $params->{pref_enabled} ? 1 : 0);
        $prefs->set('sox_path', $params->{pref_sox_path} || '/usr/bin/sox');
        $prefs->set('ffmpeg_path', $params->{pref_ffmpeg_path} || '/usr/bin/ffmpeg');
        $prefs->set('buffer_size', $params->{pref_buffer_size} || 8);
        
        $log->info("Advanced settings saved");
    }
    
    # Verifica esistenza helper applications
    my $soxPath = $prefs->get('sox_path') || '/usr/bin/sox';
    my $ffmpegPath = $prefs->get('ffmpeg_path') || '/usr/bin/ffmpeg';
    
    $params->{prefs} = {
        enabled => $prefs->get('enabled') || 0,
        sox_path => $soxPath,
        ffmpeg_path => $ffmpegPath,
        buffer_size => $prefs->get('buffer_size') || 8,
        sox_exists => (-f $soxPath && -x $soxPath) ? 1 : 0,
        ffmpeg_exists => (-f $ffmpegPath && -x $ffmpegPath) ? 1 : 0,
    };
    
    return Slim::Web::HTTP::filltemplatefile(
        'plugins/MellowDSP/settings/advanced.html',
        $params
    );
}

1;
