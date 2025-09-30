package Plugins::MellowDSP::PlayerSettings;

use strict;
use warnings;

use Slim::Utils::Prefs;
use Slim::Utils::Log;

my $prefs = preferences('plugin.mellowdsp');
my $log   = logger('plugin.mellowdsp');

sub init {
	$prefs->init({
		player_enabled   => 0,
		input_aiff       => 1,
		input_alac       => 1,
		input_flac       => 1,
		input_wav        => 1,
		output_format    => 'wav',
		target_rate      => '44100',
		phase_response   => 'linear',
		output_depth     => '24',
		dither_type      => 'none',
		dither_precision => '24',
		fir_enabled      => 0,
		fir_left         => '',
		fir_right        => '',
	});
}

1;
