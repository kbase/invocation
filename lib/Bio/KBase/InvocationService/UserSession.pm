package Bio::KBase::InvocationService::UserSession;

=head1 NAME

Bio::KBase::InvocationService::UserSession

=head1 DESCRIPTION

The UserSession object wraps up the code for performing authentication
and file system access verification for a given user's request to the
invocation service. Instances of this class only exist for the duration of
a single call to the invocation service. Doing this allows us to
remove the chaining of session ids and authentication contexts through
various calls.

=cut

use strict;
use base 'Class::Accessor';

use IPC::Run;
use Data::Dumper;
use Digest::MD5 'md5_hex';    
use Bio::KBase::InvocationService::PipelineGrammar;
use POSIX qw(strftime);
use Cwd;
use Cwd 'abs_path';
use File::Spec;
use File::Slurp;
use File::Path;
use File::Basename;
use File::Copy;

my @valid_shell_commands = qw(sort grep cut cat head tail date echo wc diff join uniq);
my %valid_shell_commands = map { $_ => 1 } @valid_shell_commands;

__PACKAGE__->mk_accessors(qw(impl session_id ctx));

sub new
{
    my($class, $impl, $session_id, $ctx) = @_;

    my $self = {
	impl => $impl,
	session_id => $session_id,
	ctx => $ctx,
    };
    return bless $self, $class;
}

sub validate_path
{
    my($self, $cwd) = @_;
    my $base = $self->_session_dir();
    my $dir = $base.$cwd;
    my $ap = abs_path($dir);
    if ($ap =~ /^$base/ || $ap eq '/dev/null') {
        return $ap;
    } else {
        die "Invalid path $ap (base=$base dir=$dir cwd=$cwd)";
    }
}

sub _prepend_cwd
{
    my($cwd, $path) = @_;
    if ($path =~ m,^/,)
    {
	return $path;
    }
    else
    {
	return $cwd . "/" . $ path;
    }
}
     

sub _valid_session_name
{
    my($self, $session) = @_;

    return $session =~ /^[a-zA-Z0-9._-]+$/;
}

sub _session_dir
{
    my($self) = @_;

    my $dir;
    if ($self->ctx && $self->ctx->authenticated)
    {
	$dir = File::Spec->catfile($self->impl->auth_storage_dir, $self->ctx->user_id);
	print STDERR "Construct dir from storage=" . $self->impl->auth_storage_dir . " userid=" . $self->ctx->user_id . "\n";

	#
	# If we come in here and somehow the directory isn't yet created, go ahead and create it.
	#
	if (! -d $dir)
	{
	    mkdir($dir) or die "Error setting up session directory $dir: $!";
	}
    }
    else
    {
	print STDERR "Construct dir from nonauth storage=" . $self->impl->nonauth_storage_dir . " sessionid=" . $self->session_id . "\n";
	$dir = File::Spec->catfile($self->impl->nonauth_storage_dir, $self->session_id);
	#
	# If we come in here and somehow the directory isn't yet created, go ahead and create it.
	#
	if (! -d $dir)
	{
	    mkdir($dir) or die "Error setting up session directory $dir: $!";
	}
    }
    return $dir;
}

sub _expand_filename
{
    my($self, $file, $cwd) = @_;
    if ($file eq '')
    {
	return $self->validate_path($cwd);
    }
    elsif ($file =~ m,^(/?)(?:[a-zA-Z0-9_.-]*(?:/[a-zA-Z0-9_.-]*)*),)
    {
	if ($1)
	{
	    return $self->validate_path($file);
	}
	else
	{
	    return $self->validate_path($cwd."/".$file);
	}
    }
    else
    {
	die "Invalid filename $file";
    }
    
    #return $self->_session_dir($session) . "/$file";
}

