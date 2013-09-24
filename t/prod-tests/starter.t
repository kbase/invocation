#!/usr/bin/perl

use  HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use JSON;
use Data::Dumper;

use strict;
use warnings;

my $ua = LWP::UserAgent->new;
my $url = 'http://kbase.us/services/invocation';
my $session_id = 'test_person';

my $json = JSON->new->allow_nonref;

sub test_for_response {
    my $url    = shift;
    my $params = shift;
    my $method = shift;

    my $ua = LWP::UserAgent->new;

    my $req = HTTP::Request->new( 'POST', $url );

    $req->content(
        $json->encode(
            {
                "params" => $params,
                "method" => $method,
                "version"=>"1.1"
            }
        )
    );

    return $json->decode($ua->request($req)->content);
}

print "test 1".Dumper (test_for_response( $url,[$session_id,'/',''],"InvocationService.start_session"));
print "test 2".Dumper ( test_for_response( $url, [ $session_id, '/', '' ],                               "InvocationService.list_files") );
print "test 3".Dumper ( test_for_response( $url, [ $session_id, 'test_file', 'I contain data', '/' ],    "InvocationService.put_file") );
print "test 4".Dumper ( test_for_response( $url, [ $session_id, 'test_file2', 'I contain data', '/' ],   "InvocationService.put_file") );
print "test 5".Dumper ( test_for_response( $url, [ $session_id, '/', '' ],                               "InvocationService.list_files") );
print "test 6".Dumper ( test_for_response( $url, [ $session_id, '/', 'test_file' ],                      "InvocationService.remove_files") );
print "test 7".Dumper ( test_for_response( $url, [ '2' ] ,                                               "InvocationService.get_tutorial_text") );
#[session_id, pipeline, input, max_output_size, cwd]
print Dumper ( test_for_response( $url, [ $session_id, 'echo "foo"', [], undef, '/' ],          "InvocationService.run_pipeline2") );
