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

my @cmd_files = <../*/COMMANDS>;

my %groups;
my %group_names;

for my $cmd_file (@cmd_files)
{
    print STDERR "Process $cmd_file\n";
    process_cmd_file(\%groups, \%group_names, $cmd_file);
}

my @gkeys = sort { $group_names{$a} cmp $group_names{$b} or $a cmp $b } keys %groups;

my @groups;
for my $gkey (@gkeys)
{
    my @items = map { { cmd => $_, link => '' } } sort { $a cmp $b } @{$groups{$gkey}};
    my $group = {
	title => ($group_names{$gkey} or $gkey),
	name => $gkey,
	items => \@items,
    };
    push(@groups, $group);
}

my %data = ( groups => \@groups );
#print Dumper(\%data);
my $tmpl = Template->new();
$tmpl->process("ValidCommands.pm.tt", \%data);


sub process_cmd_file
{
    my($groups, $group_names, $cmd_file) = @_;

    open(F, "<", $cmd_file) or die "Cannot open $cmd_file: $!";

    my @list;
    my $have_re;
    my $dir = dirname($cmd_file);

    while (<F>)
    {
	chomp;
	my @fields = split(/\t/);

	if ($fields[0] eq '#group-name')
	{
	    if (@fields != 3)
	    {
		die "Invalid #group-name line at line $.";
	    }
	    $group_names{$fields[1]} = $fields[2];
	}
	elsif ($fields[0] eq '#command-set')
	{
	    if (@fields != 3)
	    {
		die "Invalid #command-set line at line $.";
	    }
	    my $reg = $fields[1];
	    my $re = qr/^$reg/;
	    my $group = $fields[2];
	    push(@list, ['regexp', $re, $group]);
	    $have_re++;
	}
	elsif (@fields == 2)
	{
	    push(@list, ['explicit', $fields[0], $fields[1]]);
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
}
