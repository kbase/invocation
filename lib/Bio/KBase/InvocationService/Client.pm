package Bio::KBase::InvocationService::Client;

use JSON::RPC::Client;
use strict;
use Data::Dumper;
use URI;
use Bio::KBase::Exceptions;
use Bio::KBase::AuthToken;

# Client version should match Impl version
# This is a Semantic Version number,
# http://semver.org
our $VERSION = "0.1.0";

=head1 NAME

Bio::KBase::InvocationService::Client

=head1 DESCRIPTION


The Invocation Service provides a mechanism by which KBase clients may
invoke command-line programs hosted on the KBase infrastructure. 

The service provides a simple directory structure for storage of intermediate
files, and exposes a limited set of shell command functionality.


=cut

sub new
{
    my($class, $url, @args) = @_;

    my $self = {
	client => Bio::KBase::InvocationService::Client::RpcClient->new,
	url => $url,
    };

    # This module requires authentication.
    #
    # We create an auth token, passing through the arguments that we were (hopefully) given.

    {
	my $token = Bio::KBase::AuthToken->new(@args);
	
	if ($token->error_message)
	{
	    die "Authentication failed: " . $token->error_message;
	}
	$self->{token} = $token->token;
	$self->{client}->{token} = $token->token;
    }

    my $ua = $self->{client}->ua;	 
    my $timeout = $ENV{CDMI_TIMEOUT} || (30 * 60);	 
    $ua->timeout($timeout);
    bless $self, $class;
    #    $self->_validate_version();
    return $self;
}




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
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function start_session (received $n, expecting 1)");
    }
    {
	my($session_id) = @args;

	my @_bad_arguments;
        (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"session_id\" (value was \"$session_id\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to start_session:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'start_session');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.start_session",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'start_session',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method start_session",
					    status_line => $self->{client}->status_line,
					    method_name => 'start_session',
				       );
    }
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
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function list_files (received $n, expecting 3)");
    }
    {
	my($session_id, $cwd, $d) = @args;

	my @_bad_arguments;
        (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"session_id\" (value was \"$session_id\")");
        (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument 2 \"cwd\" (value was \"$cwd\")");
        (!ref($d)) or push(@_bad_arguments, "Invalid type for argument 3 \"d\" (value was \"$d\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to list_files:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'list_files');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.list_files",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'list_files',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method list_files",
					    status_line => $self->{client}->status_line,
					    method_name => 'list_files',
				       );
    }
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
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function remove_files (received $n, expecting 3)");
    }
    {
	my($session_id, $cwd, $filename) = @args;

	my @_bad_arguments;
        (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"session_id\" (value was \"$session_id\")");
        (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument 2 \"cwd\" (value was \"$cwd\")");
        (!ref($filename)) or push(@_bad_arguments, "Invalid type for argument 3 \"filename\" (value was \"$filename\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to remove_files:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'remove_files');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.remove_files",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'remove_files',
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method remove_files",
					    status_line => $self->{client}->status_line,
					    method_name => 'remove_files',
				       );
    }
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
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function rename_file (received $n, expecting 4)");
    }
    {
	my($session_id, $cwd, $from, $to) = @args;

	my @_bad_arguments;
        (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"session_id\" (value was \"$session_id\")");
        (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument 2 \"cwd\" (value was \"$cwd\")");
        (!ref($from)) or push(@_bad_arguments, "Invalid type for argument 3 \"from\" (value was \"$from\")");
        (!ref($to)) or push(@_bad_arguments, "Invalid type for argument 4 \"to\" (value was \"$to\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to rename_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'rename_file');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.rename_file",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'rename_file',
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method rename_file",
					    status_line => $self->{client}->status_line,
					    method_name => 'rename_file',
				       );
    }
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
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function copy (received $n, expecting 4)");
    }
    {
	my($session_id, $cwd, $from, $to) = @args;

	my @_bad_arguments;
        (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"session_id\" (value was \"$session_id\")");
        (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument 2 \"cwd\" (value was \"$cwd\")");
        (!ref($from)) or push(@_bad_arguments, "Invalid type for argument 3 \"from\" (value was \"$from\")");
        (!ref($to)) or push(@_bad_arguments, "Invalid type for argument 4 \"to\" (value was \"$to\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to copy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'copy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.copy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'copy',
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method copy",
					    status_line => $self->{client}->status_line,
					    method_name => 'copy',
				       );
    }
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
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function make_directory (received $n, expecting 3)");
    }
    {
	my($session_id, $cwd, $directory) = @args;

	my @_bad_arguments;
        (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"session_id\" (value was \"$session_id\")");
        (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument 2 \"cwd\" (value was \"$cwd\")");
        (!ref($directory)) or push(@_bad_arguments, "Invalid type for argument 3 \"directory\" (value was \"$directory\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to make_directory:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'make_directory');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.make_directory",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'make_directory',
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method make_directory",
					    status_line => $self->{client}->status_line,
					    method_name => 'make_directory',
				       );
    }
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
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function remove_directory (received $n, expecting 3)");
    }
    {
	my($session_id, $cwd, $directory) = @args;

	my @_bad_arguments;
        (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"session_id\" (value was \"$session_id\")");
        (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument 2 \"cwd\" (value was \"$cwd\")");
        (!ref($directory)) or push(@_bad_arguments, "Invalid type for argument 3 \"directory\" (value was \"$directory\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to remove_directory:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'remove_directory');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.remove_directory",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'remove_directory',
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method remove_directory",
					    status_line => $self->{client}->status_line,
					    method_name => 'remove_directory',
				       );
    }
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
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function change_directory (received $n, expecting 3)");
    }
    {
	my($session_id, $cwd, $directory) = @args;

	my @_bad_arguments;
        (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"session_id\" (value was \"$session_id\")");
        (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument 2 \"cwd\" (value was \"$cwd\")");
        (!ref($directory)) or push(@_bad_arguments, "Invalid type for argument 3 \"directory\" (value was \"$directory\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to change_directory:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'change_directory');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.change_directory",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'change_directory',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method change_directory",
					    status_line => $self->{client}->status_line,
					    method_name => 'change_directory',
				       );
    }
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
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function put_file (received $n, expecting 4)");
    }
    {
	my($session_id, $filename, $contents, $cwd) = @args;

	my @_bad_arguments;
        (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"session_id\" (value was \"$session_id\")");
        (!ref($filename)) or push(@_bad_arguments, "Invalid type for argument 2 \"filename\" (value was \"$filename\")");
        (!ref($contents)) or push(@_bad_arguments, "Invalid type for argument 3 \"contents\" (value was \"$contents\")");
        (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument 4 \"cwd\" (value was \"$cwd\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to put_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'put_file');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.put_file",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'put_file',
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method put_file",
					    status_line => $self->{client}->status_line,
					    method_name => 'put_file',
				       );
    }
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
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_file (received $n, expecting 3)");
    }
    {
	my($session_id, $filename, $cwd) = @args;

	my @_bad_arguments;
        (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"session_id\" (value was \"$session_id\")");
        (!ref($filename)) or push(@_bad_arguments, "Invalid type for argument 2 \"filename\" (value was \"$filename\")");
        (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument 3 \"cwd\" (value was \"$cwd\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_file');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.get_file",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_file',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_file",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_file',
				       );
    }
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
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 5)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function run_pipeline (received $n, expecting 5)");
    }
    {
	my($session_id, $pipeline, $input, $max_output_size, $cwd) = @args;

	my @_bad_arguments;
        (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"session_id\" (value was \"$session_id\")");
        (!ref($pipeline)) or push(@_bad_arguments, "Invalid type for argument 2 \"pipeline\" (value was \"$pipeline\")");
        (ref($input) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"input\" (value was \"$input\")");
        (!ref($max_output_size)) or push(@_bad_arguments, "Invalid type for argument 4 \"max_output_size\" (value was \"$max_output_size\")");
        (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument 5 \"cwd\" (value was \"$cwd\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to run_pipeline:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'run_pipeline');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.run_pipeline",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'run_pipeline',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method run_pipeline",
					    status_line => $self->{client}->status_line,
					    method_name => 'run_pipeline',
				       );
    }
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
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 5)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function run_pipeline2 (received $n, expecting 5)");
    }
    {
	my($session_id, $pipeline, $input, $max_output_size, $cwd) = @args;

	my @_bad_arguments;
        (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"session_id\" (value was \"$session_id\")");
        (!ref($pipeline)) or push(@_bad_arguments, "Invalid type for argument 2 \"pipeline\" (value was \"$pipeline\")");
        (ref($input) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"input\" (value was \"$input\")");
        (!ref($max_output_size)) or push(@_bad_arguments, "Invalid type for argument 4 \"max_output_size\" (value was \"$max_output_size\")");
        (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument 5 \"cwd\" (value was \"$cwd\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to run_pipeline2:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'run_pipeline2');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.run_pipeline2",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'run_pipeline2',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method run_pipeline2",
					    status_line => $self->{client}->status_line,
					    method_name => 'run_pipeline2',
				       );
    }
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
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function exit_session (received $n, expecting 1)");
    }
    {
	my($session_id) = @args;

	my @_bad_arguments;
        (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"session_id\" (value was \"$session_id\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to exit_session:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'exit_session');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.exit_session",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'exit_session',
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method exit_session",
					    status_line => $self->{client}->status_line,
					    method_name => 'exit_session',
				       );
    }
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
Note that this does not require authentication or a valid session, and thus
may be used to set up a graphical interface before a login is done.

