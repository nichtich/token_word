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
use tokenWord::documentManager;
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

tokenWord::documentManager::addDocument( "jj55", 
                                         "<jj55, 0, 0, 5>\n<jj55, 0, 10, 4>" );

$region = 
  tokenWord::documentManager::getRegionText( "jj55", 0, 0, 9 );
print "Region = $region\n";


sub setupDataDirectory {
    if( not -e "$dataDirectory" ) {
        
        mkdir( "$dataDirectory", oct( "0777" ) );
        mkdir( "$dataDirectory/users", oct( "0777" ) );
    }
}
