
#!/usr/bin/perl

use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use JSON;
use Data::Dumper;
use Test::More tests=>26;

use strict;
use warnings;

use Bio::KBase::InvocationService::Client; 

my $session_id = 'test_person1';
my $cwd = '/';
my $host = "http://localhost:7049";

# Created by Jason Baumohl for Novemeber 2012 Build 11-29-2012
# Updated By: ?

#
# NEW
#
print "Test 1 :\n";
my $obj = Bio::KBase::InvocationService::Client->new($host);
ok(defined $obj, "Did object get made");
print "Test 2 :\n";
isa_ok( $obj, 'Bio::KBase::InvocationService::Client', "Is it in the right class" );
#print "OBJ:".Dumper($obj);

cleanup_session($obj,$session_id,$cwd,'before');
 

#
# START_SESSION
#
print "Test 3 :\n";
my $ret_session_id = $obj->start_session($session_id);
isnt($ret_session_id, '',"Has Non Null Session_id");
print "Test 4 :\n";
is($ret_session_id,$session_id,"Session id is as expected");

#
# VALID SESSION
#
print "Test 5:\n"; 
my $val_session_id = $obj->valid_session($session_id);
isnt($val_session_id, '',"Has Non Null Valid Session_id");
print "Test 6 :\n"; 
ok($val_session_id>0,"Valid Session id is as expected");

print "Test 7:\n"; 
my $inval_session_id = $obj->valid_session('not real session'); 
isnt($inval_session_id, '',"Has Non Null Valid Session_id for bad session id"); 
print "Test 8 :\n"; 
ok(!defined($inval_session_id),"Invalid Session id is as expected");

#
# PUT and GET FILE
#
print "Test 9 :\n";
my $file_name = 'test_file_1';
my $contents = "This is the contents of test_file 1";
$obj->put_file($session_id,$file_name,$contents,$cwd);
my $ret_contents = $obj->get_file($session_id, $file_name,$cwd);
ok($contents eq $ret_contents,"put and get file tests");

#
# List Files
#
my $ret_list_files1;
my $ret_list_files2;
($ret_list_files1,$ret_list_files2) = $obj->list_files($session_id,$cwd,'');
print "Test 10 :\n";
print "file1 : ".Dumper($ret_list_files1)."\n";
print "file2 : ".Dumper($ret_list_files2)."\n";
is(ref($ret_list_files2),'ARRAY',"LIST FILES is an array");
print "Test 11 :\n";
ok($ret_list_files2->[0]->{'name'} eq $file_name,"List file test");

#
# Rename_file
#
print "Test 12 : \n";
my $new_file_name = 'new_test_file_name';
$obj->rename_file($session_id,$cwd,$file_name,$new_file_name);
($ret_list_files1,$ret_list_files2) = $obj->list_files($session_id,$cwd,''); 
ok($ret_list_files2->[0]->{'name'} eq $new_file_name,"RENAME FILE Test ");
print "file2 : ".Dumper($ret_list_files2)."\n"; 

#                                                                                                 
# copy_files                                                                                     
#                                                                                                 
print "Test 13 : \n";
$obj->copy($session_id,$cwd,$new_file_name,$file_name);
($ret_list_files1,$ret_list_files2) = $obj->list_files($session_id,$cwd,''); 
my %file_name_hash;
foreach my $file_element_hash (@{$ret_list_files2})
{
    $file_name_hash{$file_element_hash->{'name'}}=1;    
}
ok((defined($file_name_hash{$new_file_name})&& defined($file_name_hash{$file_name})),
   "Copy Files finding both $file_name and $new_file_name");
print "file2 : ".Dumper($ret_list_files2)."\n";


#
# remove_files
#
print "Test 14 : \n";
$obj->remove_files($session_id,$cwd,$file_name);
($ret_list_files1,$ret_list_files2) = $obj->list_files($session_id,$cwd,''); 
undef %file_name_hash;
foreach my $file_element_hash (@{$ret_list_files2})
{ 
    $file_name_hash{$file_element_hash->{'name'}}=1; 
} 
ok((defined($file_name_hash{$new_file_name})&& (!defined($file_name_hash{$file_name}))), 
   "Attempting Remove Single File $file_name "); 
print "file2 : ".Dumper($ret_list_files2)."\n"; 

my $directory = "new_dir"; 

#
# make directory
#
print "Test 15 : \n";
$obj->make_directory($session_id, $cwd, $directory);
$obj->put_file($session_id,$file_name,$contents,$cwd.$directory); 
my $ret_contents2 = $obj->get_file($session_id, $file_name,$cwd.$directory); 
ok($contents eq $ret_contents2,"New Directory made and file put there."); 