=back

=cut

sub valid_commands
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 0)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function valid_commands (received $n, expecting 0)");
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.valid_commands",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'valid_commands',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method valid_commands",
					    status_line => $self->{client}->status_line,
					    method_name => 'valid_commands',
				       );
    }
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
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_tutorial_text (received $n, expecting 1)");
    }
    {
	my($step) = @args;

	my @_bad_arguments;
        (!ref($step)) or push(@_bad_arguments, "Invalid type for argument 1 \"step\" (value was \"$step\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_tutorial_text:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_tutorial_text');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.get_tutorial_text",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_tutorial_text',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_tutorial_text",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_tutorial_text',
				       );
    }
}



sub version {
    my ($self) = @_;
    my $result = $self->{client}->call($self->{url}, {
        method => "InvocationService.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'get_tutorial_text',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method get_tutorial_text",
            status_line => $self->{client}->status_line,
            method_name => 'get_tutorial_text',
        );
    }
}

sub _validate_version {
    my ($self) = @_;
    my $svr_version = $self->version();
    my $client_version = $VERSION;
    my ($cMajor, $cMinor) = split(/\./, $client_version);
    my ($sMajor, $sMinor) = split(/\./, $svr_version);
    if ($sMajor != $cMajor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Major version numbers differ.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor < $cMinor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Client minor version greater than Server minor version.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor > $cMinor) {
        warn "New client version available for Bio::KBase::InvocationService::Client\n";
    }
    if ($sMajor == 0) {
        warn "Bio::KBase::InvocationService::Client version is $svr_version. API subject to change.\n";
    }
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

package Bio::KBase::InvocationService::Client::RpcClient;
use base 'JSON::RPC::Client';

#
# Override JSON::RPC::Client::call because it doesn't handle error returns properly.
#

sub call {
    my ($self, $uri, $obj) = @_;
    my $result;

    if ($uri =~ /\?/) {
       $result = $self->_get($uri);
    }
    else {
        Carp::croak "not hashref." unless (ref $obj eq 'HASH');
        $result = $self->_post($uri, $obj);
    }

    my $service = $obj->{method} =~ /^system\./ if ( $obj );

    $self->status_line($result->status_line);

    if ($result->is_success) {

        return unless($result->content); # notification?

        if ($service) {
            return JSON::RPC::ServiceObject->new($result, $self->json);
        }

        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    elsif ($result->content_type eq 'application/json')
    {
        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    else {
        return;
    }
}


sub _post {
    my ($self, $uri, $obj) = @_;
    my $json = $self->json;

    $obj->{version} ||= $self->{version} || '1.1';

    if ($obj->{version} eq '1.0') {
        delete $obj->{version};
        if (exists $obj->{id}) {
            $self->id($obj->{id}) if ($obj->{id}); # if undef, it is notification.
        }
        else {
            $obj->{id} = $self->id || ($self->id('JSON::RPC::Client'));
        }
    }
    else {
        $obj->{id} = $self->id if (defined $self->id);
    }

    my $content = $json->encode($obj);

    $self->ua->post(
        $uri,
        Content_Type   => $self->{content_type},
        Content        => $content,
        Accept         => 'application/json',
	($self->{token} ? (Authorization => $self->{token}) : ()),
    );
}



1;
