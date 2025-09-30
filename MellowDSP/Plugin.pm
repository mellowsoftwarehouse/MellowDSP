package Plugins::MellowDSP::Plugin;

use strict;
use warnings;

use Slim::Utils::Log;
use Slim::Utils::Prefs;

use Plugins::MellowDSP::Settings;
use Plugins::MellowDSP::PlayerSettings;
use Plugins::MellowDSP::TranscodingHelper;

my $log   = logger('plugin.mellowdsp');
my $prefs = preferences('plugin.mellowdsp');

sub getDisplayName {
	return 'PLUGIN_MELLOWDSP';
}

sub initPlugin {
	$log->info("MellowDSP initializing plugin");
	Plugins::MellowDSP::Settings->init();
	Plugins::MellowDSP::PlayerSettings->init();
	Plugins::MellowDSP::TranscodingHelper->init();
	$log->info("MellowDSP plugin initialized");
}

sub enabled {
	return $prefs->get('enabled') ? 1 : 0;
}

sub shutdownPlugin {
	$log->info("MellowDSP shutting down");
}

sub webPages {
	my %pages = (
		'plugins/MellowDSP/settings/advanced.html' => 1,
		'plugins/MellowDSP/playersettings/basic.html' => 1,
	);
	return \%pages;
}

1;
