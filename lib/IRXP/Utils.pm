package IRXP::Utils;

require Exporter;

use Cwd 'abs_path';
use File::Basename;
use Data::Dumper;

use IRXP::Log;

our @ISA = qw(Exporter);
 
our @EXPORT = qw(
	trim ltrim rtrim basedir get_file
);

# Perl trim function to remove whitespace from the start and end of the string
sub trim {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

# Left trim function to remove leading whitespace
sub ltrim {
	my $string = shift;
	$string =~ s/^\s+//;
	return $string;
}

# Right trim function to remove trailing whitespace
sub rtrim {
	my $string = shift;
	$string =~ s/\s+$//;
	return $string;
}


sub basedir {
	my $script_path = dirname(__FILE__) . '/../..';
	return $script_path;
}

sub get_file {
    my $filename = $_[0];
    open(INFO, $filename) or IRXP::Log->log(message => "Error opening $filename: $!", type => IRXP::Log::LOG_TYPE_ERROR);
    @lines = <INFO>;
    close(INFO);
    return join '', @lines;
}

1;