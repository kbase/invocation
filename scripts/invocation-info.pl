#
# Little test script to dump info from the invocation service variables.
#

print "Running in Iris: $ENV{KB_RUNNING_IN_IRIS}\n";
if ($ENV{KB_AUTH_TOKEN})
{
    print "Running authenticated user=$ENV{KB_AUTH_USER_ID}\n";
}
else
{
    print "Running nonauthenticated folder=$ENV{KB_IRIS_FOLDER}\n";
}


