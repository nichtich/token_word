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
    # untaint
    ( $loggedInUser ) = ( $loggedInUser =~ /(\w+)/ );
}
else {
    $loggedInUser = '';
}



if( $action eq "createUserForm" ) {
    print $cgiQuery->header( -type=>'text/html', -expires=>'now' );
    tokenWord::htmlGenerator::generateCreateUserForm( "" );
}
elsif( $action eq "createUser" ) {
    my $user = $cgiQuery->param( "user" ) || '';
    my $password = $cgiQuery->param( "password" ) || '';

    #untaint
    ( $user ) = ( $user =~ /(\w+)/ );
    ( $password ) = ( $password =~ /(\w+)/ );


    if( $user eq '' or length( $password ) < 4 ) {
        print $cgiQuery->header( -type=>'text/html', -expires=>'now' );
        tokenWord::htmlGenerator::generateCreateUserForm( 
                        "password must be at least 4 characters long" );
    }
    else {
        my $success = 
          tokenWord::userManager::addUser( $user, $password, 10000 );
    
        if( not $success ) {
            print $cgiQuery->header( -type=>'text/html', -expires=>'now' );
            tokenWord::htmlGenerator::generateCreateUserForm( 
                                                 "username already exists" );
        }
        else {
            print $cgiQuery->header( -type=>'text/html', -expires=>'now' );
            tokenWord::htmlGenerator::generateLoginForm( 
                                        "user $user created, please log in" );
        }
    }
}
elsif( $action eq "loginForm" ) {
    print $cgiQuery->header( -type=>'text/html', -expires=>'now' );
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
        print $cgiQuery->header( -type=>'text/html', -expires=>'now' );
        tokenWord::htmlGenerator::generateLoginForm( "login failed" );
    }
    else {
        my $cookie = $cgiQuery->cookie( -name=>"loggedInUser",
                                        -value=>"$user",
                                        -expires=>'+1h' );
        
        print $cgiQuery->header( -type=>'text/html',
                                 -expires=>'now',
                                 -cookie=>$cookie );
        
        tokenWord::htmlGenerator::generateMainPage( "$user" );
    }
}
elsif( $action eq "logout" ) {
    my $cookie = $cgiQuery->cookie( -name=>"loggedInUser",
                                    -value=>"" );
    
    print $cgiQuery->header( -type=>'text/html',
                             -expires=>'now',
                             -cookie=>$cookie );
    
    tokenWord::htmlGenerator::generateLoginForm( 
                                     "$loggedInUser has logged out\n" );
}
else {
    

    


    if( $loggedInUser eq '' ) {
        print $cgiQuery->header( -type=>'text/html', -expires=>'now' );

        tokenWord::htmlGenerator::generateLoginForm( "" );
    }
    else {

        # send back a new cookie to keep the user logged in
        my $cookie = $cgiQuery->cookie( -name=>"loggedInUser",
                                        -value=>"$loggedInUser",
                                        -expires=>'+1h' );
        print $cgiQuery->header( -type=>'text/html',
                                 -expires=>'now',
                                 -cookie=>$cookie );

        if( $action eq "test" ) {
            print "test for user $loggedInUser\n";
        }
        elsif( $action eq "createDocumentForm" ) {
            tokenWord::htmlGenerator::generateCreateDocumentForm( 
                                                        $loggedInUser );
        }
        elsif( $action eq "createDocument" ) {
            my $abstractDoc = $cgiQuery->param( "abstractDoc" ) || '';
            
            
            # fix "other" newline style.
            $abstractDoc =~ s/\r/\n/g;
            
            
            # convert non-standard paragraph breaks (with extra whitespace)
            # to newline-newline breaks
            $abstractDoc =~ s/\s*\n\s*\n/\n\n/g;
            
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
            
            #first, purchase the document
            tokenWord::userWorkspace::purchaseDocument( $loggedInUser,
                                                        $docOwner,
                                                        $docID );
            
            my $text = 
                tokenWord::documentManager::renderDocumentText( $docOwner, 
                                                                $docID );
            
            tokenWord::htmlGenerator::generateDocPage( $loggedInUser,
                                                       $docOwner,
                                                       $docID, $text, 0 );
        
        }
        elsif( $action eq "showDocumentQuotes" ) {
        
            my $docOwner = $cgiQuery->param( "docOwner" ) || '';
            
            # might equal 0
            my $docID = $cgiQuery->param( "docID" );
            

            #untaint
            ( $docOwner ) = ( $docOwner =~ /(\w+)/ );
            ( $docID ) = ( $docID =~ /(\d+)/ );
            
            #first, purchase the document
            tokenWord::userWorkspace::purchaseDocument( $loggedInUser,
                                                        $docOwner,
                                                        $docID );
            my @chunks = 
                tokenWord::documentManager::getAllChunks( $docOwner,
                                                          $docID );
            
            tokenWord::htmlGenerator::generateDocQuotesPage( $loggedInUser,
                                                             $docOwner,
                                                             $docID, @chunks );
        
        }
        elsif( $action eq "listQuotingDocuments" ) {
        
            my $docOwner = $cgiQuery->param( "docOwner" ) || '';
            
            # might equal 0
            my $docID = $cgiQuery->param( "docID" );
            

            #untaint
            ( $docOwner ) = ( $docOwner =~ /(\w+)/ );
            ( $docID ) = ( $docID =~ /(\d+)/ );
            
            my @quotingDocs = 
                tokenWord::documentManager::getQuotingDocuments( $docOwner,
                                                                 $docID );
            
            tokenWord::htmlGenerator::generateQuotingDocumentListPage( 
                                                             $loggedInUser,
                                                             $docOwner,
                                                             $docID, 
                                                             @quotingDocs );
            
        }
        elsif( $action eq "showQuoteList" ) {
            
            my @quoteList = 
                tokenWord::quoteClipboard::renderAllQuotes( $loggedInUser );
            
            
            tokenWord::htmlGenerator::generateQuoteListPage( $loggedInUser,
                                                             @quoteList );
        
        }
        elsif( $action eq "extractQuoteForm" ) {
            my $docOwner = $cgiQuery->param( "docOwner" ) || '';
            
            # might equal 0
            my $docID = $cgiQuery->param( "docID" );
            

            #untaint
            ( $docOwner ) = ( $docOwner =~ /(\w+)/ );
            ( $docID ) = ( $docID =~ /(\d+)/ );

            my $text = 
                tokenWord::documentManager::renderDocumentText( $docOwner, 
                                                                $docID );
            
            tokenWord::htmlGenerator::generateExtractQuoteForm( $loggedInUser,
                                                                $docOwner,
                                                                $docID,
                                                                $text );
        }
        elsif( $action eq "extractQuote" ) {
            my $abstractQuote = $cgiQuery->param( "abstractQuote" ) || '';

            my $docOwner = $cgiQuery->param( "docOwner" ) || '';
            
            # might equal 0
            my $docID = $cgiQuery->param( "docID" );
            

            # untaint
            ( $docOwner ) = ( $docOwner =~ /(\w+)/ );
            ( $docID ) = ( $docID =~ /(\d+)/ );


            # fix "other" newline style.
            $abstractQuote =~ s/\r/\n/g;
            
            
            # convert non-standard paragraph breaks (with extra whitespace)
            # to newline-newline breaks
            $abstractQuote =~ s/\s*\n\s*\n/\n\n/g;


            tokenWord::userWorkspace::extractAbstractQuote( $loggedInUser,
                                                            $docOwner, 
                                                            $docID,
                                                            $abstractQuote );
            
            # show the new quote list

            my @quoteList = 
                tokenWord::quoteClipboard::renderAllQuotes( $loggedInUser );
            
            
            tokenWord::htmlGenerator::generateQuoteListPage( $loggedInUser,
                                                             @quoteList );
        }
        else {
            # show main page
            my $text = 
                tokenWord::documentManager::renderDocumentText( "jcr13", 
                                                                0 );
            
            tokenWord::htmlGenerator::generateDocPage( $loggedInUser,
                                                       "jcr13",
                                                       0, $text );
        }
    }
}





sub setupDataDirectory {
    if( not -e "$dataDirectory" ) {
        
        mkdir( "$dataDirectory", oct( "0777" ) );
        mkdir( "$dataDirectory/users", oct( "0777" ) );
    }
}
