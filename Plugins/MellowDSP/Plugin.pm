package Plugins::MellowDSP::Plugin;

use strict;
use warnings;
use base qw(Slim::Plugin::Base);
use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Slim::Player::TranscodingHelper;
use Slim::Player::Client;
use Slim::Control::Request;

my $log = logger('plugin.mellowdsp');
my $prefs = preferences('plugin.mellowdsp');
my $class;

sub initPlugin {
    $class = shift;
    
    $log->info("MellowDSP v2.4.0 initializing...");
    
    $prefs->init({
        enabled => 0,
        sox_path => '/usr/bin/sox',
        ffmpeg_path => '/usr/bin/ffmpeg',
        buffer_size => 8,
    });
    
    if (main::WEBUI) {
        require Plugins::MellowDSP::Settings;
        require Plugins::MellowDSP::PlayerSettings;
        
        Plugins::MellowDSP::Settings->new($class);
        Plugins::MellowDSP::PlayerSettings->new($class);
    }
    
    require Plugins::MellowDSP::SOXProcessor;
    require Plugins::MellowDSP::FIRProcessor;
    
    Plugins::MellowDSP::SOXProcessor->init();
    Plugins::MellowDSP::FIRProcessor->init();
    
    Slim::Control::Request::subscribe(
        \&newClientCallback,
        [['client'], ['new']],
    );
    
    Slim::Control::Request::subscribe(
        \&clientReconnectCallback,
        [['client'], ['reconnect']],
    );
    
    $class->SUPER::initPlugin(@_);
    $log->info("MellowDSP loaded successfully");
}

sub shutdownPlugin {
    Slim::Control::Request::unsubscribe(\&newClientCallback);
    Slim::Control::Request::unsubscribe(\&clientReconnectCallback);
}

sub newClientCallback {
    my $request = shift;
    my $client = $request->client();
    
    return unless $client;
    
    $log->info("New client connected: " . $client->name());
    
    _setupTranscoderForClient($client);
}

sub clientReconnectCallback {
    my $request = shift;
    my $client = $request->client();
    
    return unless $client;
    
    $log->info("Client reconnected: " . $client->name());
    
    _setupTranscoderForClient($client);
}

sub _setupTranscoderForClient {
    my $client = shift;
    
    return unless $client;
    
    my $clientPrefs = $prefs->client($client);
    
    return unless $prefs->get('enabled');
    return unless $clientPrefs->get('player_enabled');
    
    my $macaddress = $client->id();
    my $soxPath = $prefs->get('sox_path') || '/usr/bin/sox';
    
    $log->info("Setting up transcoder for " . $client->name() . " ($macaddress)");
    
    my @inputFormats = qw(flc aif alc);
    
    foreach my $inFmt (@inputFormats) {
        my $profile = "$inFmt-pcm-*-$macaddress";
        
        my $command = "$soxPath -t $inFmt \$FILE\$ -t wav -b 24 -";
        
        $Slim::Player::TranscodingHelper::commandTable{$profile} = $command;
        
        $Slim::Player::TranscodingHelper::capabilities{$profile} = {
            F => 'noArgs',
            R => 'noArgs',
            I => 'noArgs',
        };
        
        $log->info("Registered converter: $profile");
    }
}

sub getDisplayName {
    return 'PLUGIN_MELLOWDSP';
}

1;
