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
# 2003-January-16   Jason Rohrer
# Added check for correct remote host address.
# Added a failed withdraw page.
# Added MD5 user session ID cookie with corresponding local file.
# Added check for badly-formatted quote extraction.
# Improved behavior on document creation.
# Added document preview.
# Added checks for document existence.
# Added a feedback form.
# Added support for document highlights.
# Added support for adding created documents to index.
# Added limited support for searching.
# Added display of search results.
# Added a spell checker.
# Changed to highlight-only spell checking display.
# Changed to dynamically switch between local and global ispell.
# Added a umask to give group write permissions.
# Updated main page document.
# Replaced expires now with expires -1y to force picky browsers to reload.
#


use lib '.';

use strict;
use CGI;                # Object-Oriented
use MD5;

use tokenWord::common;
use tokenWord::chunkManager;
use tokenWord::documentManager;
use tokenWord::userManager;
use tokenWord::quoteClipboard;
use tokenWord::userWorkspace;
use tokenWord::indexSearch;

use tokenWord::htmlGenerator;

use Time::HiRes;


my $paypalPercent = 0.029;
my $paypalFee = 0.30;
my $paypalNotifyIP = "65.206.229.140";   # IP of notify.paypal.com


# allow group to write to our data files
umask( oct( "02" ) );

# make sure data directories exist
setupDataDirectory();




my $cgiQuery = CGI->new();
my $action = $cgiQuery->param( "action" ) || '';


# get the cookie, if it exists
my $userCookie = $cgiQuery->cookie( "loggedInUser" ) ;
my $userSessionIDCookie = $cgiQuery->cookie( "sessionID" ) ;

my $loggedInUser;
my $sessionID;

if( $userCookie ) {
    $loggedInUser = $userCookie;
    # untaint
    ( $loggedInUser ) = ( $loggedInUser =~ /(\w+)/ );
}
else {
    $loggedInUser = '';
}

if( $userSessionIDCookie ) {
    $sessionID = $userSessionIDCookie;
    # untaint
    ( $sessionID ) = ( $sessionID =~ /(\w+)/ );
}
else {
    $sessionID = '';
}



# first check for possible paypal notification
my $payerEmail = $cgiQuery->param( "payer_email" ) || '';
my $paymentGross = $cgiQuery->param( "payment_gross" ) || '';
my $paypalCustom = $cgiQuery->param( "custom" ) || '';
my $paymentDate = $cgiQuery->param( "payment_date" ) || '';

