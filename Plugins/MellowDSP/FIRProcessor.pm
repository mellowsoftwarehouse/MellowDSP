package Plugins::MellowDSP::FIRProcessor;

use strict;
use warnings;
use Slim::Utils::Log;
use Slim::Utils::Prefs;
use File::Spec::Functions qw(catfile catdir);
use File::Path qw(make_path);
use File::Copy;

my $log = logger('plugin.mellowdsp.fir');
my $prefs = preferences('plugin.mellowdsp');

sub init {
    my $dataDir = catdir($prefs->get('cachedir') || '/tmp', 'mellowdsp');
    make_path($dataDir) unless -d $dataDir;
    
    # Crea sottodirectory per master e converted files
    make_path(catdir($dataDir, 'master')) unless -d catdir($dataDir, 'master');
    make_path(catdir($dataDir, 'converted')) unless -d catdir($dataDir, 'converted');
    
    $log->info("FIR Processor initialized, data dir: $dataDir");
}

sub updateFIRForClient {
    my ($self, $client, $targetSampleRate) = @_;
    
    return unless $client && $targetSampleRate;
    
    my $clientPrefs = $prefs->client($client);
    return unless $clientPrefs->get('fir_enabled');
    
    my $leftFile = $clientPrefs->get('fir_left');
    my $rightFile = $clientPrefs->get('fir_right');
    
    return unless ($leftFile || $rightFile);
    
    $log->info("Updating FIR filters for " . $client->name() . " to $targetSampleRate Hz");
    
    # Salva files come master se non esistono
    $self->storeMasterFiles($client, $leftFile, $rightFile);
    
    # Converte alla frequenza target
    $self->convertFIRToSampleRate($client, $targetSampleRate);
}

sub storeMasterFiles {
    my ($self, $client, $leftFile, $rightFile) = @_;
    
    my $dataDir = catdir($prefs->get('cachedir') || '/tmp', 'mellowdsp', 'master');
    my $clientId = $client->id();
    
    if ($leftFile && -f $leftFile) {
        my $masterLeft = catfile($dataDir, "${clientId}_left_master.wav");
        unless (-f $masterLeft) {
            copy($leftFile, $masterLeft) or $log->error("Cannot copy left master: $!");
            $log->info("Stored master left FIR: $masterLeft");
        }
    }
    
    if ($rightFile && -f $rightFile) {
        my $masterRight = catfile($dataDir, "${clientId}_right_master.wav");
        unless (-f $masterRight) {
            copy($rightFile, $masterRight) or $log->error("Cannot copy right master: $!");
            $log->info("Stored master right FIR: $masterRight");
        }
    }
}

sub convertFIRToSampleRate {
    my ($self, $client, $targetRate) = @_;
    
    my $clientId = $client->id();
    my $dataDir = catdir($prefs->get('cachedir') || '/tmp', 'mellowdsp');
    my $masterDir = catdir($dataDir, 'master');
    my $convertedDir = catdir($dataDir, 'converted');
    
    my $masterLeft = catfile($masterDir, "${clientId}_left_master.wav");
    my $masterRight = catfile($masterDir, "${clientId}_right_master.wav");
    
    my $convertedLeft = catfile($convertedDir, "${clientId}_left_${targetRate}.wav");
    my $convertedRight = catfile($convertedDir, "${clientId}_right_${targetRate}.wav");
    
    my $soxPath = $prefs->get('sox_path') || '/usr/bin/sox';
    return unless (-f $soxPath && -x $soxPath);
    
    # Converte left channel se esiste
    if (-f $masterLeft) {
        my $cmd = "$soxPath \"$masterLeft\" \"$convertedLeft\" rate -v -s $targetRate";
        my $result = system($cmd);
        if ($result == 0) {
            $log->info("Converted left FIR to $targetRate Hz: $convertedLeft");
        } else {
            $log->error("Failed to convert left FIR: $cmd");
        }
    }
    
    # Converte right channel se esiste
    if (-f $masterRight) {
        my $cmd = "$soxPath \"$masterRight\" \"$convertedRight\" rate -v -s $targetRate";
        my $result = system($cmd);
        if ($result == 0) {
            $log->info("Converted right FIR to $targetRate Hz: $convertedRight");
        } else {
            $log->error("Failed to convert right FIR: $cmd");
        }
    }
}

sub getFIRPath {
    my ($self, $client, $channel) = @_;
    
    return '' unless $client && $channel;
    
    my $clientPrefs = $prefs->client($client);
    return '' unless $clientPrefs->get('fir_enabled');
    
    my $targetRate = $clientPrefs->get('target_rate') || '176400';
    my $clientId = $client->id();
    my $dataDir = catdir($prefs->get('cachedir') || '/tmp', 'mellowdsp', 'converted');
    
    my $firFile = catfile($dataDir, "${clientId}_${channel}_${targetRate}.wav");
    
    return (-f $firFile) ? $firFile : '';
}

sub cleanupOldFiles {
    my ($self, $client) = @_;
    
    return unless $client;
    
    my $clientId = $client->id();
    my $dataDir = catdir($prefs->get('cachedir') || '/tmp', 'mellowdsp', 'converted');
    
    # Rimuovi vecchi file converted per questo client
    opendir(my $dh, $dataDir) or return;
    my @files = grep { /^${clientId}_/ } readdir($dh);
    closedir($dh);
    
    foreach my $file (@files) {
        my $fullPath = catfile($dataDir, $file);
        unlink($fullPath);
        $log->info("Cleaned up old FIR file: $fullPath");
    }
}

1;
