
use Test::More tests => 26;
use strict;
use Data::Dumper;
use Cwd 'abs_path';
use lib 'lib';
use Bio::KBase::InvocationService::UserSession;

my $work = abs_path("workdir");
-d $work || mkdir $work;
ok(-d $work);
ok(chdir $work);

my $bin = "$work/bin";
-d $bin || mkdir $bin;
ok(-d $bin);

my $auth = "$work/auth";
system("rm", "-r", $auth);
mkdir($auth);
ok(-d $auth);

my $nonauth = "$work/nonauth";
system("rm", "-r", $nonauth);
mkdir $nonauth;
ok(-d $nonauth);

use_ok('Bio::KBase::InvocationService::UserSession');

my $impl = new_ok('TestImpl', [$auth, $nonauth, $bin]);

#
# Test unauthenticated.
#
my $session = "sess_test";


my $ctx = new_ok('Ctx', [ authenticated => 0 ]);
my $us = new_ok('Bio::KBase::InvocationService::UserSession', [$impl, $session, $ctx]);

#
# Start session and see if we got a session directory.
#

my $s = $us->start_session($session);
is($s, "sess_test");
ok(-d "$nonauth/$session");

#
# Push a file.
#

my $cwd = "/";
my $f1 = "d\nc\nb\na\n";
$us->put_file("test.in", $f1, $cwd);
ok(-f "$nonauth/$session/test.in");

#
# Pull it back
#

is($f1, $us->get_file("test.in", $cwd));

#
# Run a sort.
#
my $f2 = "a\nb\nc\nd\n";
my($out, $err) = $us->run_pipeline("sort < test.in", [], 0, $cwd);
is(join("", @$out), $f2);

#
# Run a pipeline
#
my $f3 = "a\nb\n";
($out, $err) = $us->run_pipeline("sort < test.in | head -n 2", [], 0, $cwd);
is(join("", @$out), $f3);

#
# Make a directory
#

my $dir = "new_dir";
$us->make_directory($cwd, $dir);
ok(-d "$nonauth/$session/$dir");

#
# List files.
#
my($dirs, $files) = $us->list_files($cwd, '');

print Dumper($dirs, $files);


#
# Change directory
#
my $newcwd = $us->change_directory($cwd, $dir);
print STDERR "\n";print "\n";
is($newcwd, "/$dir");

#
# Copy
#

$us->copy($newcwd, "../test.in", "test.new");
ok(-f "$nonauth/$session/$dir/test.new");

#
# Remove file
#
$us->remove_files($newcwd, "test.new");
ok(!-f "$nonauth/$session/$dir/test.new");

#
# Cd back up
#
my $newcwd2 = $us->change_directory($newcwd, "..");
print STDERR "\n";print "\n";
is($newcwd2, "/");

#
# Rename directory
#
my $dir2 = "dir.renamed";
$us->rename_file($cwd, $dir, $dir2);
ok(! -d "$nonauth/$session/$dir");
ok(-d "$nonauth/$session/$dir2");

#
# Remove directory
#

$us->remove_directory($cwd, $dir2);
ok(! -d "$nonauth/$session/$dir2");


#
# Rename file
#
$us->rename_file($cwd, "test.in", "test.x");
ok(! -f "$nonauth/$session/test.in");
ok(-f "$nonauth/$session/test.x");

#
# Remove file
#
$us->remove_files($cwd, "test.x");
ok(! -f "$nonauth/$session/test.x");


system("rm", "-r", $work);

done_testing();

#
# This is a little class that speaks enough of the Impl protocol
# for the UserSession class to operate for testing.
#
package TestImpl;

use strict;
use base 'Class::Accessor';

BEGIN {
    __PACKAGE__->mk_accessors(qw(auth_storage_dir nonauth_storage_dir valid_commands_hash command_path verbose_status));
}

sub new
{
    my($class, $d1, $d2, $path) = @_;
    my $self = {
	auth_storage_dir => $d1,
	nonauth_storage_dir => $d2,
	valid_commands_hash => {'cmd1', => 1, 'cmd2' => 1},
	command_path => [$path],
    };
    return bless $self, $class;
}

package Ctx;

use strict;
use base 'Class::Accessor';

BEGIN {
    __PACKAGE__->mk_accessors(qw(authenticated user_id token));
}

sub new
{
    my($class, %args) = @_;
    my $self = { %args };
    return bless $self, $class;
}

