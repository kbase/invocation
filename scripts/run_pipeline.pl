use strict;
use Data::Dumper;
use Getopt::Long;
use Carp;

#
# This is a SAS Component
#

=head1 run_pipeline

Example:

    run_pipeline [arguments] < input > output


This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Documentation for underlying call

This script is a wrapper for the CDMI-API call run_pipeline. It is documented as follows:



=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$pipeline is a string
$input is a reference to a list where each element is a string
$output is a reference to a list where each element is a string
$errors is a reference to a list where each element is a string

</pre>

=end html

=begin text

$session_id is a string
$pipeline is a string
$input is a reference to a list where each element is a string
$output is a reference to a list where each element is a string
$errors is a reference to a list where each element is a string


=end text

=back

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing the identifier is not the last column.

=item -i InputFile    [ use InputFile, rather than stdin ]

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with extra columns added.

Input lines that cannot be extended are written to stderr.

=cut

use SeedUtils;

my $usage = "usage: run_pipeline [-i input-file] [-u service-url] < input > output";

use Bio::KBase::InvocationService::Client;
use Bio::KBase::Utilities::ScriptThing;

my $column;

my $input_file;

my $service_url = 'http://bio-data-1.mcs.anl.gov/services/invocation';
my $rc = GetOptions('i=s' => \$input_file,
		    'url=s' => \$service_url);

$rc or die "$usage\n";

my $invoc = Bio::KBase::InvocationService::Client->new($service_url);
if (! $invoc) { print STDERR $usage; exit }

my $ih;
if ($input_file)
{
    open $ih, "<", $input_file or die "Cannot open input file $input_file: $!";
}
else
{
    $ih = \*STDIN;
}

my $session = $invoc->start_session('');

while (my $line = <$ih>)
{
    chomp $line;
    my($out, $errors) = $invoc->run_pipeline($session, $line, [], 0, '/');
    print "$_\n" foreach @$out;
    print STDERR "$_\n" foreach @$errors;
}
