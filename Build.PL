use 5.006;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/deps/lib/perl5";
use local::lib "$FindBin::Bin/deps";

use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'IRXP',
    license             => 'perl',
    dist_author         => q{von Affenfels GmbH <info@vonaffenfels.de>},
    dist_abstract       => 'InterRed Xtension Pack',
    dist_version_from   => 'lib/IRXP.pm',
    requires => {
        'perl'                      => '5.006',
        'Class::Load'               => '0.22',
        'Data::Dumper'              => '0',
        'Module::Find'              => '0.12'
    },
    add_to_cleanup      => [ 'IRXP-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();