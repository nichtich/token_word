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


# get the cookie, if it exists
my $userCookie = $cgiQuery->cookie( "loggedInUser" ) ;

my $loggedInUser;

if( $userCookie ) {
    $loggedInUser = $userCookie;
    ( $loggedInUser ) = ( $loggedInUser =~ /(\w+)/ );
}
else {
    $loggedInUser = '';
}



if( $action eq "createUserForm" ) {
    print $cgiQuery->header( -type=>'text/html' );
    tokenWord::htmlGenerator::generateCreateUserForm( "" );
}
elsif( $action eq "createUser" ) {
    my $user = $cgiQuery->param( "user" ) || '';
    my $password = $cgiQuery->param( "password" ) || '';

    #untaint
    ( $user ) = ( $user =~ /(\w+)/ );
    ( $password ) = ( $password =~ /(\w+)/ );


    if( $user eq '' or length( $password ) < 4 ) {
        print $cgiQuery->header( -type=>'text/html' );
        tokenWord::htmlGenerator::generateCreateUserForm( 
                        "password must be at least 4 characters long" );
    }
    else {
        my $success = 
          tokenWord::userManager::addUser( $user, $password, 10000 );
    
        if( not $success ) {
            print $cgiQuery->header( -type=>'text/html' );
            tokenWord::htmlGenerator::generateCreateUserForm( 
                                                 "username already exists" );
        }
        else {
            print $cgiQuery->header( -type=>'text/html' );
            tokenWord::htmlGenerator::generateLoginForm( 
                                        "user $user created, please log in" );
        }
    }
}
elsif( $action eq "loginForm" ) {
    print $cgiQuery->header( -type=>'text/html' );
    tokenWord::htmlGenerator::generateLoginForm( "" );
}
elsif( $action eq "login" ) {
    my $user = $cgiQuery->param( "user" ) || '';
    my $password = $cgiQuery->param( "password" ) || '';

    #untaint
    ( $user ) = ( $user =~ /(\w+)/ );
    ( $password ) = ( $password =~ /(\w+)/ );
    
    
    my $correct = tokenWord::userManager::checkLogin( $user, $password );

    if( not $correct ) {
        print $cgiQuery->header( -type=>'text/html' );
        tokenWord::htmlGenerator::generateLoginForm( "login failed" );
    }
    else {
        my $cookie = $cgiQuery->cookie( -name=>"loggedInUser",
                                        -value=>"$user",
                                        -expires=>'+1h' );
        
        print $cgiQuery->header( -type=>'text/html',
                                 -cookie=>$cookie );
        
        tokenWord::htmlGenerator::generateMainPage( "$user" );
    }
}
elsif( $action eq "logout" ) {
    my $cookie = $cgiQuery->cookie( -name=>"loggedInUser",
                                        -value=>"" );
    
    print $cgiQuery->header( -type=>'text/html',
                             -cookie=>$cookie );
    
    tokenWord::htmlGenerator::generateLoginForm( 
                                     "$loggedInUser has logged out\n" );
}
else {
    print $cgiQuery->header( -type=>'text/html' );
    


    if( $loggedInUser eq '' ) {
      tokenWord::htmlGenerator::generateLoginForm( "" );
    }
    else {
        if( $action eq "test" ) {
            print "test for user $loggedInUser\n";
        }
        elsif( $action eq "createDocumentForm" ) {
            tokenWord::htmlGenerator::generateCreateDocumentForm();
        }
        elsif( $action eq "createDocument" ) {
            my $abstractDoc = $cgiQuery->param( "abstractDoc" ) || '';

            my $docID = 
              tokenWord::userWorkspace::submitAbstractDocument(
                       $loggedInUser, 
                       $abstractDoc );

            print "<BR>doc ID is $docID";
            tokenWord::htmlGenerator::generateMainPage( $loggedInUser );
        }
        elsif( $action eq "showDocument" ) {
        
            my $docOwner = $cgiQuery->param( "docOwner" ) || '';
            
            # might equal 0
            my $docID = $cgiQuery->param( "docID" );
            

            #untaint
            ( $docOwner ) = ( $docOwner =~ /(\w+)/ );
            ( $docID ) = ( $docID =~ /(\d+)/ );

            my $text = 
                tokenWord::documentManager::renderDocumentText( $docOwner, 
                                                                $docID );
            # print "owner = $docOwner, ID= $docID";    
            tokenWord::htmlGenerator::generateDocPage( $text );
        
        }
        else {
            tokenWord::htmlGenerator::generateMainPage( $loggedInUser );
        }
    }
}





sub setupDataDirectory {
    if( not -e "$dataDirectory" ) {
        
        mkdir( "$dataDirectory", oct( "0777" ) );
        mkdir( "$dataDirectory/users", oct( "0777" ) );
    }
}
