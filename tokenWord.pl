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
# 2003-January-13   Jason Rohrer
# Fixed behavior when main page document does not exist.
#
# 2003-January-14   Jason Rohrer
# Fixed holes that would allow a user to read a document without purchasing
# it first.
# Added creation of mostRecent and mostQuoted files.
#
# 2003-January-15   Jason Rohrer
# Added support for deposit page.
# Added support for withdraw page.
# Added support for paypal instant payment notification.
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


my $paypalPercent = 0.029;
my $paypalFee = 0.30;


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



# first check for possible paypal notification
my $payerEmail = $cgiQuery->param( "payer_email" ) || '';
my $paymentGross = $cgiQuery->param( "payment_gross" ) || '';
my $paypalCustom = $cgiQuery->param( "custom" ) || '';
my $paymentDate = $cgiQuery->param( "payment_date" ) || '';

if( $payerEmail ne "" and $paymentGross ne "" and $paypalCustom ne "" ) {
    print $cgiQuery->header( -type=>'text/html', -expires=>'now' );

    if( $loggedInUser ne "" ) {
        # cookie is here, so this request isn't coming from paypal
        
        # show main page
        showMainPage();
    }
    else {
        # no cookie, assume request is coming from paypal

        # we encode the token_word username and num tokens deposited
        # in paypal's custom field
        ( my $user, my $numTokens ) = split( /\|/, $paypalCustom );
    
        ( $user ) = ( $user =~ /(\w+)/ );
        ( $numTokens ) = ( $numTokens =~ /(\d+)/ );



        my $correctEmail = tokenWord::userManager::getPaypalEmail( $user );

        my $dollarsAfterFees = 
            ( $paymentGross * ( 1 - $paypalPercent ) ) - $paypalFee;
        # round down by one cent
        $dollarsAfterFees = $dollarsAfterFees * 100;
        $dollarsAfterFees = int( $dollarsAfterFees - 1 );
        $dollarsAfterFees = $dollarsAfterFees / 100;
    
        my $estimatedNumTokens = $dollarsAfterFees * 1000000;

        if( abs( $estimatedNumTokens - $numTokens ) > 10000 ) {
            # discrepancy between payment and num tokens is more than $0.01
            
            # note mismatch
            addToFile( "$dataDirectory/accounting/paymentNotifications", 
                       "Payment mismatch:  $paymentDate  $user  ".
                       "$payerEmail  $paymentGross  $numTokens\n" );
        }
        elsif( $correctEmail ne $payerEmail ) {
            # note mismatch
            addToFile( "$dataDirectory/accounting/paymentNotifications", 
                       "Email mismatch:  $paymentDate  $user  ".
                       "$payerEmail  $paymentGross  $numTokens\n" );
        }
        else {
            # emails match and token count is close enough, deposit
          tokenWord::userManager::depositTokens( $user, $numTokens );
            
            # note correct transaction
            addToFile( "$dataDirectory/accounting/paymentNotifications", 
                       "Transaction complete:  $paymentDate  $user  ".
                       "$payerEmail  $paymentGross  $numTokens\n" );
        }
    }
}
elsif( $action eq "createUserForm" ) {
    print $cgiQuery->header( -type=>'text/html', -expires=>'now' );
    tokenWord::htmlGenerator::generateCreateUserForm( "" );
}
elsif( $action eq "createUser" ) {
    my $user = $cgiQuery->param( "user" ) || '';
    my $password = $cgiQuery->param( "password" ) || '';
    my $paypalEmail = $cgiQuery->param( "paypalEmail" ) || '';

    #untaint
    ( $user ) = ( $user =~ /(\w+)/ );
    ( $password ) = ( $password =~ /(\w+)/ );
    ( $paypalEmail ) = ( $paypalEmail =~ /(\S+@\S+)/ );

    
    print $cgiQuery->header( -type=>'text/html', -expires=>'now' );

    if( $user eq '' ) {
        tokenWord::htmlGenerator::generateCreateUserForm( 
                        "invalid username" );
    }
    elsif( length( $password ) < 4 ) {
        tokenWord::htmlGenerator::generateCreateUserForm( 
                        "password must be at least 4 characters long" );
    }
    elsif( not ( $paypalEmail =~ /\S+@\S+/ ) ) {
        tokenWord::htmlGenerator::generateCreateUserForm( 
                        "invalid email address" );
    }
    else {
        my $success = 
          tokenWord::userManager::addUser( $user, $password, $paypalEmail,
                                           50000 );
    
        if( not $success ) {
            tokenWord::htmlGenerator::generateCreateUserForm( 
                                                 "username already exists" );
        }
        else {
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
        $loggedInUser = $user;
        showMainPage();
    }
}
elsif( $action eq "logout" ) {
    my $cookie = $cgiQuery->cookie( -name=>"loggedInUser",
                                    -value=>"" );
    
    print $cgiQuery->header( -type=>'text/html',
                             -expires=>'now',
                             -cookie=>$cookie );
    
    if( $loggedInUser ne '' ) {
        tokenWord::htmlGenerator::generateLoginForm( 
                                      "$loggedInUser has logged out\n" );
    }
    else {
        tokenWord::htmlGenerator::generateLoginForm( "" );
    }
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
            
            showMainPage();
        }
        elsif( $action eq "showDocument" ) {
        
            my $docOwner = $cgiQuery->param( "docOwner" ) || '';
            
            # might equal 0
            my $docID = $cgiQuery->param( "docID" );
            

            #untaint
            ( $docOwner ) = ( $docOwner =~ /(\w+)/ );
            ( $docID ) = ( $docID =~ /(\d+)/ );
            
            #first, purchase the document
            ( my $success, my $amount ) =
                tokenWord::userWorkspace::purchaseDocument( $loggedInUser,
                                                            $docOwner,
                                                            $docID );
            if( $success ) {
                my $text = 
                    tokenWord::documentManager::renderDocumentText( $docOwner, 
                                                                    $docID );
            
                tokenWord::htmlGenerator::generateDocPage( $loggedInUser,
                                                           $docOwner,
                                                           $docID, $text, 0 );
            }
            else {
                tokenWord::htmlGenerator::generateFailedPurchasePage(
                                                               $loggedInUser,
                                                               $docOwner,
                                                               $docID,
                                                               $amount );
            }
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
                tokenWord::quoteClipboard::getAllQuoteRegions( $loggedInUser );
            
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

            #first, purchase the document
            tokenWord::userWorkspace::purchaseDocument( $loggedInUser,
                                                        $docOwner,
                                                        $docID );
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
            
            # since abstract quote string contains entire document
            # text, forcing user to purchase document when extracting
            # quote makes sense

            #first, purchase the document
            tokenWord::userWorkspace::purchaseDocument( $loggedInUser,
                                                        $docOwner,
                                                        $docID );


            tokenWord::userWorkspace::extractAbstractQuote( $loggedInUser,
                                                            $docOwner, 
                                                            $docID,
                                                            $abstractQuote );
            
            # show the new quote list
            my @quoteList = 
                tokenWord::quoteClipboard::getAllQuoteRegions( $loggedInUser );
            
            tokenWord::htmlGenerator::generateQuoteListPage( $loggedInUser,
                                                             @quoteList );
        }
        elsif( $action eq "deposit" ) {
        
            my $tokenCount = $cgiQuery->param( "tokenCount" ) || '';
            
            #untaint
            ( $tokenCount ) = ( $tokenCount =~ /(\d+)/ );
            
            my $dollarAmount = $tokenCount / 1000000;
            
            my $netDollarPayment = ($dollarAmount + $paypalFee ) / 
                                   ( 1.0 - $paypalPercent );
            
            # round up to nearest whole cent value
            $netDollarPayment = ($netDollarPayment * 100 )+ 1;
            $netDollarPayment = int( $netDollarPayment );
            $netDollarPayment = $netDollarPayment / 100.0;

            my $paypalEmail = 
              tokenWord::userManager::getPaypalEmail( $loggedInUser );
            
            tokenWord::htmlGenerator::generateDepositConfirmPage(
                                                            $loggedInUser,
                                                            $tokenCount,
                                                            $dollarAmount,
                                                            $netDollarPayment,
                                                            $paypalEmail );
        }
        elsif( $action eq "withdraw" ) {
        
            my $tokenCount = $cgiQuery->param( "tokenCount" ) || '';
            
            #untaint
            ( $tokenCount ) = ( $tokenCount =~ /(\d+)/ );
            
            my $dollarAmount = $tokenCount / 1000000;
            
            my $netDollarRefund = $dollarAmount;
            
            # round downto nearest whole cent value
            $netDollarRefund = ($netDollarRefund * 100 );
            $netDollarRefund = int( $netDollarRefund );
            $netDollarRefund = $netDollarRefund / 100.0;

            my $paypalEmail = 
              tokenWord::userManager::getPaypalEmail( $loggedInUser );
            
            tokenWord::htmlGenerator::generateWithdrawConfirmPage(
                                                            $loggedInUser,
                                                            $tokenCount,
                                                            $dollarAmount,
                                                            $netDollarRefund,
                                                            $paypalEmail );
        }
        elsif( $action eq "confirmedWithdraw" ) {
        
            my $tokenCount = $cgiQuery->param( "tokenCount" ) || '';
            
            #untaint
            ( $tokenCount ) = ( $tokenCount =~ /(\d+)/ );
            
            my $dollarAmount = $tokenCount / 1000000;
            
            my $netDollarRefund = $dollarAmount;
            
            # round downto nearest whole cent value
            $netDollarRefund = ($netDollarRefund * 100 );
            $netDollarRefund = int( $netDollarRefund );
            $netDollarRefund = $netDollarRefund / 100.0;

            my $paypalEmail = 
              tokenWord::userManager::getPaypalEmail( $loggedInUser );
            
            my $success = 
                tokenWord::userManager::withdrawTokens( $loggedInUser,
                                                        $tokenCount ); 
            
            if( $success ) {
                addToFile( "$dataDirectory/accounting/pendingPayments",
                           "$loggedInUser  $paypalEmail".
                           "  $tokenCount  $netDollarRefund" );
                showMainPage();
            }
            else {
                print "you do not have enough tokens for this withdrawl";
            }
        }
        else {
            # show main page
            showMainPage();
        }
    }
}



sub showMainPage {
    
    if( -e "$dataDirectory/users/jcr13/text/documents/0" ) {

        #first, purchase the document
        tokenWord::userWorkspace::purchaseDocument( $loggedInUser,
                                                    "jcr13",
                                                    0 );
        my $text = 
          tokenWord::documentManager::renderDocumentText( "jcr13", 
                                                          0 );
        
        tokenWord::htmlGenerator::generateDocPage( $loggedInUser,
                                                   "jcr13",
                                                   0, $text );
    }
    else {
        tokenWord::htmlGenerator::generateMainPage( $loggedInUser );
    }                                            
}



sub setupDataDirectory {
    if( not -e "$dataDirectory" ) {
        
        mkdir( "$dataDirectory", oct( "0777" ) );
        mkdir( "$dataDirectory/users", oct( "0777" ) );

        mkdir( "$dataDirectory/topDocuments", oct( "0777" ) );
        
        writeToFile( "$dataDirectory/topDocuments/mostQuoted", "" );
        writeToFile( "$dataDirectory/topDocuments/mostRecent", "" );
        
    }
}
