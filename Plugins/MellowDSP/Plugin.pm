package Plugins::MellowDSP::Plugin;

use strict;
use warnings;
use base qw(Slim::Plugin::Base);
use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Slim::Player::TranscodingHelper;
use Slim::Player::Client;
use Slim::Control::Request;

my $log;
my $prefs = preferences('plugin.mellowdsp');
my $class;

my %formatMap = (
    'flc' => 'flac',
    'aif' => 'aiff',
    'alc' => 'alac',
);

sub initPlugin {
    $class = shift;
    
    $log = Slim::Utils::Log->addLogCategory({
        category     => 'plugin.mellowdsp',
        defaultLevel => 'INFO',
        description  => 'PLUGIN_MELLOWDSP',
    });
    
    $log->info("MellowDSP v2.5.1 initializing...");
    
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
    
    _disableConflictingProfiles();
    
    my @clients = Slim::Player::Client::clients();
    foreach my $client (@clients) {
        _setupTranscoderForClient($client);
    }
    
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

sub _disableConflictingProfiles {
    
    return unless $prefs->get('enabled');
    
    $log->info("Disabling conflicting profiles for flac, aiff, alac...");
    
    my $conv = Slim::Player::TranscodingHelper::Conversions();
    my $count = 0;
    
    for my $profile (keys %$conv) {
        if ($profile =~ /^(flc|aif|alc)-/) {
            delete $Slim::Player::TranscodingHelper::commandTable{$profile};
            delete $Slim::Player::TranscodingHelper::capabilities{$profile};
            $count++;
            $log->debug("Disabled profile: $profile");
        }
    }
    
    $log->info("Disabled $count conflicting profiles");
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
    
    unless ($prefs->get('enabled')) {
        $log->warn("Plugin not enabled globally, skipping " . $client->name());
        return;
    }
    
    unless ($clientPrefs->get('player_enabled')) {
        $log->warn("Plugin not enabled for player " . $client->name());
        return;
    }
    
    my $macaddress = $client->id();
    my $soxPath = $prefs->get('sox_path') || '/usr/bin/sox';
    
    $log->info("Setting up transcoder for " . $client->name() . " ($macaddress)");
    
    my @inputFormats = qw(flc aif alc);
    
    foreach my $inFmt (@inputFormats) {
        my $profile = "$inFmt-pcm-*-$macaddress";
        
        my $soxFormat = $formatMap{$inFmt} || $inFmt;
        
        my $command = "$soxPath -t $soxFormat \$FILE\$ -t wav -b 24 -";
        
        $Slim::Player::TranscodingHelper::commandTable{$profile} = $command;
        
        $Slim::Player::TranscodingHelper::capabilities{$profile} = {
            F => 'noArgs',
            R => 'noArgs',
            I => 'noArgs',
        };
        
        $log->info("Registered converter: $profile (SOX format: $soxFormat)");
    }
}

sub getDisplayName {
    return 'PLUGIN_MELLOWDSP';
}

1;
