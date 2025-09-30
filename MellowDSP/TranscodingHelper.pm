package Plugins::MellowDSP::TranscodingHelper;

use strict;
use warnings;

use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Slim::Player::TranscodingHelper;

my $log   = logger('plugin.mellowdsp');
my $prefs = preferences('plugin.mellowdsp');

sub init {
	$log->info("TranscodingHelper initializing...");
	registerConverters();
	$log->info("TranscodingHelper initialized");
}

sub registerConverters {

	my @inputs  = qw(flc aif alc wav);
	my $output  = 'wav';

	for my $in (@inputs) {
		my $profile = "${in}-${output}-mellowdsp-*-*";
		my $command = _buildCommandTemplate($in, $output);

		next unless $command;

		$Slim::Player::TranscodingHelper::commandTable{$profile} = $command;
		$Slim::Player::TranscodingHelper::capabilities{$profile} = "MellowDSP: $in->$output";
		$log->info("Registered converter: $profile");
	}
}

sub _buildCommandTemplate {
	my ($inputFormat, $outputFormat) = @_;

	my $sox = $prefs->get('sox_path') || '/usr/bin/sox';
	return unless -x $sox;

	my $buf = $prefs->get('buffer_size') || '8';

	my $cmd = $inputFormat eq 'flc'
		? [ 'flac', '-dcs', '-']
		: $inputFormat eq 'alc'
			? [ 'ffmpeg', '-loglevel', 'error', '-i', '-', '-f', 'wav', '-' ]
			: [ 'cat' ];

	my $pipeline = join(' ',
		'|', @$cmd,
		'|', $sox, '--buffer', $buf, '-', '-t', 'wav', '-'
	);

	return $pipeline;
}

1;