#
# change directory
#
# NO REAL VALID TEST TO DO THIS
#my $changed_directory = $obj->change_directory($session_id, $cwd, $directory);
#print "\nChanged Directory:$changed_directory:\n";
#($ret_list_files1,$ret_list_files2) = $obj->list_files($session_id,$cwd.$directory,''); 
#print "files of $directory : ".Dumper($ret_list_files2)."\n"; 

#
# Valid Commands
#
print "Test 16 : \n";
my $valid_commands = $obj->valid_commands();
my @top_level_commands_grouping_names = ('modeling_scripts','tree_scripts','scripts','anno_scripts','er_scripts');
my %grouping_names_hash; #key: name of group and value: number of commands
foreach my $grouping_hash_ref (@{$valid_commands})
{
    $grouping_names_hash{$grouping_hash_ref->{'name'}} = scalar(@{$grouping_hash_ref->{'items'}});
    print "Command Grouping Name: ".$grouping_hash_ref->{'name'}.
	"\tNumber of Commands:".scalar(@{$grouping_hash_ref->{'items'}})."\n";
}
my $number_found = 0;
foreach my $group_name (@top_level_commands_grouping_names)
{
    if(exists($grouping_names_hash{$group_name}))
    {
	$number_found++;
    }
}
ok($number_found >= scalar(@top_level_commands_grouping_names),
   "Valid commands works and has at least the expected command groupings\n(".
    join(",",@top_level_commands_grouping_names).")");

#
# GET_TUTORIAL_TEXT
#
print "\nTest 17 : \n";
my $step = 1;
my ($text,$prev,$next) = $obj->get_tutorial_text($step);
print "\nTEXT: $text";
print "\nPREV: $prev";
print "\nNEXT: $next";
ok(defined($text) && defined($prev) && defined($next),"Get Tutorial working properly");

#
# RUN PIPELINE
#
#Not sure what valid inputs are for  $pipeline, $input, $max_output_size
print "\nTest 18-19 : \n";
my $pipeline = "annotate";
my @input_array = ("1","2","a","b");
my $input = \@input_array;
my $max_output_size = 10000;
my ($output, $errors) = $obj->run_pipeline($session_id, $pipeline, $input, $max_output_size, $cwd);

ok(ref($output) eq 'ARRAY',"Run Pipeline output is an array");
ok(ref($errors) eq 'ARRAY',"Run Pipeline errors is an array");

#                                                                                                             
# RUN PIPELINE 2                                                                                                
#                                                                                                              
#Not sure what valid inputs are for  $pipeline, $input, $max_output_size                                     
print "\nTest 20-23 : \n";
my $pipeline = "annotate"; 
my @input_array = ("1","2","a","b"); 
my $input = \@input_array; 
my $max_output_size = 10000; 
my ($output, $errors, $stdweb) = $obj->run_pipeline2($session_id, $pipeline, $input, $max_output_size, $cwd); 
 
ok(ref($output) eq 'ARRAY',"Run Pipeline2 output is an array"); 
ok(ref($errors) eq 'ARRAY',"Run Pipeline2 errors is an array"); 
ok(defined($stdweb),"Run Pipeline2 stdweb is defined");
ok($stdweb ne '',"Run Pipeline2 stdweb is not an empty string");


cleanup_session($obj,$session_id,$cwd,'after');

#
# exit_session
#
print "\nTest 26 : \n";
eval {$obj->exit_session($session_id)};
ok($@ eq '', 'Exit session');

done_testing();


sub cleanup_session
{
    #Does a list file and removes all files and directories that exist within the session.
    my $obj = shift;
    my $session_id = shift;
    my $cwd = shift;
    my $time = shift; #before or after  (if after does a test)
    my ($ret_list_files1,$ret_list_files2) = $obj->list_files($session_id,$cwd,'');
    print "Running Cleanup\n";

    print "directories before clean up : ".Dumper($ret_list_files1)."\n";
    print "files before clean up: ".Dumper($ret_list_files2)."\n";
    
    foreach my $file_element_hash (@{$ret_list_files2}) 
    { 
	my $file_to_remove = $file_element_hash->{'name'}; 
	$obj->remove_files($session_id,$cwd,$file_to_remove);
    } 
    foreach my $directory_element_hash (@{$ret_list_files1}) 
    { 
        my $directory_to_remove = $directory_element_hash->{'name'};
        $obj->remove_directory($session_id,$cwd,$directory_to_remove);
    }
    ($ret_list_files1,$ret_list_files2) = $obj->list_files($session_id,$cwd,''); 
    if ($time eq 'after')
    {
	ok(scalar(@{$ret_list_files2}) == 0,"Remove files test.");
	ok(scalar(@{$ret_list_files1}) == 0,"Remove directories test.");
    }

    print "directories after clean up : ".Dumper($ret_list_files1); 
    print "files after clean up: ".Dumper($ret_list_files2)."\n"; 
}
