package Plugins::MellowDSP::Plugin;

use strict;
use warnings;
use base qw(Slim::Plugin::Base);
use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Slim::Player::TranscodingHelper;
use Slim::Player::Client;
use Slim::Control::Request;
use File::Spec::Functions qw(catfile catdir);
use Cwd qw(abs_path);

my $log;
my $prefs = preferences('plugin.mellowdsp');
my $class;

sub initPlugin {
    $class = shift;
    
    $log = Slim::Utils::Log->addLogCategory({
        category     => 'plugin.mellowdsp',
        defaultLevel => 'DEBUG',
        description  => 'PLUGIN_MELLOWDSP',
    });
    
    $log->info("MellowDSP v3.1.0 initializing...");
    
    $prefs->init({
        enabled => 0,
        sox_path => '/usr/bin/sox',
    });
    
    if (main::WEBUI) {
        require Plugins::MellowDSP::Settings;
        require Plugins::MellowDSP::PlayerSettings;
        
        Plugins::MellowDSP::Settings->new($class);
        Plugins::MellowDSP::PlayerSettings->new($class);
    }
    
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
    
    $log->info("Disabling conflicting profiles...");
    
    my $conv = Slim::Player::TranscodingHelper::Conversions();
    my $count = 0;
    
    for my $profile (keys %$conv) {
        if ($profile =~ /^(flc|aif|alc)-/) {
            delete $Slim::Player::TranscodingHelper::commandTable{$profile};
            delete $Slim::Player::TranscodingHelper::capabilities{$profile};
            $count++;
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
        return;
    }
    
    unless ($clientPrefs->get('player_enabled')) {
        return;
    }
    
    my $macaddress = $client->id();
    
    my $scriptPath = abs_path(__FILE__);
    $scriptPath =~ s/Plugin\.pm$/Bin\/mellowdsp.pl/;
    
    $log->info("Script absolute path: $scriptPath");
    
    if (!-f $scriptPath) {
        $log->error("Script not found at: $scriptPath");
        return;
    }
    
    if (!-x $scriptPath) {
        $log->error("Script not executable at: $scriptPath");
        return;
    }
    
    my $outputFormat = $clientPrefs->get('output_format') || 'wav';
    my $targetRate = $clientPrefs->get('target_rate') || '';
    my $firEnabled = $clientPrefs->get('fir_enabled') || 0;
    my $firLeft = $clientPrefs->get('fir_left') || '';
    my $firRight = $clientPrefs->get('fir_right') || '';
    
    $log->info("Setting up transcoder for " . $client->name());
    $log->info("FIR enabled: $firEnabled");
    
    my $pluginDir = abs_path(__FILE__);
    $pluginDir =~ s/Plugin\.pm$//;
    
    my @inputFormats = qw(flc aif alc);
    
    foreach my $inFmt (@inputFormats) {
        my $outFmt = ($outputFormat eq 'flac') ? 'flc' : 'wav';
        my $profile = "$inFmt-$outFmt-*-$macaddress";
        
        my $command = "[perl] $scriptPath -c \$CLIENTID\$ -i $inFmt -o $outputFormat";
        
        if ($targetRate) {
            $command .= " -r $targetRate";
        }
        
        if ($firEnabled && $firLeft && $firRight && -f $firLeft && -f $firRight) {
            require Plugins::MellowDSP::CamillaDSPHelper;
            
            my $configFile = Plugins::MellowDSP::CamillaDSPHelper->generateConfig(
                $macaddress, 
                $targetRate || 96000, 
                $firLeft, 
                $firRight
            );
            
            if ($configFile) {
                $command .= " --fir --fir-config=$configFile";
                $log->info("FIR filter enabled with config: $configFile");
            }
        }
        
        $command .= " \$FILE\$";
        
        $Slim::Player::TranscodingHelper::commandTable{$profile} = $command;
        
        $Slim::Player::TranscodingHelper::capabilities{$profile} = {
            F => 'noArgs',
            R => 'noArgs',
            I => 'noArgs',
        };
        
        $log->info("Registered: $profile");
        $log->info("Command: $command");
    }
}

sub getDisplayName {
    return 'PLUGIN_MELLOWDSP';
}

1;
