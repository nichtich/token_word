#!/usr/bin/perl -wT

#
# Modification History
#
# 2003-January-6   Jason Rohrer
# Created.
#


use lib '.';

use strict;


use tokenWord::userManager;
use tokenWord::common;


print "test\n";

setupDataDirectory();

tokenWord::userManager::addUser( "jj55", "testPass", "15" );



sub setupDataDirectory {
    if( not -e "$dataDirectory" ) {
        
        mkdir( "$dataDirectory", oct( "0777" ) );
        mkdir( "$dataDirectory/users", oct( "0777" ) );
    }
}
