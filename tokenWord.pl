#!/usr/bin/perl -wT

#
# Modification History
#
# 2003-January-6   Jason Rohrer
# Created.
#
# 2003-January-7   Jason Rohrer
# Updated to test new features.
#


use lib '.';

use strict;


use tokenWord::common;
use tokenWord::chunkManager;
use tokenWord::documentManager;
use tokenWord::userManager;
use tokenWord::quoteClipboard;
use tokenWord::userWorkspace;


print "test\n";

setupDataDirectory();

    
    # use regexp to untaint username
    #my ( $safeUsername ) = 
    #    ( $username =~ /(\w+)$/ );
    

tokenWord::userManager::addUser( "jj55", "testPass", "15" );
my $chunkID = tokenWord::chunkManager::addChunk( "jj55", 
                                                 "This is a test chunk." );

my $region = 
  tokenWord::chunkManager::getRegionText( "jj55", $chunkID, 10, 4 );
print "chunk region = $region\n";

my $docString = "<jj55, $chunkID, 0, 5>\n<jj55, $chunkID, 10, 4>";
my $docID = 
  tokenWord::documentManager::addDocument( "jj55", $docString );


my $fullDocText =
  tokenWord::documentManager::renderDocumentText( "jj55", $docID );

print "Full document text = \n$fullDocText\n";

$region = 
  tokenWord::documentManager::renderRegionText( "jj55", $docID, 2, 2 );
print "document region = $region\n";


#my $quoteID = tokenWord::quoteClipboard::addQuote( "jj55", "jj55",
#                                                   $docID, 2, 2 );

my $quoteID = tokenWord::userWorkspace::extractAbstractQuote( 
                                                         "jj55", "jj55",
                                                         $docID,
                                                         "T<q>his te</q>st" );

$region = 
  tokenWord::quoteClipboard::renderQuoteText( "jj55", $quoteID );
print "quote = $region\n";

$docID = 
  tokenWord::userWorkspace::submitAbstractDocument(
      "jj55", "I am quoting myself here:  <q $quoteID>" );

print "done submitting document\n";

$fullDocText =
  tokenWord::documentManager::renderDocumentText( "jj55", $docID );

print "Full quote document text = \n$fullDocText\n";



sub setupDataDirectory {
    if( not -e "$dataDirectory" ) {
        
        mkdir( "$dataDirectory", oct( "0777" ) );
        mkdir( "$dataDirectory/users", oct( "0777" ) );
    }
}
