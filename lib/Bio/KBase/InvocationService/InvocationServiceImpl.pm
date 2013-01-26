package Bio::KBase::InvocationService::InvocationServiceImpl;
use strict;
use Bio::KBase::Exceptions;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org 
our $VERSION = "0.1.0";

=head1 NAME

InvocationService

=head1 DESCRIPTION

The Invocation Service provides a mechanism by which KBase clients may
invoke command-line programs hosted on the KBase infrastructure. 

The service provides a simple directory structure for storage of intermediate
files, and exposes a limited set of shell command functionality.

=cut

#BEGIN_HEADER

use Bio::KBase::DeploymentConfig;
use Bio::KBase::InvocationService::UserSession;
use Bio::KBase::InvocationService::ValidCommands;

use base 'Class::Accessor';

__PACKAGE__->mk_accessors(qw(auth_storage_dir nonauth_storage_dir valid_commands_hash command_groups command_path));

#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR

    my($cfg) = @args;

    my $auth_storage = $cfg->setting('authenticated-storage');
    my $nonauth_storage = $cfg->setting('nonauthenticated-storage');

    $self->{auth_storage_dir} = $auth_storage;
    $self->{nonauth_storage_dir} = $nonauth_storage;
    $self->{counter} = 0;

    $self->{valid_commands_hash} = Bio::KBase::InvocationService::ValidCommands::valid_commands();
    $self->{command_groups} = Bio::KBase::InvocationService::ValidCommands::command_groups();

    my @command_path;

    my $kb_top = $ENV{KB_TOP};
    if ($kb_top)
    {
	$self->{command_path} = ["$kb_top/bin"];
    }
    else
    {
	die "Fatal error: no KB_TOP environment variable is set; this is required for the invocation service.";
    }
    
    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}

=head1 METHODS

=head2 start_session

  $actual_session_id = $obj->start_session($session_id)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$actual_session_id is a string

</pre>

=end html

=begin text

$session_id is a string
$actual_session_id is a string


=end text



=item Description

Begin a new session. A session_id is an uninterpreted string that
identifies a workspace with in the Invocation Service, and serves to
scope the data stored in that workspace.
If start_session is invoked with valid authentication (via the standard
KBase authentication mechanisms), the session_id is ignored, and an
empty session_id returned. Throughout this service interface, if
any call is made using authentication the given session_id will be ignored.

=back

=cut

sub start_session
{
    my $self = shift;
    my($session_id) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to start_session:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'start_session');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    my($actual_session_id);
    #BEGIN start_session

    my $us = Bio::KBase::InvocationService::UserSession->new($self, undef, $ctx);
    $actual_session_id = $us->start_session($session_id);
    
    #END start_session
    my @_bad_returns;
    (!ref($actual_session_id)) or push(@_bad_returns, "Invalid type for return variable \"actual_session_id\" (value was \"$actual_session_id\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to start_session:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'start_session');
    }
    return($actual_session_id);
}




=head2 valid_session

  $return = $obj->valid_session($session_id)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$return is an int

</pre>

=end html

=begin text

$session_id is a string
$return is an int


=end text



=item Description

Determine if the given session identifier is valid (has been used in the past).
This routine is a candidate for deprecation.

=back

=cut

sub valid_session
{
    my $self = shift;
    my($session_id) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to valid_session:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'valid_session');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    my($return);
    #BEGIN valid_session
    return $self->_validate_session($session_id);
    #END valid_session
    my @_bad_returns;
    (!ref($return)) or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to valid_session:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'valid_session');
    }
    return($return);
}




=head2 list_files

  $return_1, $return_2 = $obj->list_files($session_id, $cwd, $d)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$cwd is a string
$d is a string
$return_1 is a reference to a list where each element is a directory
$return_2 is a reference to a list where each element is a file
directory is a reference to a hash where the following keys are defined:
	name has a value which is a string
	full_path has a value which is a string
	mod_date has a value which is a string
file is a reference to a hash where the following keys are defined:
	name has a value which is a string
	full_path has a value which is a string
	mod_date has a value which is a string
	size has a value which is a string

</pre>

=end html

=begin text