sub validate_path
{
    my($self, $cwd) = @_;

    if ($cwd eq '/dev/null')
    {
	return $cwd;
    }
    
    my $base = $self->_session_dir();
    my $dir = $base.$cwd;
    my $ap = abs_path($dir);
    if ($ap =~ /^$base/) {
        return $ap;
    } else {
        die "Invalid path '$ap' (cwd='$cwd' base='$base' dir='$dir')";
    }


}

sub _validate_command
{
    my($self, $cmd) = @_;

    my $path;
    if ($self->impl->valid_commands_hash->{$cmd})
    {
	for my $cpath (@{$self->impl->command_path})
	    
	{
	    if (-x "$cpath/$cmd")
	    {
		$path = "$cpath/$cmd";
		last;
	    }
	    else
	    {
		print STDERR "Not found: $cpath/$cmd\n";
	    }
	}
    }
    elsif ($valid_shell_commands{$cmd})
    {
	for my $dir ('/bin', '/usr/bin')
	{
	    if (-x "$dir/$cmd")
	    {
		$path = "$dir/$cmd";
		last;
	    }
	}
    }
    else
    {
	return undef;
    }

    if (! -x $path)
    {
	return undef;
    }
    return $path;
}

=head2 C<$session_id = $us->start_session($provided_session_id)>

Begin a new session. C<$provided_session_id> is the id requested by the user.
For a non-authenticated Iris session this will be the login or workspace name that
the user provided. For an authenticated Iris session this will be empty, and in fact
the session ID will be ignored throughout this interface, and the authenticated
username used in its place.

=cut

sub start_session
{
    my($self, $session_id) = @_;

    if ($self->ctx->authenticated)
    {
	$session_id = '';
    }
    elsif (!$session_id)
    {
	my $dig = Digest::MD5->new();
	if (open(my $rand, "<", "/dev/urandom"))
	{
	    my $dat;
	    my $n = read($rand, $dat, 1024);
	    print STDERR "Read $n bytes of random data\n";
	    $dig->add($dat);
	    close($rand);
	}
	$dig->add($$);
	$dig->add($self->{counter}++);
	$dig->add($self->{storage_dir});
	
	$session_id = $dig->hexdigest;
    }
    elsif (!$self->_valid_session_name($session_id))
    {
	die "Invalid session id";
    }
    $self->session_id($session_id);
    my $dir = $self->_session_dir();
    if (!-d $dir)
    {
	mkdir($dir) or die "Cannot create session directory";
    }
    return $session_id;
}