if( $payerEmail ne "" and $paymentGross ne "" and $paypalCustom ne "" ) {
    print $cgiQuery->header( -type=>'text/html', -expires=>'-1y' );


    # we encode the token_word username and num tokens deposited
    # in paypal's custom field
    ( my $user, my $numTokens ) = split( /\|/, $paypalCustom );
    
    ( $user ) = ( $user =~ /(\w+)/ );
    ( $numTokens ) = ( $numTokens =~ /(\d+)/ );


    if( $loggedInUser ne "" ) {
        # cookie is here, so this request isn't coming from paypal
        
        # show main page
        showMainPage();
    }
    else {
        # no cookie, assume request is coming from paypal

        # make sure host address matches

        my $remoteAddress = $cgiQuery->remote_host();

        if( $remoteAddress eq $paypalNotifyIP ) {

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
        else {
            # remote host does not match what we expect from 
            # paypal
            # note this mismatch
            addToFile( "$dataDirectory/accounting/paymentNotifications", 
                       "Bad remote address ($remoteAddress):  ".
                       "$paymentDate  $user  ".
                       "$payerEmail  $paymentGross  $numTokens\n" );
        }            
    }
}
elsif( $action eq "createUserForm" ) {
    print $cgiQuery->header( -type=>'text/html', -expires=>'-1y' );
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

    
    print $cgiQuery->header( -type=>'text/html', -expires=>'-1y' );

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
    print $cgiQuery->header( -type=>'text/html', -expires=>'-1y' );
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
        print $cgiQuery->header( -type=>'text/html', -expires=>'-1y' );
        tokenWord::htmlGenerator::generateLoginForm( "login failed" );
    }
    else {
        my $userCookie = $cgiQuery->cookie( -name=>"loggedInUser",
                                            -value=>"$user",
                                            -expires=>'+1h' );
        
        # take the MD5 hash of the username, password, 
        # and current system time 
        my $md5 = new MD5;
        $md5->add( $user, $password, time() ); 
        my $newSessionID = $md5->hexdigest();

        my $sessionIDCookie = $cgiQuery->cookie( -name=>"sessionID",
                                                 -value=>"$newSessionID",
                                                 -expires=>'+1h' );
        
        print $cgiQuery->header( -type=>'text/html',
                                 -expires=>'-1y',
                                 -cookie=>[ $userCookie, $sessionIDCookie ] );
        $loggedInUser = $user;

        # save the new session ID
        writeFile( "$dataDirectory/users/$user/sessionID",
                   $newSessionID );

        showMainPage();
    }
}
elsif( $action eq "logout" ) {
    my $userCookie = $cgiQuery->cookie( -name=>"loggedInUser",
                                        -value=>"" );
    my $sessionIDCookie = $cgiQuery->cookie( -name=>"sessionID",
                                             -value=>"" );
    
    print $cgiQuery->header( -type=>'text/html',
                             -expires=>'-1y',
                             -cookie=>[ $userCookie, $sessionIDCookie ] );
    
    # leave the old sessionID file in place    

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
        print $cgiQuery->header( -type=>'text/html', -expires=>'-1y' );

        tokenWord::htmlGenerator::generateLoginForm( "" );
    }
    elsif( -e "$dataDirectory/users/$loggedInUser/sessionID" and
           $sessionID ne 
           readFileValue( "$dataDirectory/users/$loggedInUser/sessionID" ) ) {
        
        # bad session ID returned in cookie
        print $cgiQuery->header( -type=>'text/html', -expires=>'-1y' );

        tokenWord::htmlGenerator::generateLoginForm( "" );
    }
    elsif( not -e "$dataDirectory/users/$loggedInUser/sessionID" ) {
        # session ID file does not exist
        print $cgiQuery->header( -type=>'text/html', -expires=>'-1y' );

        tokenWord::htmlGenerator::generateLoginForm( "" );
    }
    else {
        # session ID returned in cookie is correct

        # send back a new cookie to keep the user logged in longer
        my $userCookie = $cgiQuery->cookie( -name=>"loggedInUser",
                                        -value=>"$loggedInUser",
                                        -expires=>'+1h' );
        my $sessionIDCookie = $cgiQuery->cookie( -name=>"sessionID",
                                                 -value=>"$sessionID",
                                                 -expires=>'+1h' );
        print $cgiQuery->header( -type=>'text/html',
                                 -expires=>'-1y',
                                 -cookie=>[ $userCookie, $sessionIDCookie ] );

        if( $action eq "test" ) {
            print "test for user $loggedInUser\n";
        }
        elsif( $action eq "feedbackForm" ) {            
            tokenWord::htmlGenerator::generateFeedbackForm( $loggedInUser );
        }
        elsif( $action eq "feedback" ) { 
            my $message = $cgiQuery->param( "message" ) || '';

            addToFile( "$dataDirectory/feedback",
                       "$loggedInUser :\n$message\n\n" );
            
            showMainPage();
        }
        elsif( $action eq "createDocumentForm" ) {            
            tokenWord::htmlGenerator::generateCreateDocumentForm( 
                                                        $loggedInUser,
                                                        0, "", "", 0 );
        }
        elsif( $action eq "createDocument" ) {
            my $buttonSubmit = $cgiQuery->param( "buttonSubmit" ) || '';
            my $buttonPreview = $cgiQuery->param( "buttonPreview" ) || '';
            my $abstractDoc = $cgiQuery->param( "abstractDoc" ) || '';
            
            
            if( $buttonPreview ne "" ) {
                # preview mode
                
                # fix "other" newline style.
                $abstractDoc =~ s/\r/\n/g;
            
            
                # convert non-standard paragraph breaks (with extra whitespace)
                # to newline-newline breaks
                $abstractDoc =~ s/\s*\n\s*\n/\n\n/g;

                
                # note that there is a potential payment hole here,
                # since we don't force the user to pay for the quotes
                # before we display them...
                # However, these are the user's quotes, so they paid
                # for them when extracting them...
                # Don't worry about this unless it's a problem in practice.
                my $docTextPreview = 
                    tokenWord::userWorkspace::previewAbstractDocument( 
                                                                $loggedInUser,
                                                                $abstractDoc );
                
                my @misspelledWords = ();

                my $spellCheck = $cgiQuery->param( "spellCheck" ) || '';
                my $spellCheckOn = 0;

                if( $spellCheck eq "1" ) {
                    $spellCheckOn = 1;

                    # take MD5 of doc text to get a unique temp file name
                    my $md5 = new MD5;
                    $md5->add( $docTextPreview ); 
                    my $fileName = $md5->hexdigest();

                    my $filePath = "$dataDirectory/temp/$fileName";
                
                    writeFile( $filePath, $docTextPreview );

                    
                    # find ispell program, either global or local
                    my $ispellCommand;
                    
                    if( -e "/usr/bin/ispell" ) {
                        $ispellCommand ="/usr/bin/ispell -l";
                    }
                    else {
                        # use local ispell install
                        $ispellCommand = "./ispell -l -d ./english.hash";
                    }
                    

                    # call ispell... this is a safe use of the shell
                    # untaint and later restore PATH
                    my $oldPath = $ENV{ "PATH" };
                    $ENV{ "PATH" } = "";
                    
                    my $misspelled = 
                        `/bin/cat ./$filePath | $ispellCommand`;
                    
                    $ENV{ "PATH" } = $oldPath;
                    
                    # delete temp file
                    unlink( $filePath );

                    
                    @misspelledWords = split( /\s+/, $misspelled );
                    
                    # replace misspelled words with red versions
                    foreach my $word ( @misspelledWords ) {
                        my $redWord = "<FONT COLOR=#FF0000>$word</FONT>";
                        
                        # make sure we only replace those that have
                        # not yet been replaced.
                        $docTextPreview =~ 
                            s/([^>])$word([^<])/$1$redWord$2/;
                    }
                
                }
                
                tokenWord::htmlGenerator::generateCreateDocumentForm( 
                                                        $loggedInUser,
                                                        1, 
                                                        $docTextPreview, 
                                                        $abstractDoc,
                                                        $spellCheckOn );
            }
            else {
                # submit mode

                # fix "other" newline style.
                $abstractDoc =~ s/\r/\n/g;
            
            
                # convert non-standard paragraph breaks (with extra whitespace)
                # to newline-newline breaks
                $abstractDoc =~ s/\s*\n\s*\n/\n\n/g;
                
                my $docID = 
                    tokenWord::userWorkspace::submitAbstractDocument(
                                                                $loggedInUser, 
                                                                $abstractDoc );
                my $text = 
                        tokenWord::documentManager::renderDocumentText(
                                                              $loggedInUser, 
                                                              $docID );
                # add to index
                tokenWord::indexSearch::addToIndex( $loggedInUser,
                                                    $docID,
                                                    $text );

                # show the new document
            
                # still need to purchase it, just incase quoted material
                # is not owned yet
                ( my $success, my $amount ) =
                    tokenWord::userWorkspace::purchaseDocument( $loggedInUser,
                                                                $loggedInUser,
                                                                $docID );
                if( $success ) {
                    tokenWord::htmlGenerator::generateDocPage( $loggedInUser,
                                                               $loggedInUser,
                                                               $docID, 
                                                               $text, 0 );
                }
                else {
                    tokenWord::htmlGenerator::generateFailedPurchasePage(
                                                               $loggedInUser,
                                                               $loggedInUser,
                                                               $docID,
                                                               $amount );
                }
            }
        }
        elsif( $action eq "showDocument" ) {
        
            my $docOwner = $cgiQuery->param( "docOwner" ) || '';
            
            # might equal 0
            my $docID = $cgiQuery->param( "docID" );
            

            #untaint
            ( $docOwner ) = ( $docOwner =~ /(\w+)/ );
            ( $docID ) = ( $docID =~ /(\d+)/ );
            
            # make sure it exists
            if( tokenWord::documentManager::doesDocumentExist( $docOwner,
                                                               $docID ) ) {

                #first, purchase the document
                ( my $success, my $amount ) =
                  tokenWord::userWorkspace::purchaseDocument( $loggedInUser,
                                                              $docOwner,
                                                              $docID );
                if( $success ) {
                    my $text = 
                        tokenWord::documentManager::renderDocumentText( 
                                                                  $docOwner, 
                                                                  $docID );
                    # check for highlight
                    
                    # might be 0
                    my $highlightOffset = 
                        $cgiQuery->param( "highlightOffset" );
                    my $highlightLength = 
                        $cgiQuery->param( "highlightLength" );

                    # untaint
                    ( $highlightOffset ) = ( $highlightOffset =~ /(\d+)/ );
                    ( $highlightLength ) = ( $highlightLength =~ /(\d+)/ );

                    if( $highlightLength ne "" and  
                        $highlightOffset ne "" and
                        $highlightLength != 0 ) {

                        tokenWord::htmlGenerator::generateDocHighlightPage( 
                                                            $loggedInUser,
                                                            $docOwner,
                                                            $docID, 
                                                            $text,
                                                            $highlightOffset,
                                                            $highlightLength );
                    }
                    else {
                        # show plain document
                        tokenWord::htmlGenerator::generateDocPage( 
                                                               $loggedInUser,
                                                               $docOwner,
                                                               $docID, $text, 
                                                               0 );
                    }
                }
                else {
                    tokenWord::htmlGenerator::generateFailedPurchasePage(
                                                               $loggedInUser,
                                                               $docOwner,
                                                               $docID,
                                                               $amount );
                  }
            }
            else {
                tokenWord::htmlGenerator::generateErrorPage( 
                                                 $loggedInUser,
                                                 "document does not exist" );
            }
        }
        elsif( $action eq "showDocumentQuotes" ) {
        
            my $docOwner = $cgiQuery->param( "docOwner" ) || '';
            
            # might equal 0
            my $docID = $cgiQuery->param( "docID" );
            

            #untaint
            ( $docOwner ) = ( $docOwner =~ /(\w+)/ );
            ( $docID ) = ( $docID =~ /(\d+)/ );
            
            # make sure it exists
            if( tokenWord::documentManager::doesDocumentExist( $docOwner,
                                                               $docID ) ) {
                #first, purchase the document
                ( my $success, my $amount ) =
                    tokenWord::userWorkspace::purchaseDocument( $loggedInUser,
                                                                $docOwner,
                                                                $docID );

                if( $success ) {
                    my @chunks = 
                        tokenWord::documentManager::getAllChunks( $docOwner,
                                                                  $docID );
            
                    tokenWord::htmlGenerator::generateDocQuotesPage( 
                                                               $loggedInUser,
                                                               $docOwner,
                                                               $docID, 
                                                               @chunks );
                }
                else {
                    tokenWord::htmlGenerator::generateFailedPurchasePage(
                                                               $loggedInUser,
                                                               $docOwner,
                                                               $docID,
                                                               $amount );
                  }
            }
            else {
                tokenWord::htmlGenerator::generateErrorPage( 
                                                 $loggedInUser,
                                                 "document does not exist" );
            }
        }
        elsif( $action eq "listQuotingDocuments" ) {
        
            my $docOwner = $cgiQuery->param( "docOwner" ) || '';
            
            # might equal 0
            my $docID = $cgiQuery->param( "docID" );
            

            #untaint
            ( $docOwner ) = ( $docOwner =~ /(\w+)/ );
            ( $docID ) = ( $docID =~ /(\d+)/ );
            
            # make sure it exists
            if( tokenWord::documentManager::doesDocumentExist( $docOwner,
                                                               $docID ) ) {
                my @quotingDocs = 
                    tokenWord::documentManager::getQuotingDocuments( $docOwner,
                                                                     $docID );
            
                tokenWord::htmlGenerator::generateQuotingDocumentListPage( 
                                                             $loggedInUser,
                                                             $docOwner,
                                                             $docID, 
                                                             @quotingDocs );
            }
            else {
                tokenWord::htmlGenerator::generateErrorPage( 
                                                 $loggedInUser,
                                                 "document does not exist" );
            }
            
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

            # make sure it exists
            if( tokenWord::documentManager::doesDocumentExist( $docOwner,
                                                               $docID ) ) {
                #first, purchase the document
                ( my $success, my $amount ) =
                    tokenWord::userWorkspace::purchaseDocument( $loggedInUser,
                                                                $docOwner,
                                                                $docID );
                if( $success ) {
                    my $text = 
                        tokenWord::documentManager::renderDocumentText( 
                                                                  $docOwner, 
                                                                  $docID );
            
                    tokenWord::htmlGenerator::generateExtractQuoteForm( 
                                                               $loggedInUser,
                                                               $docOwner,
                                                               $docID,
                                                               $text,
                                                               "");
                }
                else {
                    tokenWord::htmlGenerator::generateFailedPurchasePage(
                                                               $loggedInUser,
                                                               $docOwner,
                                                               $docID,
                                                               $amount );
                  }
            }
            else {
                tokenWord::htmlGenerator::generateErrorPage( 
                                                 $loggedInUser,
                                                 "document does not exist" );
            }
        }
        elsif( $action eq "extractQuote" ) {
            my $abstractQuote = $cgiQuery->param( "abstractQuote" ) || '';

            my $docOwner = $cgiQuery->param( "docOwner" ) || '';
            
            # might equal 0
            my $docID = $cgiQuery->param( "docID" );
            

            # untaint
            ( $docOwner ) = ( $docOwner =~ /(\w+)/ );
            ( $docID ) = ( $docID =~ /(\d+)/ );

            if( tokenWord::documentManager::doesDocumentExist( $docOwner,
                                                               $docID ) ) {

                # fix "other" newline style.
                $abstractQuote =~ s/\r/\n/g;
            
            
                # convert non-standard paragraph breaks (with extra whitespace)
                # to newline-newline breaks
                $abstractQuote =~ s/\s*\n\s*\n/\n\n/g;
                
                # since abstract quote string contains entire document
                # text, forcing user to purchase document when extracting
                # quote makes sense

                #first, purchase the document
                ( my $success, my $amount ) =
                    tokenWord::userWorkspace::purchaseDocument( $loggedInUser,
                                                                $docOwner,
                                                                $docID );

                if( $success ) {
                    my $newQuoteID =
                        tokenWord::userWorkspace::extractAbstractQuote( 
                                                              $loggedInUser,
                                                              $docOwner, 
                                                              $docID,
                                                              $abstractQuote );
                    if( $newQuoteID == -1 ) {
                        # failed to extract quote
                        # show form with a message
                        my $text = 
                            tokenWord::documentManager::renderDocumentText(
                                                                  $docOwner, 
                                                                  $docID );
            
                        tokenWord::htmlGenerator::generateExtractQuoteForm( 
                                                               $loggedInUser,
                                                               $docOwner,
                                                               $docID,
                                                               $text,
                                         "quote tags not properly formatted" );
                    }
                    else {
                        # show the new quote list
                        my @quoteList = 
                            tokenWord::quoteClipboard::getAllQuoteRegions( 
                                                              $loggedInUser );
            
                        tokenWord::htmlGenerator::generateQuoteListPage(
                                                              $loggedInUser,
                                                              @quoteList );
                    }
                }
                else {
                    tokenWord::htmlGenerator::generateFailedPurchasePage(
                                                               $loggedInUser,
                                                               $docOwner,
                                                               $docID,
                                                               $amount );
                  }
            }
            else {
                tokenWord::htmlGenerator::generateErrorPage( 
                                                 $loggedInUser,
                                                 "document does not exist" );
            }
        }
        elsif( $action eq "search" ) {
            my $searchTermString = $cgiQuery->param( "terms" ) || '';
            
            my $startTime = Time::HiRes::time();

            my @terms = split( /\s+/, $searchTermString );
            my @matchingDocs = tokenWord::indexSearch::searchIndex( 100,
                                                                    @terms );
            
            my $endTime = Time::HiRes::time();
            my $netTime = $endTime - $startTime;

            my $timeString;
            if( $netTime < 1 ) {
                $netTime = $netTime * 1000;
                $timeString = sprintf( "%.2f milliseconds", $netTime );
            }
            else {
                $timeString = sprintf( "%.2f seconds", $netTime );
            }

            my $docCount = tokenWord::indexSearch::getIndexedDocCount();

            tokenWord::htmlGenerator::generateSearchResultsPage (
                                                            $loggedInUser,
                                                            $searchTermString,
                                                            $docCount,
                                                            $timeString,
                                                            @matchingDocs );
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
                tokenWord::htmlGenerator::generateFailedWithdrawPage(
                                                              $loggedInUser );
              }
        }
        else {
            # show main page
            showMainPage();
        }
    }
}



sub showMainPage {
    
    if( -e "$dataDirectory/users/jcr13/text/documents/2" ) {

        #first, purchase the document
        tokenWord::userWorkspace::purchaseDocument( $loggedInUser,
                                                    "jcr13",
                                                    2 );
        my $text = 
          tokenWord::documentManager::renderDocumentText( "jcr13", 
                                                          2 );
        
        tokenWord::htmlGenerator::generateDocPage( $loggedInUser,
                                                   "jcr13",
                                                   2, $text, 0 );
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

        mkdir( "$dataDirectory/index", oct( "0777" ) );
        mkdir( "$dataDirectory/temp", oct( "0777" ) );

        writeFile( "$dataDirectory/topDocuments/mostQuoted", "" );
        writeFile( "$dataDirectory/topDocuments/mostRecent", "" );
        
        writeFile( "$dataDirectory/index/docCount", "0" );
    }
}
