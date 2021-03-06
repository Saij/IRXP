#
# t/taint-mode.t: checks that local::lib sets up @INC correctly when
# included in a script that has taint mode on, and is executing in an
# environment in which local::lib has already been loaded.
#

use strict;
use warnings;
use Cwd; # load before anything else to work around ActiveState bug
use Test::More tests => 4;
use File::Temp 'tempfile';
use File::Basename qw(basename dirname);
use File::Spec;
use IPC::Open3;
use Config;

use lib 't/lib'; use TempDir;

my @INC_CLEAN = @INC;

my $dir1 = mk_temp_dir('used_in_taint-XXXXX');
my $dir2 = mk_temp_dir('not_used_in_taint-XXXXX');

# Set up local::lib environment using our temp dir
require local::lib;
local::lib->import($dir1);
local::lib->import($dir2);

# Create a script that has taint mode turned on, and tries to use a
# local lib to the same temp dir.
mkdir 't/temp';
my ($fh, $filename) = tempfile(
  'test_local_lib-XXXXX',
  DIR => Cwd::abs_path('t/temp'),
  UNLINK => 1,
);

print $fh <<"EOM";
#!/usr/bin/perl -T
use strict; use warnings;
use local::lib "\Q$dir1\E";
print "\$_\\n" for \@INC;
EOM
close $fh;

open my $in, '<', File::Spec->devnull;
my $pid = open3($in, my $out, undef, $^X, map("-I$_", @INC_CLEAN), '-T', $filename);
my @libs = <$out>;
s/[\r\n]*\z// for @libs;
close $out;
waitpid $pid, 0;
is $?, 0, 'test script ran without error';

my $dir1_lib = local::lib->install_base_perl_path($dir1);
ok grep($_ eq $dir1_lib, @libs),
  'local::lib used in taint script added to @INC'
  or diag "searched for '$dir1_lib' in: ", join(', ', map "'$_'", @libs);

my $dir2_lib = local::lib->install_base_perl_path($dir2);
ok !grep($_ eq $dir2_lib, @libs),
  'local::lib not used used in taint script not added to @INC'
  or diag "searched for '$dir2_lib' in: ", join(', ', map "'$_'", @libs);

{
  my $perl_file = basename($^X);
  if (!File::Spec->file_name_is_absolute($^X)) {
    my $perl_dir = dirname($^X);
    $ENV{PATH} = join($Config{path_sep}, $ENV{PATH}, $perl_dir);
  }

  my ($fh, $filename) = tempfile(
    'test_local_lib-XXXXX',
    DIR => Cwd::abs_path('t/temp'),
    UNLINK => 1,
  );

  print $fh <<'EOM';
#!/usr/bin/perl -T
use strict; use warnings;
use local::lib ();
print local::lib::_cwd();
EOM
  close $fh;

  open my $err, '>', File::Spec->devnull
    or die "can't open null output: $!";
  my $out;
  my $pid = open3($in, $out, $err, $^X, map("-I$_", @INC_CLEAN), '-T', $filename);
  my $cwd = do { local $/; <$out> };
  $cwd =~ s/[\r\n]*\z//;
  $cwd = File::Spec->canonpath($cwd);
  is $cwd, File::Spec->canonpath(Cwd::cwd()), 'reimplemented cwd matches standard cwd';
}
