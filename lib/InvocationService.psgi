use strict;
use Bio::KBase::InvocationService::InvocationServiceImpl;

use Bio::KBase::InvocationService::Service;

use Bio::KBase::AuthToken;

use Data::Dumper;
use File::Path qw(make_path);
use Plack::Request;
use URI::Dispatch;
use Bio::KBase::DeploymentConfig;
use Cwd 'abs_path';

my @dispatch;

my $tmpdir = abs_path("/tmp");

my $cfg = Bio::KBase::DeploymentConfig->new("InvocationService", {
    'authenticated-storage' => "$tmpdir/InvocationService/authenticated-storage",
    'nonauthenticated-storage' => "$tmpdir/InvocationService/nonauthenticated-storage",
});

my $auth_storage = $cfg->setting('authenticated-storage');
my $nonauth_storage = $cfg->setting('nonauthenticated-storage');

make_path($auth_storage);
make_path($nonauth_storage);

print STDERR "auth=$auth_storage nonauth=$nonauth_storage\n";

my $obj = Bio::KBase::InvocationService::InvocationServiceImpl->new($cfg);
push(@dispatch, 'InvocationService' => $obj);

my $server = Bio::KBase::InvocationService::Service->new(instance_dispatch => { @dispatch },
				allow_get => 0,
			       );


my $dispatch = URI::Dispatch->new();
$dispatch->add('/', 'handle_service');
$dispatch->add('/invoke', 'handle_invoke');
$dispatch->add('/upload', 'handle_upload');
$dispatch->add('/download/#*', 'handle_download');
$dispatch->add('//download/#*', 'handle_download');

{
    package handle_download;
    use strict;
    use Data::Dumper;

    sub get
    {
	my($req, $args) = @_;
	my $session = $req->param("session_id");

    my $token = $server->_plack_req->header("Authorization");
	my $auth_token = Bio::KBase::AuthToken->new(token => $token, ignore_authrc => 1);
	my $valid = $auth_token->validate();

    my $ctx = undef;
    if ($valid) {
        $ctx = Bio::KBase::InvocationService::ServiceContext->new(client_ip => $server->_plack_req->address);
	    $ctx->authenticated(1);
	    $ctx->user_id($auth_token->user_id);
	    $ctx->token( $token);
    }

	my $us = Bio::KBase::InvocationService::UserSession->new($obj, $session, $ctx);

	my $dir = $us->_session_dir();

	if (! -d $dir)
	{
	    return [500, [], ["Invalid session id\n"]];
	}

	#
	# Validate path given.
	#
	my $file = $args->[0];
	my @comps = split(/\//, $file);
	if (grep { $_ eq '..' } @comps)
	{
	    return [404, [], ["File not found\n"]];
	}

	my $path = "$dir/$file";
	my $fh;
	if (!open($fh, "<", $path))
	{
	    return [404, [], ["File not found\n"]];
	}

    (my $fileName = $file) =~ s!^(?:.*)/([^/]+)$!$1!g;

	return [
		200,
		[
			'Content-type' => 'application/force-download',
			'Content-Disposition' => "attachment; filename=\"$fileName\"",
			'Content-Length' => -s $path,
		],
		$fh
	];
    }
}

{
    package handle_upload;
    use strict;
    use Data::Dumper;

    sub post
    {
	my($req, $args) = @_;

	my @origin_hdr = ('Access-Control-Allow-Origin', $req->env->{HTTP_ORIGIN});

	my $session = $req->param("session_id");
	my $us = Bio::KBase::InvocationService::UserSession->new($obj, $session, undef);

	my $dir = $obj->_session_dir();
	if (!-d $dir)
	{
	    return [500, \@origin_hdr, ["Invalid session id\n"]];
	}

	#
	# Validate path given.
	#
	my $file = $req->param('qqfile');
	my @comps = split(/\//, $file);
	if (grep { $_ eq '..' } @comps)
	{
	    return [404, \@origin_hdr, ["File not found\n"]];
	}

	my $path = "$dir/$file";
	my $fh;
	if (!open($fh, ">", $path))
	{
	    return [404, \@origin_hdr, ["File not found\n"]];
	}

	my $buf;
	while ($req->input->read($buf, 4096))
	{
	    print $fh $buf;
	}
	close($fh);

	my @hdrs;
	if ($req->env->{HTTP_ORIGIN})
	{
	    push(@hdrs, 'Access-Control-Allow-Origin', $req->env->{HTTP_ORIGIN});
	}

	return [200, \@hdrs, ['{ "success": true}']];
    }
    sub options
    {
	my($req, $args) = @_;

	my @origin_hdr = ('Access-Control-Allow-Origin', $req->env->{HTTP_ORIGIN},
			  'Access-Control-Allow-Methods', $req->env->{HTTP_ACCESS_CONTROL_REQUEST_METHOD},
			  'Access-Control-Allow-Headers', $req->env->{HTTP_ACCESS_CONTROL_REQUEST_HEADERS},
			  'Access-Control-Expose-Headers', $req->env->{HTTP_ACCESS_CONTROL_REQUEST_HEADERS},
			  'Access-Control-Allow-Credentials', 'true');

	return [200, \@origin_hdr, []];
    }

}

{
    package handle_invoke;

    use strict;
    use Data::Dumper;

    sub post
    {
	my($req) = @_;
	#
	# The invoke REST interface expects to get a 3-line header:
	#
	#   session-id
	#   pipeline
	#   cwd
	#
	# followed by the pipeline input. It emits lines of output
	# which may have stdout and stderr interleaved; the lines are
	# prefixed by the characters 'O' for stdout and 'E' for stderr.
	#
    }
}

{
    package handle_service;
    use strict;
    use Data::Dumper;

    sub post
    {
	my($req) = @_;

	my $resp = $server->handle_input($req->env);
	my($code, $hdrs, $body) = @$resp;
#	if ($code =~ /^5/)
	{
	    if ($req->env->{HTTP_ORIGIN})
	    {
		push(@$hdrs, 'Access-Control-Allow-Origin', $req->env->{HTTP_ORIGIN});
	    }
	}
	return $resp;
    }
    sub options
    {
	my($req, $args) = @_;

	my @origin_hdr = ('Access-Control-Allow-Origin', $req->env->{HTTP_ORIGIN},
			  'Access-Control-Allow-Methods', $req->env->{HTTP_ACCESS_CONTROL_REQUEST_METHOD},
			  'Access-Control-Allow-Headers', $req->env->{HTTP_ACCESS_CONTROL_REQUEST_HEADERS},
			  'Access-Control-Expose-Headers', $req->env->{HTTP_ACCESS_CONTROL_REQUEST_HEADERS},
			  'Access-Control-Allow-Credentials', 'true');

	return [200, \@origin_hdr, []];
    }
}

my $handler = sub {
    my($env) = @_;
    print Dumper($env);
    my $req = Plack::Request->new($env);
    my $ret = $dispatch->dispatch($req);
    return $ret;
};

$handler;
