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
# 2003-January-8   Jason Rohrer
# Started working on CGI interface.
#


use lib '.';

use strict;
use CGI;                # Object-Oriented


use tokenWord::common;
use tokenWord::chunkManager;
use tokenWord::documentManager;
use tokenWord::userManager;
use tokenWord::quoteClipboard;
use tokenWord::userWorkspace;

use tokenWord::htmlGenerator;


# make sure data directories exist
setupDataDirectory();



my $cgiQuery = CGI->new();
my $action = $cgiQuery->param( "action" ) || '';

my %userCookie = $cgiQuery->cookie( "loggedInUser" ) ;

my $loggedInUser = $userCookie{ value } || ''; 


my $setCookie = 0;
my $cookie;


if( $action eq "login" ) {
    my $user = $cgiQuery->param( "user" ) || '';
    my $password = $cgiQuery->param( "password" ) || '';
    

    $cookie = $query->cookie( -name=>"loggedInUser",
                              -value=>"$user",
                              -expires=>'+1h' );
    $setCookie = 1;
}

if( $setCookie ) {
    print $cgiQuery->header( -type=>'text/html',
                             -cookie=>$cookie );
}
else {
    print $cgiQuery->header( -type=>'text/html' );
}


if( $loggedInUser eq '' ) {
    tokenWord::htmlGenerator::generateLoginForm();
}
else {

    if( $action eq "showDocument" ) {
        
        my $docOwner = $cgiQuery->param( "docOwner" ) || '';
        my $docID = $cgiQuery->param( "docID" ) || '';
    
        my $text = 
          tokenWord::documentManager::renderDocumentText( $docOwner, $docID );
    
      tokenWord::htmlGenerator::generateDocPage( $text );
    }
}





sub setupDataDirectory {
    if( not -e "$dataDirectory" ) {
        
        mkdir( "$dataDirectory", oct( "0777" ) );
        mkdir( "$dataDirectory/users", oct( "0777" ) );
    }
}
