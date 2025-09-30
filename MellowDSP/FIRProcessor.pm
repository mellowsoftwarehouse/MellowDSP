package Plugins::MellowDSP::FIRProcessor;

use strict;
use warnings;

use Slim::Utils::Log;
use Slim::Utils::Prefs;

my $log   = logger('plugin.mellowdsp');
my $prefs = preferences('plugin.mellowdsp');

sub prepare_filters_for_rate {
	my ($target_rate) = @_;

	return unless $prefs->get('fir_enabled');

	my $left  = $prefs->get('fir_left')  || '';
	my $right = $prefs->get('fir_right') || '';

	unless (-r $left && -r $right) {
		$log->warn("FIR files not readable: L=$left R=$right");
		return;
	}

	my %out = (
		left  => $left,
		right => $right,
	);

	return \%out;
}

1;
