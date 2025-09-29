package Plugins::MellowDSP::UploadHandler;

use strict;
use warnings;
use Slim::Utils::Log;
use Slim::Utils::Prefs;
use File::Spec::Functions qw(catfile catdir);
use File::Path qw(make_path);
use CGI;

my $log = logger('plugin.mellowdsp.upload');
my $prefs = preferences('plugin.mellowdsp');

sub handleUpload {
    my ($class, $client, $params) = @_;
    
    return unless $client;
    
    my $cgi = CGI->new($params);
    my $channel = $params->{channel} || 'left';
    my $fh = $cgi->upload('file');
    
    unless ($fh) {
        $log->error("No file uploaded");
        return { error => "No file uploaded" };
    }
    
    my $dataDir = catdir($prefs->get('cachedir') || '/tmp', 'mellowdsp', 'uploads');
    make_path($dataDir) unless -d $dataDir;
    
    my $clientId = $client->id();
    my $filename = $cgi->param('file');
    $filename =~ s/.*[\/\\]//;
    $filename =~ s/[^a-zA-Z0-9._-]/_/g;
    
    my $uploadPath = catfile($dataDir, "${clientId}_${channel}_${filename}");
    
    open(my $outfh, '>', $uploadPath) or do {
        $log->error("Cannot write file: $uploadPath");
        return { error => "Cannot write file" };
    };
    
    binmode($outfh);
    my $buffer;
    while (read($fh, $buffer, 8192)) {
        print $outfh $buffer;
    }
    close($outfh);
    close($fh);
    
    $log->info("File uploaded: $uploadPath");
    
    require Plugins::MellowDSP::FIRProcessor;
    Plugins::MellowDSP::FIRProcessor->processUploadedFile($client, $uploadPath, $channel);
    
    return { 
        success => 1, 
        path => $uploadPath,
        channel => $channel 
    };
}

1;