sub list_files
{
    my($self, $cwd, $d) = @_;
    
    my $dir  = $self->_expand_filename($d, $cwd);
    my $fpath;
    my $base = $self->_session_dir();
    if ($dir =~ /^$base(.*)/)
    {
	$fpath = $1 ? $1 : "/";
    }
    else
    {
	die "Invalid path $dir";
    }

    my @dirs;
    my @files;
    my $dh;
    opendir($dh, $dir) or die "Cannot open directory: $!";
    while (my $file = readdir($dh)) {
	next if ($file =~ m/^\./);
	my($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat("$dir/$file");

	my $date= strftime("%b %d %G %H:%M:%S", localtime($mtime));

        if (-f "$dir/$file") {
	    push @files, { name => $file, full_path => "$fpath/$file", mod_date => $date, size => $size};
        } elsif (-d "$dir/$file") {
	    push @dirs, { name => $file, full_path => "$fpath/$file", mod_date => $date };
        }
    }

    closedir($dh);

    return (\@dirs, \@files);
}

sub remove_files
{
    my($self, $cwd, $filename) = @_;
    my $ap;

    my $ap = $self->_expand_filename($filename, $cwd);

    unlink($ap);
}

sub rename_file
{
    my($self, $cwd, $from, $to) = @_;

    my $apf;
    my $apt;

    my $apf  = $self->_expand_filename($from, $cwd);
    my $apt  = $self->_expand_filename($to, $cwd);

   if (-d $apt) {
       my $f = basename $from;
       $apt = $self->_expand_filename( "$to/$f", $cwd);
   }

    rename($apf, $apt) || die ( "Error in renaming" );
}

sub copy
{
    my($self, $cwd, $from, $to) = @_;

    my $apf;
    my $apt;
    
    $apf = $self->_expand_filename($from, $cwd);
    if (-d $apf) {
	die "Cannot copy a directory";
    }
    $apt = $self->_expand_filename($to, $cwd);
    if (-d $apt) {
	my $f = basename $from;
	$apt = $self->_expand_filename("$to/$f", $cwd);
    }

    File::Copy::copy($apf, $apt) || die "Copy $apf $apt failed: $!";
}

sub make_directory
{
    my($self, $cwd, $directory) = @_;
    my $ap;

    $ap = $self->_expand_filename($directory, $cwd);

    mkdir($ap) || die ( "Error in mkdir" );
}

sub remove_directory
{
    my($self, $cwd, $directory) = @_;

    my $ap;

    $ap = $self->_expand_filename($directory, $cwd);

    rmtree($ap) || die ( "Error in rmdir" );
}

sub change_directory
{
    my($self, $cwd, $directory) = @_;

    my $base = $self->_session_dir();

    my $ap;

    $ap = $self->_expand_filename($directory, $cwd);

    my $return;
    if (-d $ap) {
	print "$ap is a dir";
	if ($ap =~ /^$base(.*)/) {
	    if (!$1) {
		$return = "/";
	    } else {
		$return = $1;
	    }
	} else {
	    die "invalid path";
	}
    }
    else
    {
	die "$directory not a directory";
    }
    return $return;
}

sub put_file
{
    my($self, $filename, $contents, $cwd) = @_;

    #
    # Filenames can't have any special characters or start with a /.
    #
    if ($filename !~ /^([a-zA-Z][a-zA-Z0-9-_]*(?:\/[a-zA-Z][a-zA-Z0-9-_]*)*)/)
    {
	die "Invalid filename";
    }
    my $ap;

    $ap = $self->_expand_filename($filename, $cwd);

    open(my $fh, ">", $ap) or die "Cannot open $ap: $!";
    print $fh $contents;
    close($fh);
}

sub get_file
{
    my($self, $filename, $cwd) = @_;

    my $contents;
    my $ap;

    $ap = $self->_expand_filename($filename, $cwd);

    $contents = read_file($ap);
    if (!defined($contents))
    {
	die "Error reading $filename: $!";
    }
    return $contents;
}

sub run_pipeline
{
    my($self, $pipeline, $input, $max_output_size, $cwd) = @_;

    my($output, $errors);

    print STDERR "Parse: '$pipeline'\n";
    $pipeline =~ s/\xA0/ /g;
    print STDERR "Parse: '$pipeline'\n";
    my $parser = Bio::KBase::InvocationService::PipelineGrammar->new;
    $parser->input($pipeline);
    my $tree = $parser->Run();

    if (!$tree)
    {
	die "Error parsing command line";
    }

    #
    # construct pipeline for IPC::Run
    #

    my @cmds;

    print STDERR Dumper($tree);

    $output = [];
    $errors = [];

    my $harness;

    my %env;

    #
    # Compute environment for our subprocesses. We set these in the IPC::Run
    # init hook so that we don't pollute the environment of the service itself.
    #

    $env{KB_RUNNING_IN_IRIS} = 1;
    if ($self->ctx->authenticated)
    {
	$env{KB_IRIS_FOLDER} = '';
	$env{KB_AUTH_TOKEN} = $self->ctx->token;
	$env{KB_AUTH_USER_ID} = $self->ctx->user_id;
    }
    else
    {
	$env{KB_IRIS_FOLDER} = $self->session_id;
	$env{KB_AUTH_TOKEN} = $self->ctx->token;
	$env{KB_AUTH_USER_ID} = $self->ctx->user_id;
    }

    my $dir = $self->validate_path($cwd);
    my @cmd_list;
    my @saved_stderr;
 PIPELINE:
    for my $idx (0..$#$tree)
    {
	my $ent = $tree->[$idx];
	
	my $cmd = $ent->{cmd};
	my $redirect = $ent->{redir};
	my $args = $ent->{args};

	my $cmd_path = $self->_validate_command($cmd);
	if (!$cmd_path)
	{
	    push(@$errors, "$cmd: invalid command");
	    next;
	}

	if (@cmds)
	{
	    push(@cmds, '|');
	}
	$saved_stderr[$idx] = [];
	push(@cmd_list, $cmd);
	if ($cmd eq 'sort')
	{
	    if (!grep { $_ eq '-t' } @$args)
	    {
		unshift(@$args, "-t", "\t");
	    }
	}
	push(@cmds, [$cmd_path, map { s/\\t/\t/g; $_ } @$args]);
	push @cmds, init => sub {
	    $ENV{$_} = $env{$_} foreach keys %env;
	    chdir $dir or die $!;
	};
	my $have_output_redirect;
	my $have_stderr_redirect;
	my $have_stdin_redirect;
	for my $r (@$redirect)
	{
	    my($what, $file) = @$r;
	    if ($what eq '<')
	    {
		my $path = $self->_expand_filename($file, $cwd);
		if (! -f $path)
		{
		    push(@$errors, "$file: input not found");
		    next PIPELINE;
		}
		$have_stdin_redirect = 1;
		push(@cmds, '<', $path);
	    }
	    elsif ($what eq '>' || $what eq '>>' || $what eq '2>' || $what eq '2>>')
	    {
		my $path = $self->_expand_filename($file, $cwd);
		push(@cmds, $what, $path);
		if ($what =~ /^2/)
		{
		    $have_stderr_redirect = 1;
		}
		else
		{
		    $have_output_redirect = 1;
		}
	    }
	    
	}
	if ($idx == 0)
	{
	    if (!$have_stdin_redirect)
	    {
		push(@cmds, '<', '/dev/null');
	    }
	}
	if ($idx == $#$tree)
	{
	    if (!$have_output_redirect)
	    {
		push(@cmds, '>', IPC::Run::new_chunker, sub {
		    my($l) = @_;
		    push(@$output, $l);
		    if ($max_output_size > 0 && @$output >= $max_output_size)
		    {
			push(@$errors, "Output truncated to $max_output_size lines");
			$harness->kill_kill;
		    }
		});
	    }
	}
	if (!$have_stderr_redirect)
	{
	    push(@cmds, '2>', IPC::Run::new_chunker, sub {
		my($l) = @_;
		push(@{$saved_stderr[$idx]}, $l);
	    });
	}
    }

    print STDERR Dumper(\@cmds);
    $output = [];

    if (@$errors == 0)
    {
	my $h = IPC::Run::start(@cmds);
	$harness = $h;
	eval {
	    $h->finish();
	};

	my $err = $@;
	if ($err)
	{
	    push(@$errors, "Error invoking pipeline");
	    warn "error invooking pipeline: $err";
	}
	
	my @res = $h->results();
	for (my $i = 0; $i <= $#res; $i++)
	{
	    if ($res[$i] != 0 || $self->impl->verbose_status)
	    {
		push(@$errors, "Return code from $cmd_list[$i]: $res[$i]");
	    }
	    push(@$errors, @{$saved_stderr[$i]});
	}
    }

    if ($max_output_size > 0 && @$output > $max_output_size)
    {
	my $removed = @$output - $max_output_size;
	$#$output = $max_output_size - 1;
	push(@$errors, "Elided $removed lines of output");
    }
	
    return($output, $errors);
}

sub run_pipeline2
{
    my($self, $pipeline, $input, $max_output_size, $cwd) = @_;

    my($output, $errors, $stdweb);
    print STDERR "Parse: '$pipeline'\n";
    $pipeline =~ s/\xA0/ /g;
    print STDERR "Parse: '$pipeline'\n";
    my $parser = Bio::KBase::InvocationService::PipelineGrammar->new;
    $parser->input($pipeline);
    my $tree = $parser->Run();

    if (!$tree)
    {
	die "Error parsing command line";
    }

    #
    # construct pipeline for IPC::Run
    #

    my @cmds;

    print STDERR Dumper($tree);

    $output = [];
    $errors = [];

    my $harness;

    my $dir = $self->validate_path($cwd);
    my @cmd_list;
    my @saved_stderr;
 PIPELINE:
    for my $idx (0..$#$tree)
    {
	my $ent = $tree->[$idx];
	
	my $cmd = $ent->{cmd};
	my $redirect = $ent->{redir};
	my $args = $ent->{args};

	my $cmd_path = $self->_validate_command($cmd);
	if (!$cmd_path)
	{
	    push(@$errors, "$cmd: invalid command");
	    next;
	}

	
	if (@cmds)
	{
	    push(@cmds, '|');
	}
	$saved_stderr[$idx] = [];
	push(@cmd_list, $cmd);
	if ($cmd eq 'sort')
	{
	    if (!grep { $_ eq '-t' } @$args)
	    {
		unshift(@$args, "-t", "\t");
	    }
	}
	push(@cmds, [$cmd_path, map { s/\\t/\t/g; $_ } @$args]);
	push @cmds, init => sub {
	    chdir $dir or die $!;
	    $ENV{KB_STDWEB} = 3;
	};
	my $have_output_redirect;
	my $have_stderr_redirect;
	my $have_stdin_redirect;
	for my $r (@$redirect)
	{
	    my($what, $file) = @$r;
	    if ($what eq '<')
	    {
		my $path = $self->_expand_filename($file, $cwd);
		if (! -f $path)
		{
		    push(@$errors, "$file: input not found");
		    next PIPELINE;
		}
		$have_stdin_redirect = 1;
		push(@cmds, '<', $path);
	    }
	    elsif ($what eq '>' || $what eq '>>' || $what eq '2>' || $what eq '2>>')
	    {
		my $path = $self->_expand_filename($file, $cwd);
		push(@cmds, $what, $path);
		if ($what =~ /^2/)
		{
		    $have_stderr_redirect = 1;
		}
		else
		{
		    $have_output_redirect = 1;
		}
	    }
	    
	}
	if ($idx == 0)
	{
	    if (!$have_stdin_redirect)
	    {
		push(@cmds, '<', '/dev/null');
	    }
	}
	if ($idx == $#$tree)
	{
	    if (!$have_output_redirect)
	    {
		push(@cmds, '>', IPC::Run::new_chunker, sub {
		    my($l) = @_;
		    push(@$output, $l);
		    if ($max_output_size > 0 && @$output >= $max_output_size)
		    {
			push(@$errors, "Output truncated to $max_output_size lines");
			$harness->kill_kill;
		    }
		});
	    }
	    push(@cmds, "3>", \$stdweb);
	}
	if (!$have_stderr_redirect)
	{
	    push(@cmds, '2>', IPC::Run::new_chunker, sub {
		my($l) = @_;
		push(@{$saved_stderr[$idx]}, $l);
	    });
	}
    }

    print STDERR Dumper(\@cmds);
    $output = [];

    if (@$errors == 0)
    {
	my $h = IPC::Run::start(@cmds);
	$harness = $h;
	eval {
	    $h->finish();
	};

	my $err = $@;
	if ($err)
	{
	    push(@$errors, "Error invoking pipeline");
	    warn "error invooking pipeline: $err";
	}
	
	my @res = $h->results();
	for (my $i = 0; $i <= $#res; $i++)
	{
	    push(@$errors, "Return code from $cmd_list[$i]: $res[$i]");
	    push(@$errors, @{$saved_stderr[$i]});
	}
    }

    if ($max_output_size > 0 && @$output > $max_output_size)
    {
	my $removed = @$output - $max_output_size;
	$#$output = $max_output_size - 1;
	push(@$errors, "Elided $removed lines of output");
    }
}

1;
