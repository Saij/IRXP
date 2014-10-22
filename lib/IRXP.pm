package IRXP;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp;
use Class::Load ':all';
use Data::Dumper;
use Module::Find;

use IRXP::Log;
use IRXP::Utils;

use InterRed::Config::Globals;

sub install_xpack {
	my ($class, %options) = @_;

	my $logfile 	= $options{logfile};
	my $loglevel 	= $options{loglevel} || IRXP::Log::LOG_TYPE_WARNING;

	my $facilities  = {
		Stderr => {level => IRXP::Log::LOG_TYPE_ERROR}
	};

	$facilities->{'File'} = {filename => $logfile} if ($logfile);

	IRXP::Log->new(facilities => $facilities, level => $loglevel);
	IRXP::Log->log(message => 'Logsystem startet...', type => IRXP::Log::LOG_TYPE_INFO);

	foreach my $module (findallmod IRXP::Modules) {
		IRXP::Log->log(message => "Loading module $module...", type => IRXP::Log::LOG_TYPE_INFO);
		my ($result, $error) = try_load_class($module);
		if (!$result) {
			IRXP::Log->log(message => "Could not load module $module: $error!", type => IRXP::Log::LOG_TYPE_ERROR);
			next;
		}

		my $object = $module->new();
		next unless ($object->is_correct_version($version_string));

		$object->init_overwrites();
	}

	IRXP::Log->log(message => 'IR Xtension Pack startet...', type => IRXP::Log::LOG_TYPE_INFO);
}

1;