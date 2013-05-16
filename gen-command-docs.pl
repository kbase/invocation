#
# generate the documentation for each command line script
# that was found by gen-valid-commands.pl
#

use strict;
#use Template;
use Data::Dumper;
use File::Basename;

use Bio::KBase::InvocationService::ValidCommands qw(command_groups);

# use Getopt if options get more complicated
my $top_dir = shift @ARGV;
$top_dir = $ENV{CWD} unless ($top_dir);

my $command_groups=command_groups();

foreach my $group (@$command_groups)
{
	my $target_dir = $top_dir . '/' . $group->{'name'};
	mkdir $target_dir;
	open INDEX, '>', "$target_dir/index.txt"
		or die "couldn't create $target_dir/index.txt: $!";
	print INDEX $group->{'title'};
	print INDEX "\n";

	foreach my $command (@{$group->{'items'}})
	{
		my $cmd = $command->{'cmd'};
		print INDEX "$cmd\n";
#		print qq{system($cmd, '-h' "1>$target_dir/$cmd.txt" "2>$target_dir/$cmd.err"); };
#		print "\n";
		system("$cmd -h > $target_dir/$cmd.txt");
	}
	close INDEX;
}

