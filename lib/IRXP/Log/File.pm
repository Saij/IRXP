package IRXP::Log::File;

use strict;
use warnings;

use Carp;

use IRXP::Utils;

sub new {
	my ($class, %options) = @_;
	
	my $filename = $options{filename} || confess 'No filename given!';
	if ($filename !~ m@^/@) {
		$filename = basedir() . "/../$filename";
	}
	
	my $format 	= $options{format} 	|| IRXP::Log::DEFAULT_FORMAT;
	my $level	= $options{level}	|| confess 'No maximal log level provided!';
	
	my $data = {
		_format		=> $format,
		_level		=> $level,
		_filename 	=> $filename
	};
	
	return bless $data, $class;
}

sub DESTROY {
	my $self = shift;
	$self->SUPER::DESTROY if $self->can('SUPER::DESTROY');
}

sub log {
	my ($self, %options) = @_;
	
	my $message = $options{'message'} 	|| confess 'No message given!';
	my $type	= $options{'type'}		|| IRXP::Log::LOG_TYPE_INFO;
	my $time	= $options{'time'}		|| confess 'No time given!';
	my $pid		= $options{'pid'}		|| confess 'No PID given!';
	my $caller	= $options{'caller'}	|| '';
	
	return if ($type > $self->{_level});
	
	my $typestring = IRXP::Log::log_type_string($type);
	
	my $text = $self->{_format};
	$text =~ s/%%TIME%%/$time/simg;
	$text =~ s/%%PID%%/$pid/simg;
	$text =~ s/%%TYPE%%/$typestring/simg;
	$text =~ s/%%MESSAGE%%/$message/simg;
	$text =~ s/%%CALLER%%/$caller/simg;
	
	open my $logfile, '>>' . $self->{_filename} or confess 'Could not open logfile ' . $self->{_filename} . ': ' . $!;
	print $logfile $text;
	close $logfile;
}

1;