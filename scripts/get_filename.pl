use strict;

if (!exists $ENV{KB_STDWEB})
{
    die "no stdweb\n";
}

open(KB_STDWEB, ">&$ENV{KB_STDWEB}" ) or die;
print KB_STDWEB "<p>Some text</p>";
