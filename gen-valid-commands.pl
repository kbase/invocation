#
# generate the valid-commands block that goes into the
# InvocationService implementation.
#

use strict;
use Template;
use Data::Dumper;
use File::Basename;

my @groups;

#
# We assume we are running from a directory in the modules directory
# of a KBase dev container. 
#
# Use the module-order script that is part of the dev_container
# to retrieve the list of modules in topological order; we reverse
# that order to get the "most general" modules first.
#
# If that fails for some reason, revert to the list of directories that
# contain a Makefile.
#

my @modules;

if (open(P, "-|", "../../tools/module-order", ".."))
{
    while (<P>)
    {
	chomp;
	unshift(@modules, $_);
    }
    close(P);
}
else
{
    opendir(D, "..") or die "Cannot opendir ..: $!";
    while (my $d = readdir(D))
    {
	if (-f "../$d/Makefile")
	{
	    push(@modules, $d);
	}
    }
    closedir(D);
}

my @groups;
my %groups;
my %group_names;
my %groups_seen;
my @modules_with_commands;

for my $module (@modules)
{
    my $cmd_file = "../$module/COMMANDS";
    if (! -f $cmd_file)
    {
	$cmd_file = "module_commands/$module";
    }
    next unless -f $cmd_file;
    print STDERR "Process $cmd_file\n";
    my $has_command = process_cmd_file(\%groups_seen, \@groups, \%groups, \%group_names, $module, $cmd_file);
    push(@modules_with_commands, $module) if $has_command;
}

my @group_ents;
for my $gkey (@groups)
{
    my $list = $groups{$gkey};
    if (!ref($list) || @$list == 0)
    {
	warn "No items found for $gkey\n";
	next;
    }
    my @items = map { { cmd => $_, link => '' } } sort { $a cmp $b } @{$groups{$gkey}};
    my $group = {
	title => ($group_names{$gkey} or $gkey),
	name => $gkey,
	items => \@items,
    };
    push(@group_ents, $group);
}

my %data = (
	    groups => \@group_ents,
	    modules => \@modules_with_commands,
	   );
#print Dumper(\%data);
my $tmpl = Template->new();
$tmpl->process("ValidCommands.pm.tt", \%data) || die "Error processing template: " . $tmpl->error;


sub process_cmd_file
{
    my($groups_seen, $group_list, $groups, $group_names, $module, $cmd_file) = @_;

    open(F, "<", $cmd_file) or die "Cannot open $cmd_file: $!";

    my @list;
    my $have_re;
    my $dir = "../$module";
    my @ignore;

    while (<F>)
    {
	chomp;
	s/\s*$//;
	s/^\s*//;
	
	my($cmd, $rest) = /^(\S+)\s+(.*)/;

	if ($cmd eq '#group-name')
	{
	    my($group, $name) = $rest =~ /^(\S+)\s+(.*)$/;
	    print STDERR "group'$group' name='$name'\n";
	    if (!$group || !$name)
	    {
		die "Invalid #group-name line at line $.";
	    }
	    push(@$group_list, $group) if (!$groups_seen->{$group});
	    $groups_seen->{$group} = 1;
	    $group_names{$group} = $name;
	}
	elsif ($cmd eq '#command-set')
	{
	    my($reg, $group) = $rest =~ /^(.*?)\s+(\S+)$/;
	    print STDERR "CMDSET reg='$reg' group='$group'\n";
	    if (!$reg || !$group)
	    {
		die "Invalid #command-set line at line $.";
	    }
	    my $re = qr/^$reg/;
	    push(@$group_list, $group) if (!$groups_seen->{$group});
	    $groups_seen->{$group} = 1;
	    push(@list, ['regexp', $re, $group]);
	    $have_re++;
	}
	elsif ($cmd eq '#ignore')
	{
	    my $reg = $rest;
	    my $re = qr/^$reg/;
	    push(@ignore, $re);
	    $have_re++;
	}
	elsif ($rest =~ /^\S+$/)
	{
	    my $group = $rest;
	    push(@$group_list, $group) if (!$groups_seen->{$group});
	    $groups_seen->{$group} = 1;
	    push(@list, ['explicit', $cmd, $group]);
	}
	else
	{
	    die "Unknown commands line at line $.";
	}
    }
    close(F);

    #
    # If there are regexp expressions, generate a file listing.
    #
    my @files;
    if ($have_re)
    {
	open(FIND, "-|", "find", $dir, "-type", "f") or die "cannot open find: $!";
	@files = <FIND>;
	chomp @files;
	@files = grep { ! m,^\./\.git/, } @files;
	my $qdir = quotemeta($dir);
	s,^$qdir/,, foreach @files;
    }

    my %ignore_file;
    #
    # Find list of files to ignore.
    #
    for my $re (@ignore)
    {
	$ignore_file{$_} = 1 foreach  grep { $_ =~ $re } @files;
    }

    my %file_group;

    for my $ent (@list)
    {
	my($what, $val, $group) = @$ent;
	if ($what eq 'explicit')
	{
	    $file_group{$val} = $group;
	}
	elsif ($what eq 'regexp')
	{
	    for my $file (@files)
	    {
		next if $ignore_file{$file};
		if (my($base) = $file =~ $val)
		{
		    $file_group{$base} = $group;
		}
	    }
	}
    }

    for my $file (keys %file_group)
    {
	my $group = $file_group{$file};
	push(@{$groups->{$group}}, $file);
    }

    return %file_group ? 1 : 0;
}
