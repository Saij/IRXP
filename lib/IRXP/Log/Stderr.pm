package IRXP::Log::Stderr;

use strict;
use warnings;

use Carp;

sub new {
	my ($class, %options) = @_;
	
	my $data = {
		_format	=> $options{format} || IRXP::Log::DEFAULT_FORMAT,
		_level	=> $options{level}	|| confess 'No maximal log level provided!'
	};
		
	return bless $data, $class;
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
	
	print STDERR $text;
}

1;