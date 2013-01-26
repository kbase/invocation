
use Test::More;
use strict;
use Data::Dumper;
use Cwd 'abs_path';

my $url;
my $nonauth;
if (@ARGV)
{
    $url = shift;
    $nonauth = shift;
}

if (!$url)
{
    die "Usage: $0 url nonauth-dir\n";
}

use_ok('Bio::KBase::InvocationService::Client');

#
# Test unauthenticated.
#
my $session = "sess_test";

my $us = new_ok('Bio::KBase::InvocationService::Client', [$url]);

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
$us->put_file($session, "test.in", $f1, $cwd);
ok(-f "$nonauth/$session/test.in");

#
# Pull it back
#

is($f1, $us->get_file($session, "test.in", $cwd));

#
# Run a sort.
#
my $f2 = "a\nb\nc\nd\n";
my($out, $err) = $us->run_pipeline($session, "sort < test.in", [], 0, $cwd);
is(join("", @$out), $f2);

#
# Run a pipeline
#
my $f3 = "a\nb\n";
($out, $err) = $us->run_pipeline($session, "sort < test.in | head -n 2", [], 0, $cwd);
is(join("", @$out), $f3);

#
# Make a directory
#

my $dir = "new_dir";
$us->make_directory($session, $cwd, $dir);
ok(-d "$nonauth/$session/$dir");

#
# List files.
#

my($dirs, $files) = $us->list_files($session, $cwd, '');
print Dumper($dirs, $files);

#
# Change directory
#

my $newcwd = $us->change_directory($session, $cwd, $dir);
is($newcwd, "/$dir");

#
# Copy
#
$us->copy($session, $newcwd, "../test.in", "test.new");
ok(-f "$nonauth/$session/$dir/test.new");

#
# Remove file
#
$us->remove_files($session, $newcwd, "test.new");
ok(!-f "$nonauth/$session/$dir/test.new");

#
# Cd back up
#
my $newcwd2 = $us->change_directory($session, $newcwd, "..");
is($newcwd2, "/");

#
# Rename directory
#
my $dir2 = "dir.renamed";
$us->rename_file($session, $cwd, $dir, $dir2);
ok(! -d "$nonauth/$session/$dir");
ok(-d "$nonauth/$session/$dir2");

#
# Remove directory
#

$us->remove_directory($session, $cwd, $dir2);
ok(! -d "$nonauth/$session/$dir2");


#
# Rename file
#
$us->rename_file($session, $cwd, "test.in", "test.x");
ok(! -f "$nonauth/$session/test.in");
ok(-f "$nonauth/$session/test.x");

#
# Remove file
#
$us->remove_files($session,$cwd, "test.x");
ok(! -f "$nonauth/$session/test.x");

done_testing();

    
