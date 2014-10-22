package IRXP::Log;

use strict;
use warnings;

use Carp;
use Class::Load ':all';
use Data::Dumper;

my $_instance = undef;

use constant LOG_TYPE_ERROR 	=> 1;
use constant LOG_TYPE_WARNING 	=> 2;
use constant LOG_TYPE_INFO 		=> 3;
use constant LOG_TYPE_DEBUG 	=> 4;

use constant DEFAULT_FORMAT		=> "[%%TIME%%] - PID %%PID%% - [%%TYPE%%] - [%%CALLER%%] - %%MESSAGE%%\n";

my %log_type_strings = (
	&LOG_TYPE_ERROR 		=> 'ERROR',
	&LOG_TYPE_WARNING 		=> 'WARNING',
	&LOG_TYPE_INFO 			=> 'INFO',
	&LOG_TYPE_DEBUG 		=> 'DEBUG'
);

sub new {
	return $_instance if ($_instance);

	my ($class, %options) = @_;

 	my $facilities 	= $options{facilities} 	|| {'Stderr' => {}};
	my $level		= $options{level}		|| LOG_TYPE_WARNING;
	
	my $data = {
		_level 		=> $level,
		_facilities => {}
	};
	
	foreach (keys %$facilities) {
		my $class = 'IRXP::Log::' . $_;
		load_class($class);
		$facilities->{$_}->{level} = $level if (!defined $facilities->{$_}->{level});
		$data->{_facilities}->{$_} = $class->new(%{ $facilities->{$_} });
	}
	
	$_instance = bless $data, $class;
	return $_instance;
}

sub log_type_string {
	return $log_type_strings{$_[0]};
}

sub log {
	my ($self, %options) = @_;
	$self = $_instance if (!ref $self);
	
	my $message = $options{message} || confess 'No message provided!';
	my $type	= $options{type}	|| LOG_TYPE_INFO;
	
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
	$year += 1900;
	$mon += 1;
	
	my $time = sprintf('%02d.%02d.%04d - %02d:%02d:%02d', $mday, $mon, $year, $hour, $min, $sec);
	my ($caller_package) = caller();
	
	$self->{_facilities}->{$_}->log(message => $message, type => $type, time => $time, pid => $$, caller => $caller_package) foreach (keys %{ $self->{_facilities} });
}

sub facility {
	my ($self, $facility) = @_;
	$self = $_instance if (!ref $self);	
	return $self->{_facilities}->{$facility};
}

1;