$session_id is a string
$cwd is a string
$d is a string
$return_1 is a reference to a list where each element is a directory
$return_2 is a reference to a list where each element is a file
directory is a reference to a hash where the following keys are defined:
	name has a value which is a string
	full_path has a value which is a string
	mod_date has a value which is a string
file is a reference to a hash where the following keys are defined:
	name has a value which is a string
	full_path has a value which is a string
	mod_date has a value which is a string
	size has a value which is a string


=end text



=item Description

Enumerate the files in the session, assuming the current working
directory is cwd, and the filename to be listed is d. Think of this
as the equivalent of "cd $cwd; ls $d".

=back

=cut

sub list_files
{
    my $self = shift;
    my($session_id, $cwd, $d) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    (!ref($d)) or push(@_bad_arguments, "Invalid type for argument \"d\" (value was \"$d\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to list_files:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'list_files');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    my($return_1, $return_2);
    #BEGIN list_files

    my $us = Bio::KBase::InvocationService::UserSession->new($self, $session_id, $ctx);
    ($return_1, $return_2) = $us->list_files($cwd, $d);

    #END list_files
    my @_bad_returns;
    (ref($return_1) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"return_1\" (value was \"$return_1\")");
    (ref($return_2) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"return_2\" (value was \"$return_2\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to list_files:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'list_files');
    }
    return($return_1, $return_2);
}




=head2 remove_files

  $obj->remove_files($session_id, $cwd, $filename)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$cwd is a string
$filename is a string

</pre>

=end html

=begin text

$session_id is a string
$cwd is a string
$filename is a string


=end text



=item Description

Remove the given file from the given directory.

=back

=cut

sub remove_files
{
    my $self = shift;
    my($session_id, $cwd, $filename) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    (!ref($filename)) or push(@_bad_arguments, "Invalid type for argument \"filename\" (value was \"$filename\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to remove_files:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'remove_files');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    #BEGIN remove_files

    my $us = Bio::KBase::InvocationService::UserSession->new($self, $session_id, $ctx);
    $us->remove_files($cwd, $filename);

    #END remove_files
    return();
}




=head2 rename_file

  $obj->rename_file($session_id, $cwd, $from, $to)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$cwd is a string
$from is a string
$to is a string

</pre>

=end html

=begin text

$session_id is a string
$cwd is a string
$from is a string
$to is a string


=end text



=item Description

Rename the given file.

=back

=cut

sub rename_file
{
    my $self = shift;
    my($session_id, $cwd, $from, $to) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    (!ref($from)) or push(@_bad_arguments, "Invalid type for argument \"from\" (value was \"$from\")");
    (!ref($to)) or push(@_bad_arguments, "Invalid type for argument \"to\" (value was \"$to\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to rename_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'rename_file');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    #BEGIN rename_file

    my $us = Bio::KBase::InvocationService::UserSession->new($self, $session_id, $ctx);
    $us->rename_file($cwd, $from, $to);

    #END rename_file
    return();
}




=head2 copy

  $obj->copy($session_id, $cwd, $from, $to)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$cwd is a string
$from is a string
$to is a string

</pre>

=end html

=begin text

$session_id is a string
$cwd is a string
$from is a string
$to is a string


=end text



=item Description

Copy the given file to the given destination.

=back

=cut

sub copy
{
    my $self = shift;
    my($session_id, $cwd, $from, $to) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    (!ref($from)) or push(@_bad_arguments, "Invalid type for argument \"from\" (value was \"$from\")");
    (!ref($to)) or push(@_bad_arguments, "Invalid type for argument \"to\" (value was \"$to\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to copy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'copy');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    #BEGIN copy

    my $us = Bio::KBase::InvocationService::UserSession->new($self, $session_id, $ctx);
    $us->copy($cwd, $from, $to);
    #END copy
    return();
}




=head2 make_directory

  $obj->make_directory($session_id, $cwd, $directory)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$cwd is a string
$directory is a string

</pre>

=end html

=begin text

$session_id is a string
$cwd is a string
$directory is a string


=end text



=item Description

Create a new directory.

=back

=cut

sub make_directory
{
    my $self = shift;
    my($session_id, $cwd, $directory) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    (!ref($directory)) or push(@_bad_arguments, "Invalid type for argument \"directory\" (value was \"$directory\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to make_directory:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'make_directory');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    #BEGIN make_directory

    my $us = Bio::KBase::InvocationService::UserSession->new($self, $session_id, $ctx);
    $us->make_directory($cwd, $directory);

    #END make_directory
    return();
}




=head2 remove_directory

  $obj->remove_directory($session_id, $cwd, $directory)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$cwd is a string
$directory is a string

</pre>

=end html

=begin text

$session_id is a string
$cwd is a string
$directory is a string


=end text



=item Description

Remove a directory.

=back

=cut

sub remove_directory
{
    my $self = shift;
    my($session_id, $cwd, $directory) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    (!ref($directory)) or push(@_bad_arguments, "Invalid type for argument \"directory\" (value was \"$directory\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to remove_directory:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'remove_directory');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    #BEGIN remove_directory

    my $us = Bio::KBase::InvocationService::UserSession->new($self, $session_id, $ctx);
    $us->remove_directory($cwd, $directory);
    
    #END remove_directory
    return();
}




=head2 change_directory

  $return = $obj->change_directory($session_id, $cwd, $directory)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$cwd is a string
$directory is a string
$return is a string

</pre>

=end html

=begin text

$session_id is a string
$cwd is a string
$directory is a string
$return is a string


=end text



=item Description

Change to the given directory. Returns the new cwd.

=back

=cut

sub change_directory
{
    my $self = shift;
    my($session_id, $cwd, $directory) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    (!ref($directory)) or push(@_bad_arguments, "Invalid type for argument \"directory\" (value was \"$directory\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to change_directory:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'change_directory');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    my($return);
    #BEGIN change_directory

    my $us = Bio::KBase::InvocationService::UserSession->new($self, $session_id, $ctx);
    $return = $us->change_directory($cwd, $directory);
    
    #END change_directory
    my @_bad_returns;
    (!ref($return)) or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to change_directory:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'change_directory');
    }
    return($return);
}




=head2 put_file

  $obj->put_file($session_id, $filename, $contents, $cwd)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$filename is a string
$contents is a string
$cwd is a string

</pre>

=end html

=begin text

$session_id is a string
$filename is a string
$contents is a string
$cwd is a string


=end text



=item Description

Write contents to the given file.

=back

=cut

sub put_file
{
    my $self = shift;
    my($session_id, $filename, $contents, $cwd) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($filename)) or push(@_bad_arguments, "Invalid type for argument \"filename\" (value was \"$filename\")");
    (!ref($contents)) or push(@_bad_arguments, "Invalid type for argument \"contents\" (value was \"$contents\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to put_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'put_file');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    #BEGIN put_file

    my $us = Bio::KBase::InvocationService::UserSession->new($self, $session_id, $ctx);
    $us->put_file($filename, $contents, $cwd);
    #END put_file
    return();
}




=head2 get_file

  $contents = $obj->get_file($session_id, $filename, $cwd)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$filename is a string
$cwd is a string
$contents is a string

</pre>

=end html

=begin text

$session_id is a string
$filename is a string
$cwd is a string
$contents is a string


=end text



=item Description

Retrieve the contents of the given file.

=back

=cut

sub get_file
{
    my $self = shift;
    my($session_id, $filename, $cwd) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($filename)) or push(@_bad_arguments, "Invalid type for argument \"filename\" (value was \"$filename\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to get_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_file');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    my($contents);
    #BEGIN get_file

    my $us = Bio::KBase::InvocationService::UserSession->new($self, $session_id, $ctx);
    $contents = $us->get_file($filename, $cwd);
    #END get_file
    my @_bad_returns;
    (!ref($contents)) or push(@_bad_returns, "Invalid type for return variable \"contents\" (value was \"$contents\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to get_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_file');
    }
    return($contents);
}




=head2 run_pipeline

  $output, $errors = $obj->run_pipeline($session_id, $pipeline, $input, $max_output_size, $cwd)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$pipeline is a string
$input is a reference to a list where each element is a string
$max_output_size is an int
$cwd is a string
$output is a reference to a list where each element is a string
$errors is a reference to a list where each element is a string

</pre>

=end html

=begin text

$session_id is a string
$pipeline is a string
$input is a reference to a list where each element is a string
$max_output_size is an int
$cwd is a string
$output is a reference to a list where each element is a string
$errors is a reference to a list where each element is a string


=end text



=item Description

Run the given command pipeline. Returns the stdout and stderr for the pipeline.
If max_output_size is greater than zero, limits the output of the command
to max_output_size lines.

=back

=cut

sub run_pipeline
{
    my $self = shift;
    my($session_id, $pipeline, $input, $max_output_size, $cwd) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($pipeline)) or push(@_bad_arguments, "Invalid type for argument \"pipeline\" (value was \"$pipeline\")");
    (ref($input) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"input\" (value was \"$input\")");
    (!ref($max_output_size)) or push(@_bad_arguments, "Invalid type for argument \"max_output_size\" (value was \"$max_output_size\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to run_pipeline:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'run_pipeline');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    my($output, $errors);
    #BEGIN run_pipeline

    my $us = Bio::KBase::InvocationService::UserSession->new($self, $session_id, $ctx);
    ($output, $errors) = $us->run_pipeline($pipeline, $input, $max_output_size, $cwd);
    
    #END run_pipeline
    my @_bad_returns;
    (ref($output) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    (ref($errors) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"errors\" (value was \"$errors\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to run_pipeline:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'run_pipeline');
    }
    return($output, $errors);
}




=head2 run_pipeline2

  $output, $errors, $stdweb = $obj->run_pipeline2($session_id, $pipeline, $input, $max_output_size, $cwd)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$pipeline is a string
$input is a reference to a list where each element is a string
$max_output_size is an int
$cwd is a string
$output is a reference to a list where each element is a string
$errors is a reference to a list where each element is a string
$stdweb is a string

</pre>

=end html

=begin text

$session_id is a string
$pipeline is a string
$input is a reference to a list where each element is a string
$max_output_size is an int
$cwd is a string
$output is a reference to a list where each element is a string
$errors is a reference to a list where each element is a string
$stdweb is a string


=end text



=item Description

Experimental routine.

=back

=cut

sub run_pipeline2
{
    my $self = shift;
    my($session_id, $pipeline, $input, $max_output_size, $cwd) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($pipeline)) or push(@_bad_arguments, "Invalid type for argument \"pipeline\" (value was \"$pipeline\")");
    (ref($input) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"input\" (value was \"$input\")");
    (!ref($max_output_size)) or push(@_bad_arguments, "Invalid type for argument \"max_output_size\" (value was \"$max_output_size\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to run_pipeline2:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'run_pipeline2');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    my($output, $errors, $stdweb);
    #BEGIN run_pipeline2

    my $us = Bio::KBase::InvocationService::UserSession->new($self, $session_id, $ctx);
    ($output, $errors, $stdweb) = $us->run_pipeline2($pipeline, $input, $max_output_size, $cwd);
    
    #END run_pipeline2
    my @_bad_returns;
    (ref($output) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    (ref($errors) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"errors\" (value was \"$errors\")");
    (!ref($stdweb)) or push(@_bad_returns, "Invalid type for return variable \"stdweb\" (value was \"$stdweb\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to run_pipeline2:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'run_pipeline2');
    }
    return($output, $errors, $stdweb);
}

=head2 exit_session

  $obj->exit_session($session_id)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string

</pre>

=end html

=begin text

$session_id is a string


=end text



=item Description

Exit the session.

=back

=cut

sub exit_session
{
    my $self = shift;
    my($session_id) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to exit_session:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'exit_session');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    #BEGIN exit_session
    #END exit_session
    return();
}

=head2 valid_commands

  $return = $obj->valid_commands()

=over 4

=item Parameter and return types

=begin html

<pre>
$return is a reference to a list where each element is a command_group_desc
command_group_desc is a reference to a hash where the following keys are defined:
	name has a value which is a string
	title has a value which is a string
	items has a value which is a reference to a list where each element is a command_desc
command_desc is a reference to a hash where the following keys are defined:
	cmd has a value which is a string
	link has a value which is a string

</pre>

=end html

=begin text

$return is a reference to a list where each element is a command_group_desc
command_group_desc is a reference to a hash where the following keys are defined:
	name has a value which is a string
	title has a value which is a string
	items has a value which is a reference to a list where each element is a command_desc
command_desc is a reference to a hash where the following keys are defined:
	cmd has a value which is a string
	link has a value which is a string


=end text



=item Description

Retrieve the set of valid commands.

=back

=cut

sub valid_commands
{
    my $self = shift;

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    my($return);
    #BEGIN valid_commands
    return $self->{command_groups};
    #END valid_commands
    my @_bad_returns;
    (ref($return) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to valid_commands:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'valid_commands');
    }
    return($return);
}




=head2 get_tutorial_text

  $text, $prev, $next = $obj->get_tutorial_text($step)

=over 4

=item Parameter and return types

=begin html

<pre>
$step is an int
$text is a string
$prev is an int
$next is an int

</pre>

=end html

=begin text

$step is an int
$text is a string
$prev is an int
$next is an int


=end text



=item Description

Retrieve the tutorial text for the given tutorial step, along with the
the step numbers for the previous and next steps in the tutorial.

=back

=cut

sub get_tutorial_text
{
    my $self = shift;
    my($step) = @_;

    my @_bad_arguments;
    (!ref($step)) or push(@_bad_arguments, "Invalid type for argument \"step\" (value was \"$step\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to get_tutorial_text:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_tutorial_text');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    my($text, $prev, $next);
    #BEGIN get_tutorial_text

    my $gpath = sub { sprintf "/home/olson/public_html/kbt/t%d.html", $_[0]; };

    my $path = &$gpath($step);
    if (! -f $path)
    {
	$step = 1;
	$path = &$gpath($step);
    }

    if (open(my $fh, "<", $path))
    {
	local $/;
	undef $/;
	$text = <$fh>;

	$prev = $step - 1;
	$next = $step + 1;
	if (! -f &$gpath($prev))
	{
	    $prev = -1;
	}
	if (! -f &$gpath($next))
	{
	    $next = -1;
	}
	close($fh);
    }
    #END get_tutorial_text
    my @_bad_returns;
    (!ref($text)) or push(@_bad_returns, "Invalid type for return variable \"text\" (value was \"$text\")");
    (!ref($prev)) or push(@_bad_returns, "Invalid type for return variable \"prev\" (value was \"$prev\")");
    (!ref($next)) or push(@_bad_returns, "Invalid type for return variable \"next\" (value was \"$next\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to get_tutorial_text:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_tutorial_text');
    }
    return($text, $prev, $next);
}




=head2 version 

  $return = $obj->version()

=over 4

=item Parameter and return types

=begin html

<pre>
$return is a string
</pre>

=end html

=begin text

$return is a string

=end text

=item Description

Return the module version. This is a Semantic Versioning number.

=back

=cut

sub version {
    return $VERSION;
}

=head1 TYPES



=head2 directory

=over 4



=item Description

* A directory entry. Used as the return from list_files.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
name has a value which is a string
full_path has a value which is a string
mod_date has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
name has a value which is a string
full_path has a value which is a string
mod_date has a value which is a string


=end text

=back



=head2 file

=over 4



=item Description

* A file entry. Used as the return from list_files.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
name has a value which is a string
full_path has a value which is a string
mod_date has a value which is a string
size has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
name has a value which is a string
full_path has a value which is a string
mod_date has a value which is a string
size has a value which is a string


=end text

=back



=head2 command_desc

=over 4



=item Description

* Description of a command. Contains the command name and a link to documentation.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
cmd has a value which is a string
link has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
cmd has a value which is a string
link has a value which is a string


=end text

=back



=head2 command_group_desc

=over 4



=item Description

* Description of a command group, a set of common commands.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
name has a value which is a string
title has a value which is a string
items has a value which is a reference to a list where each element is a command_desc

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
name has a value which is a string
title has a value which is a string
items has a value which is a reference to a list where each element is a command_desc


=end text

=back



=cut

1;
