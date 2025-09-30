package Plugins::MellowDSP::SOXProcessor;

use strict;
use warnings;

use Slim::Utils::Prefs;

my $prefs = preferences('plugin.mellowdsp');

sub build_sox_chain {
	my %p = @_;

	my @chain;

	if ($p{target_rate}) {
		push @chain, 'rate', '-v', $p{target_rate};
	}

	if ($p{phase_response} && $p{phase_response} eq 'minimum') {
		push @chain, 'phase', 'minimum';
	} elsif ($p{phase_response} && $p{phase_response} eq 'intermediate') {
		push @chain, 'phase', 'intermediate';
	} else {
		push @chain, 'phase', 'linear';
	}

	if ($p{output_depth}) {
		push @chain, 'bits', $p{output_depth};
	}

	if ($p{dither_type} && $p{dither_type} ne 'none') {
		push @chain, 'dither';
	}

	return @chain;
}

1;
