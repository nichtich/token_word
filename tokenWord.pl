#!/usr/bin/perl -wT

#
# Modification History
#
# 2003-January-6   Jason Rohrer
# Created.
#


use lib '.';

use strict;


use tokenWord::common;
use tokenWord::chunkManager;
use tokenWord::userManager;


print "test\n";

setupDataDirectory();

    
    # use regexp to untaint username
    #my ( $safeUsername ) = 
    #    ( $username =~ /(\w+)$/ );
    

tokenWord::userManager::addUser( "jj55", "testPass", "15" );
tokenWord::chunkManager::addChunk( "jj55", "This is a test chunk." );
my $region = 
  tokenWord::chunkManager::getRegion( "jj55", 0, 10, 4 );
print "Region = $region\n";



sub setupDataDirectory {
    if( not -e "$dataDirectory" ) {
        
        mkdir( "$dataDirectory", oct( "0777" ) );
        mkdir( "$dataDirectory/users", oct( "0777" ) );
    }
}
