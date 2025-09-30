package Plugins::MellowDSP::Settings;

use strict;
use warnings;

use Slim::Utils::Prefs;
use Slim::Utils::Log;

my $prefs = preferences('plugin.mellowdsp');
my $log   = logger('plugin.mellowdsp');

sub init {
	$prefs->init({
		enabled      => 0,
		sox_path     => '/usr/bin/sox',
		ffmpeg_path  => '/usr/bin/ffmpeg',
		buffer_size  => '8',
		sox_exists   => 0,
		ffmpeg_exists=> 0,
	});

	_validate_bins();
}

sub _validate_bins {
	my $sox = $prefs->get('sox_path') || '';
	my $ffm = $prefs->get('ffmpeg_path') || '';

	$prefs->set('sox_exists',   (-x $sox) ? 1 : 0);
	$prefs->set('ffmpeg_exists',(-x $ffm) ? 1 : 0);

	$log->info("SOX: ".($prefs->get('sox_exists') ? 'found' : 'not found')." at $sox");
	$log->info("FFMPEG: ".($prefs->get('ffmpeg_exists') ? 'found' : 'not found')." at $ffm");
}

1;
