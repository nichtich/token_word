#!/usr/local/bin/perl -wT

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
# Added cache control.
#
# 2003-January-18   Jason Rohrer
# Added working no-cache directives of two types (Pragma and Cache-control).
# Added highlight of search words.
#
# 2003-January-19   Jason Rohrer
# Set up a local error log.  Changed to work with apnrecords.org server.
# Changed to log user in immediately after account creation.
#
# 2003-February-11   Jason Rohrer
# Added support for backup/restore of data directory as a tarball.
# Added creation of accounting directory.
#
# 2003-April-30   Jason Rohrer
# Changed to use subroutine to check for file existence.
# Changed to use subroutine to make directories.
# Added bypassed file access where appropriate.
# Added function for populating database from a tarball.
#
# 2003-June-1   Jason Rohrer
# Added functions for deleting files.
# Added support for deleting quotes from clipboards.
#
# 2003-June-2   Jason Rohrer
# Added support for extracting multiple quotes with the same operation.
#
# 2003-July-18   Jason Rohrer
# Added per-user toggle of quote display mode.
#
# 2004-October-20   Jason Rohrer
# Added new PayPal IP.
# Added path to make ispell wrapper work (so it can find aspell).
# Added external web and email link support.
#
# 2004-December-3   Jason Rohrer
# Added inline image support.
#
# 2019-September-1   Jakob Voß
# Remove tokenWord_errors.log, use STDERR instead

use lib '.';

use strict;
use CGI;    # Object-Oriented
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
my $paypalFee     = 0.30;

# my $paypalNotifyIP = "65.206.229.140";   # IP of notify.paypal.com
# New IP as of June 11, 2004
my $paypalNotifyIP = "216.113.188.202";

# allow group to write to our data files
umask( oct("02") );

# make sure data directories exist
setupDataDirectory();

my $cgiQuery = CGI->new();

# always set the Pragma: no-cache directive
# this feature seems to be undocumented...
$cgiQuery->cache(1);

my $action = $cgiQuery->param("action") || '';

# get the cookie, if it exists
my $userCookie           = $cgiQuery->cookie("loggedInUser");
my $userSessionIDCookie  = $cgiQuery->cookie("sessionID");
my $userShowQuotesCookie = $cgiQuery->cookie("showQuotes");

my $loggedInUser;
my $sessionID;
my $showQuotes;

if ($userCookie) {
    $loggedInUser = $userCookie;

    # untaint
    ($loggedInUser) = ( $loggedInUser =~ /(\w+)/ );
}
else {
    $loggedInUser = '';
}

if ($userSessionIDCookie) {
    $sessionID = $userSessionIDCookie;

    # untaint
    ($sessionID) = ( $sessionID =~ /(\w+)/ );
}
else {
    $sessionID = '';
}

if ( $userShowQuotesCookie eq 'true' ) {
    $showQuotes = 1;
}
else {
    $showQuotes = 0;
}

# first check for possible paypal notification
my $payerEmail   = $cgiQuery->param("payer_email")   || '';
my $paymentGross = $cgiQuery->param("payment_gross") || '';
my $paypalCustom = $cgiQuery->param("custom")        || '';
my $paymentDate  = $cgiQuery->param("payment_date")  || '';

if ( $payerEmail ne "" and $paymentGross ne "" and $paypalCustom ne "" ) {
    print $cgiQuery->header(
        -type          => 'text/html',
        -expires       => 'now',
        -Cache_control => 'no-cache'
    );

    # we encode the token_word username and num tokens deposited
    # in paypal's custom field
    ( my $user, my $numTokens ) = split( /\|/, $paypalCustom );

    ($user)      = ( $user =~ /(\w+)/ );
    ($numTokens) = ( $numTokens =~ /(\d+)/ );

    if ( $loggedInUser ne "" ) {

        # cookie is here, so this request isn't coming from paypal

        # show main page
        showMainPage();
    }
    else {
        # no cookie, assume request is coming from paypal

        # make sure host address matches

        my $remoteAddress = $cgiQuery->remote_host();

        if ( $remoteAddress eq $paypalNotifyIP ) {

            my $correctEmail = tokenWord::userManager::getPaypalEmail($user);

            my $dollarsAfterFees =
              ( $paymentGross * ( 1 - $paypalPercent ) ) - $paypalFee;

            # round down by one cent
            $dollarsAfterFees = $dollarsAfterFees * 100;
            $dollarsAfterFees = int( $dollarsAfterFees - 1 );
            $dollarsAfterFees = $dollarsAfterFees / 100;

            my $estimatedNumTokens = $dollarsAfterFees * 1000000;

            if ( abs( $estimatedNumTokens - $numTokens ) > 10000 ) {

                # discrepancy between payment and num tokens is more than $0.01

                # note mismatch
                bypass_addToFile(
                    "$dataDirectory/accounting/paymentNotifications",
                    "Payment mismatch:  $paymentDate  $user  "
                      . "$payerEmail  $paymentGross  $numTokens\n"
                );
            }
            elsif ( $correctEmail ne $payerEmail ) {

                # note mismatch
                bypass_addToFile(
                    "$dataDirectory/accounting/paymentNotifications",
                    "Email mismatch:  $paymentDate  $user  "
                      . "$payerEmail  $paymentGross  $numTokens\n"
                );
            }
            else {
                # emails match and token count is close enough, deposit
                tokenWord::userManager::depositTokens( $user, $numTokens );

                # note correct transaction
                bypass_addToFile(
                    "$dataDirectory/accounting/paymentNotifications",
                    "Transaction complete:  $paymentDate  $user  "
                      . "$payerEmail  $paymentGross  $numTokens\n"
                );
            }
        }
        else {
            # remote host does not match what we expect from
            # paypal
            # note this mismatch
            bypass_addToFile( "$dataDirectory/accounting/paymentNotifications",
                    "Bad remote address ($remoteAddress):  "
                  . "$paymentDate  $user  "
                  . "$payerEmail  $paymentGross  $numTokens\n" );
        }
    }
}
elsif ( $action eq "getDataTarball" ) {
    my $password = $cgiQuery->param("password") || '';

    my $truePassword = bypass_readFileValue("$dataDirectory/admin.pass");

    if ( $password eq $truePassword ) {

        print $cgiQuery->header(
            -type          => 'application-x/gzip',
            -expires       => 'now',
            -Cache_control => 'no-cache'
        );
        my $oldPath = $ENV{"PATH"};
        $ENV{"PATH"} = "";

        open( TARBALL_READER,
"cd $dataDirectory/..; /bin/tar cf - $dataDirectoryName | /bin/gzip -f |"
        );
        while (<TARBALL_READER>) {
            print "$_";
        }
        close(TARBALL_READER);

        $ENV{"PATH"} = $oldPath;
    }
    else {
        print $cgiQuery->header(
            -type          => 'text/html',
            -expires       => 'now',
            -Cache_control => 'no-cache'
        );
        print "access denied";
    }
}
elsif ( $action eq "makeDataTarball" ) {
    my $password = $cgiQuery->param("password") || '';

    my $truePassword = bypass_readFileValue("$dataDirectory/admin.pass");

    if ( $password eq $truePassword ) {

        print $cgiQuery->header(
            -type          => 'text/html',
            -expires       => 'now',
            -Cache_control => 'no-cache'
        );
        my $oldPath = $ENV{"PATH"};
        $ENV{"PATH"} = "";

        my $outcome =
`cd $dataDirectory/..; /bin/tar cf - $dataDirectoryName | /bin/gzip -f > $dataDirectoryName.tar.gz`;

        print "Outcome = $outcome <BR>(blank indicates no error)";

        $ENV{"PATH"} = $oldPath;
    }
    else {
        print $cgiQuery->header(
            -type          => 'text/html',
            -expires       => 'now',
            -Cache_control => 'no-cache'
        );
        print "access denied";
    }
}
elsif ( $action eq "refreshFromDataTarball" ) {
    my $password = $cgiQuery->param("password") || '';

    my $truePassword = bypass_readFileValue("$dataDirectory/admin.pass");

    if ( $password eq $truePassword ) {

        print $cgiQuery->header(
            -type          => 'text/html',
            -expires       => 'now',
            -Cache_control => 'no-cache'
        );
        my $oldPath = $ENV{"PATH"};
        $ENV{"PATH"} = "";

        my $outcome =
`cd $dataDirectory/..; /bin/rm -r $dataDirectoryName; /bin/cat ./$dataDirectoryName.tar.gz | /bin/gzip -d - | /bin/tar xf -`;

        print "Outcome = $outcome <BR>(blank indicates no error)";

        $ENV{"PATH"} = $oldPath;
    }
    else {
        print $cgiQuery->header(
            -type          => 'text/html',
            -expires       => 'now',
            -Cache_control => 'no-cache'
        );
        print "access denied";
    }
}
elsif ( $action eq "updateDatabaseFromDataTarball" ) {
    my $password = $cgiQuery->param("password") || '';

    my $truePassword = bypass_readFileValue("$dataDirectory/admin.pass");

    if ( $password eq $truePassword ) {

        print $cgiQuery->header(
            -type          => 'text/html',
            -expires       => 'now',
            -Cache_control => 'no-cache'
        );

        updateDatabaseFromDataTarball();
    }
    else {
        print $cgiQuery->header(
            -type          => 'text/html',
            -expires       => 'now',
            -Cache_control => 'no-cache'
        );
        print "access denied";
    }
}
elsif ( $action eq "createUserForm" ) {
    print $cgiQuery->header(
        -type          => 'text/html',
        -expires       => 'now',
        -Cache_control => 'no-cache'
    );
    tokenWord::htmlGenerator::generateCreateUserForm("");
}
elsif ( $action eq "createUser" ) {
    my $user        = $cgiQuery->param("user")        || '';
    my $password    = $cgiQuery->param("password")    || '';
    my $paypalEmail = $cgiQuery->param("paypalEmail") || '';

    #untaint
    ($user)        = ( $user =~ /(\w+)/ );
    ($password)    = ( $password =~ /(\w+)/ );
    ($paypalEmail) = ( $paypalEmail =~ /(\S+@\S+)/ );

    if ( $user eq '' ) {
        print $cgiQuery->header(
            -type          => 'text/html',
            -expires       => 'now',
            -Cache_control => 'no-cache'
        );
        tokenWord::htmlGenerator::generateCreateUserForm("invalid username");
    }
    elsif ( length($password) < 4 ) {
        print $cgiQuery->header(
            -type          => 'text/html',
            -expires       => 'now',
            -Cache_control => 'no-cache'
        );
        tokenWord::htmlGenerator::generateCreateUserForm(
            "password must be at least 4 characters long");
    }
    elsif ( not( $paypalEmail =~ /\S+@\S+/ ) ) {
        print $cgiQuery->header(
            -type          => 'text/html',
            -expires       => 'now',
            -Cache_control => 'no-cache'
        );
        tokenWord::htmlGenerator::generateCreateUserForm(
            "invalid email address");
    }
    else {
        my $success =
          tokenWord::userManager::addUser( $user, $password, $paypalEmail,
            50000 );

        if ( not $success ) {
            print $cgiQuery->header(
                -type          => 'text/html',
                -expires       => 'now',
                -Cache_control => 'no-cache'
            );
            tokenWord::htmlGenerator::generateCreateUserForm(
                "username already exists");
        }
        else {
            # the user has been created...
            # set cookie and show the main page (same as code
            # for user login)

            my $userCookie = $cgiQuery->cookie(
                -name    => "loggedInUser",
                -value   => "$user",
                -expires => '+1h'
            );

            # take the MD5 hash of the username, password,
            # and current system time
            my $md5 = new MD5;
            $md5->add( $user, $password, time() );
            my $newSessionID = $md5->hexdigest();

            my $sessionIDCookie = $cgiQuery->cookie(
                -name    => "sessionID",
                -value   => "$newSessionID",
                -expires => '+1h'
            );

            # default to hide quotes mode
            my $showQuotesCookie = $cgiQuery->cookie(
                -name    => "showQuotes",
                -value   => "false",
                -expires => '+1h'
            );
            print $cgiQuery->header(
                -type          => 'text/html',
                -expires       => 'now',
                -Cache_control => 'no-cache',
                -cookie => [ $userCookie, $sessionIDCookie, $showQuotesCookie ]
            );
            $loggedInUser = $user;

            # save the new session ID
            writeFile( "$dataDirectory/users/$user/sessionID", $newSessionID );

            showMainPage();
        }
    }
}
elsif ( $action eq "loginForm" ) {
    print $cgiQuery->header(
        -type          => 'text/html',
        -expires       => 'now',
        -Cache_control => 'no-cache'
    );
    tokenWord::htmlGenerator::generateLoginForm("");
}
elsif ( $action eq "login" ) {
    my $user     = $cgiQuery->param("user")     || '';
    my $password = $cgiQuery->param("password") || '';

    #untaint
    ($user)     = ( $user =~ /(\w+)/ );
    ($password) = ( $password =~ /(\w+)/ );

    my $correct = tokenWord::userManager::checkLogin( $user, $password );

    if ( not $correct ) {
        print $cgiQuery->header(
            -type          => 'text/html',
            -expires       => 'now',
            -Cache_control => 'no-cache'
        );
        tokenWord::htmlGenerator::generateLoginForm("login failed");
    }
    else {
        my $userCookie = $cgiQuery->cookie(
            -name    => "loggedInUser",
            -value   => "$user",
            -expires => '+1h'
        );

        # take the MD5 hash of the username, password,
        # and current system time
        my $md5 = new MD5;
        $md5->add( $user, $password, time() );
        my $newSessionID = $md5->hexdigest();

        my $sessionIDCookie = $cgiQuery->cookie(
            -name    => "sessionID",
            -value   => "$newSessionID",
            -expires => '+1h'
        );

        # default to hide quotes mode
        my $showQuotesCookie = $cgiQuery->cookie(
            -name    => "showQuotes",
            -value   => "false",
            -expires => '+1h'
        );

        print $cgiQuery->header(
            -type          => 'text/html',
            -expires       => 'now',
            -Cache_control => 'no-cache',
            -cookie => [ $userCookie, $sessionIDCookie, $showQuotesCookie ]
        );
        $loggedInUser = $user;

        # save the new session ID
        writeFile( "$dataDirectory/users/$user/sessionID", $newSessionID );

        showMainPage();
    }
}
elsif ( $action eq "logout" ) {
    my $userCookie = $cgiQuery->cookie(
        -name  => "loggedInUser",
        -value => ""
    );
    my $sessionIDCookie = $cgiQuery->cookie(
        -name  => "sessionID",
        -value => ""
    );
    my $showQuotesCookie = $cgiQuery->cookie(
        -name    => "showQuotes",
        -value   => "",
        -expires => '+1h'
    );

    print $cgiQuery->header(
        -type          => 'text/html',
        -expires       => 'now',
        -Cache_control => 'no-cache',
        -cookie        => [ $userCookie, $sessionIDCookie, $showQuotesCookie ]
    );

    # leave the old sessionID file in place

    if ( $loggedInUser ne '' ) {
        tokenWord::htmlGenerator::generateLoginForm(
            "$loggedInUser has logged out\n");
    }
    else {
        tokenWord::htmlGenerator::generateLoginForm("");
    }
}
else {

    if ( $loggedInUser eq '' ) {

        print $cgiQuery->header(
            -type          => 'text/html',
            -expires       => 'now',
            -Cache_control => 'no-cache'
        );

        tokenWord::htmlGenerator::generateLoginForm("");
    }
    elsif ( doesFileExist("$dataDirectory/users/$loggedInUser/sessionID")
        and $sessionID ne
        readFileValue("$dataDirectory/users/$loggedInUser/sessionID") )
    {

        # bad session ID returned in cookie
        print $cgiQuery->header(
            -type          => 'text/html',
            -expires       => 'now',
            -Cache_control => 'no-cache'
        );

        tokenWord::htmlGenerator::generateLoginForm("");
    }
    elsif ( not doesFileExist("$dataDirectory/users/$loggedInUser/sessionID") )
    {
        # session ID file does not exist
        print $cgiQuery->header(
            -type          => 'text/html',
            -expires       => 'now',
            -Cache_control => 'no-cache'
        );

        tokenWord::htmlGenerator::generateLoginForm("");
    }
    else {
        # session ID returned in cookie is correct

        # send back a new cookie to keep the user logged in longer
        my $userCookie = $cgiQuery->cookie(
            -name    => "loggedInUser",
            -value   => "$loggedInUser",
            -expires => '+1h'
        );
        my $sessionIDCookie = $cgiQuery->cookie(
            -name    => "sessionID",
            -value   => "$sessionID",
            -expires => '+1h'
        );

        my $showQuotesCookieValue;

        if ( $action eq "showDocumentQuotes" ) {
            $showQuotesCookieValue = "true";
            $showQuotes            = 1;
        }
        elsif ( $action eq "hideDocumentQuotes" ) {
            $showQuotesCookieValue = "false";
            $showQuotes            = 0;
        }
        else {
            # retain old value
            $showQuotesCookieValue = "$userShowQuotesCookie";
        }

        my $showQuotesCookie = $cgiQuery->cookie(
            -name    => "showQuotes",
            -value   => "$showQuotesCookieValue",
            -expires => '+1h'
        );

        print $cgiQuery->header(
            -type          => 'text/html',
            -expires       => 'now',
            -Cache_control => 'no-cache',
            -cookie => [ $userCookie, $sessionIDCookie, $showQuotesCookie ]
        );

        # switch action to show document quotes if show quote mode is on
        # and highlights are off
        my $highlightOn          = 0;
        my $highlightWordsString = $cgiQuery->param("highlightWords") || '';
        my $highlightLength      = $cgiQuery->param("highlightLength") || '';

        if ( $highlightWordsString ne "" or $highlightLength ne "" ) {
            $highlightOn = 1;
            print "highlight is on<BR>";
        }

        if ( $showQuotes and not $highlightOn ) {
            if ( $action eq "showDocument" ) {

                # switch action
                $action = "showDocumentQuotes";
            }
        }

        if ( $action eq "test" ) {
            print "test for user $loggedInUser\n";
        }
        elsif ( $action eq "feedbackForm" ) {
            tokenWord::htmlGenerator::generateFeedbackForm($loggedInUser);
        }
        elsif ( $action eq "feedback" ) {
            my $message = $cgiQuery->param("message") || '';

            bypass_addToFile( "$dataDirectory/feedback",
                "$loggedInUser :\n$message\n\n" );

            showMainPage();
        }
        elsif ( $action eq "createDocumentForm" ) {
            tokenWord::htmlGenerator::generateCreateDocumentForm( $loggedInUser,
                0, "", "", 0 );
        }
        elsif ( $action eq "createDocument" ) {
            my $buttonSubmit  = $cgiQuery->param("buttonSubmit")  || '';
            my $buttonPreview = $cgiQuery->param("buttonPreview") || '';
            my $abstractDoc   = $cgiQuery->param("abstractDoc")   || '';

            if ( $buttonPreview ne "" ) {

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
                    $loggedInUser, $abstractDoc );

                # add any external web links (plain http:// URLS)
                # search for http:// followed by a string of non-whitespace
                $docTextPreview =~
s/[^\!](http:\/\/\S+)/<A HREF=\"$1\" TARGET="_blank"><FONT COLOR=#00BF00>$1<\/FONT><\/A>/gi;

                # add any inline image links ( !http:// URLS)
                # search for !http:// followed by a string of non-whitespace
                $docTextPreview =~ s/\!(http:\/\/\S+)/<IMG SRC=\"$1\">/gi;

                # add any email address links
                # search for two strings of non-whitespace separated by @
                $docTextPreview =~
s/(\S+@\S+)/<A HREF=\"mailto:$1\"><FONT COLOR=#00BF00>$1<\/FONT><\/A>/gi;

                my @misspelledWords = ();

                my $spellCheck = $cgiQuery->param("spellCheck") || '';
                my $spellCheckOn = 0;

                if ( $spellCheck eq "1" ) {
                    $spellCheckOn = 1;

                    # take MD5 of doc text to get a unique temp file name
                    my $md5 = new MD5;
                    $md5->add($docTextPreview);
                    my $fileName = $md5->hexdigest();

                    my $filePath = "$dataDirectory/temp/$fileName";

                    bypass_writeFile( $filePath, $docTextPreview );

                    # find ispell program, either global or local
                    my $ispellCommand;

                    if ( -e "/usr/bin/ispell" ) {
                        $ispellCommand = "/usr/bin/ispell -l";
                    }
                    else {
                        # use local ispell install
                        $ispellCommand = "./ispell -l -d ./english.hash";
                    }

                    # call ispell... this is a safe use of the shell
                    # untaint and later restore PATH
                    my $oldPath = $ENV{"PATH"};

                    # set path so that ispell can find aspell if it needs to
                    $ENV{"PATH"} = "/usr/bin";

                    my $misspelled = `/bin/cat ./$filePath | $ispellCommand`;

                    $ENV{"PATH"} = $oldPath;

                    # delete temp file
                    bypass_deleteFile($filePath);

                    @misspelledWords = split( /\s+/, $misspelled );

                    # replace misspelled words with red versions
                    foreach my $word (@misspelledWords) {
                        my $redWord = "<FONT COLOR=#FF0000>$word</FONT>";

                        # make sure we only replace those that have
                        # not yet been replaced.
                        $docTextPreview =~ s/([^>])$word([^<])/$1$redWord$2/;
                    }

                }

                tokenWord::htmlGenerator::generateCreateDocumentForm(
                    $loggedInUser, 1, $docTextPreview, $abstractDoc,
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
                    $loggedInUser, $abstractDoc );
                my $text =
                  tokenWord::documentManager::renderDocumentText( $loggedInUser,
                    $docID );

                # add to index
                tokenWord::indexSearch::addToIndex( $loggedInUser, $docID,
                    $text );

                # show the new document

                # still need to purchase it, just incase quoted material
                # is not owned yet
                ( my $success, my $amount ) =
                  tokenWord::userWorkspace::purchaseDocument( $loggedInUser,
                    $loggedInUser, $docID );
                if ($success) {
                    tokenWord::htmlGenerator::generateDocPage( $loggedInUser,
                        $loggedInUser, $docID, $text, 0 );
                }
                else {
                    tokenWord::htmlGenerator::generateFailedPurchasePage(
                        $loggedInUser, $loggedInUser, $docID, $amount );
                }
            }
        }
        elsif ( $action eq "showDocument" or $action eq "hideDocumentQuotes" ) {

            my $docOwner = $cgiQuery->param("docOwner") || '';

            # might equal 0
            my $docID = $cgiQuery->param("docID");

            #untaint
            ($docOwner) = ( $docOwner =~ /(\w+)/ );
            ($docID)    = ( $docID =~ /(\d+)/ );

            # make sure it exists
            if (
                tokenWord::documentManager::doesDocumentExist(
                    $docOwner, $docID
                )
              )
            {

                #first, purchase the document
                ( my $success, my $amount ) =
                  tokenWord::userWorkspace::purchaseDocument( $loggedInUser,
                    $docOwner, $docID );
                if ($success) {
                    my $text =
                      tokenWord::documentManager::renderDocumentText( $docOwner,
                        $docID );

                    # add any external web links (plain http:// URLS)
                    # search for http:// followed by a string of non-whitespace
                    $text =~
s/[^\!](http:\/\/\S+)/<A HREF=\"$1\" TARGET="_blank"><FONT COLOR=#00BF00>$1<\/FONT><\/A>/gi;

                    # add any inline image links ( !http:// URLS)
                    # search for !http:// followed by a string of
                    # non-whitespace
                    $text =~ s/\!(http:\/\/\S+)/<IMG SRC=\"$1\">/gi;

                    # add any email address links
                    # search for two strings of non-whitespace separated by @
                    $text =~
s/(\S+@\S+)/<A HREF=\"mailto:$1\"><FONT COLOR=#00BF00>$1<\/FONT><\/A>/gi;

                    my $highlightWordsString =
                      $cgiQuery->param("highlightWords") || '';

                    # 0 for non-highlight-word mode
                    my $highlightWordFlag = 0;

                    if ( $highlightWordsString ne "" ) {

                        # 3 for highlight word mode
                        $highlightWordFlag = 3;

                        # we can stick single-word highlights right
                        # into the doc text
                        # This does not work for region highlights,
                        # so we handle those differently below.

                        my @highlightWords =
                          split( /\s+/, $highlightWordsString );

                        # replace highlight words with red versions
                        foreach my $word (@highlightWords) {
                            my $redWord    = "<FONT COLOR=#FF0000>$word</FONT>";
                            my $colorStart = "<FONT COLOR=#FF0000>";
                            my $colorEnd   = "</FONT>";

                            # make sure we only highlight true words
                            # case insensitive
                            # preserve case on replacement
                            $text =~
                              s/(\W+)($word)(\W+)/$1$colorStart$2$colorEnd$3/gi;
                        }
                    }

                    # check for region highlight

                    # might be 0
                    my $highlightOffset = $cgiQuery->param("highlightOffset");
                    my $highlightLength = $cgiQuery->param("highlightLength");

                    # untaint
                    ($highlightOffset) = ( $highlightOffset =~ /(\d+)/ );
                    ($highlightLength) = ( $highlightLength =~ /(\d+)/ );

                    if (    $highlightLength ne ""
                        and $highlightOffset ne ""
                        and $highlightLength != 0 )
                    {

                        tokenWord::htmlGenerator::generateDocHighlightPage(
                            $loggedInUser, $docOwner, $docID, $text,
                            $highlightOffset, $highlightLength );
                    }
                    else {
                        # show plain document, maybe with highlighted words
                        tokenWord::htmlGenerator::generateDocPage(
                            $loggedInUser, $docOwner, $docID, $text,
                            $highlightWordFlag );
                    }
                }
                else {
                    tokenWord::htmlGenerator::generateFailedPurchasePage(
                        $loggedInUser, $docOwner, $docID, $amount );
                }
            }
            else {
                tokenWord::htmlGenerator::generateErrorPage( $loggedInUser,
                    "document does not exist" );
            }
        }
        elsif ( $action eq "showDocumentQuotes" ) {

            my $docOwner = $cgiQuery->param("docOwner") || '';

            # might equal 0
            my $docID = $cgiQuery->param("docID");

            #untaint
            ($docOwner) = ( $docOwner =~ /(\w+)/ );
            ($docID)    = ( $docID =~ /(\d+)/ );

            # make sure it exists
            if (
                tokenWord::documentManager::doesDocumentExist(
                    $docOwner, $docID
                )
              )
            {
                #first, purchase the document
                ( my $success, my $amount ) =
                  tokenWord::userWorkspace::purchaseDocument( $loggedInUser,
                    $docOwner, $docID );

                if ($success) {
                    my @chunks =
                      tokenWord::documentManager::getAllChunks( $docOwner,
                        $docID );

                    tokenWord::htmlGenerator::generateDocQuotesPage(
                        $loggedInUser, $docOwner, $docID, @chunks );
                }
                else {
                    tokenWord::htmlGenerator::generateFailedPurchasePage(
                        $loggedInUser, $docOwner, $docID, $amount );
                }
            }
            else {
                tokenWord::htmlGenerator::generateErrorPage( $loggedInUser,
                    "document does not exist" );
            }
        }
        elsif ( $action eq "listQuotingDocuments" ) {

            my $docOwner = $cgiQuery->param("docOwner") || '';

            # might equal 0
            my $docID = $cgiQuery->param("docID");

            #untaint
            ($docOwner) = ( $docOwner =~ /(\w+)/ );
            ($docID)    = ( $docID =~ /(\d+)/ );

            # make sure it exists
            if (
                tokenWord::documentManager::doesDocumentExist(
                    $docOwner, $docID
                )
              )
            {
                my @quotingDocs =
                  tokenWord::documentManager::getQuotingDocuments( $docOwner,
                    $docID );

                tokenWord::htmlGenerator::generateQuotingDocumentListPage(
                    $loggedInUser, $docOwner, $docID, @quotingDocs );
            }
            else {
                tokenWord::htmlGenerator::generateErrorPage( $loggedInUser,
                    "document does not exist" );
            }

        }
        elsif ( $action eq "showQuoteList" ) {
            my @quoteList =
              tokenWord::quoteClipboard::getAllQuoteRegions($loggedInUser);

            tokenWord::htmlGenerator::generateQuoteListPage( $loggedInUser,
                @quoteList );
        }
        elsif ( $action eq "deleteQuotes" ) {

            # quoteNumber parameter might occur multiple times, once for
            # each quote that is flagged for deletion.
            my @quoteNumbersToDelete = $cgiQuery->param("quoteNumber");

            if ( scalar(@quoteNumbersToDelete) > 0 ) {
                foreach my $quoteNumber (@quoteNumbersToDelete) {
                    tokenWord::quoteClipboard::deleteQuote( $loggedInUser,
                        $quoteNumber );
                }
            }

            # now show quote list
            my @quoteList =
              tokenWord::quoteClipboard::getAllQuoteRegions($loggedInUser);

            tokenWord::htmlGenerator::generateQuoteListPage( $loggedInUser,
                @quoteList );
        }
        elsif ( $action eq "extractQuoteForm" ) {
            my $docOwner = $cgiQuery->param("docOwner") || '';

            # might equal 0
            my $docID = $cgiQuery->param("docID");

            #untaint
            ($docOwner) = ( $docOwner =~ /(\w+)/ );
            ($docID)    = ( $docID =~ /(\d+)/ );

            # make sure it exists
            if (
                tokenWord::documentManager::doesDocumentExist(
                    $docOwner, $docID
                )
              )
            {
                #first, purchase the document
                ( my $success, my $amount ) =
                  tokenWord::userWorkspace::purchaseDocument( $loggedInUser,
                    $docOwner, $docID );
                if ($success) {
                    my $text =
                      tokenWord::documentManager::renderDocumentText( $docOwner,
                        $docID );

                    tokenWord::htmlGenerator::generateExtractQuoteForm(
                        $loggedInUser, $docOwner, $docID, $text, "" );
                }
                else {
                    tokenWord::htmlGenerator::generateFailedPurchasePage(
                        $loggedInUser, $docOwner, $docID, $amount );
                }
            }
            else {
                tokenWord::htmlGenerator::generateErrorPage( $loggedInUser,
                    "document does not exist" );
            }
        }
        elsif ( $action eq "extractQuote" ) {
            my $abstractQuote = $cgiQuery->param("abstractQuote") || '';

            my $docOwner = $cgiQuery->param("docOwner") || '';

            # might equal 0
            my $docID = $cgiQuery->param("docID");

            # untaint
            ($docOwner) = ( $docOwner =~ /(\w+)/ );
            ($docID)    = ( $docID =~ /(\d+)/ );

            if (
                tokenWord::documentManager::doesDocumentExist(
                    $docOwner, $docID
                )
              )
            {

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
                    $docOwner, $docID );

                if ($success) {
                    my @newQuoteIDs =
                      tokenWord::userWorkspace::extractAbstractQuotes(
                        $loggedInUser, $docOwner, $docID, $abstractQuote );
                    if ( $newQuoteIDs[0] == -1 ) {

                        # failed to extract quote
                        # show form with a message
                        my $text =
                          tokenWord::documentManager::renderDocumentText(
                            $docOwner, $docID );

                        tokenWord::htmlGenerator::generateExtractQuoteForm(
                            $loggedInUser, $docOwner, $docID, $text,
                            "quote tags not properly formatted" );
                    }
                    else {
                        # show the new quote list
                        my @quoteList =
                          tokenWord::quoteClipboard::getAllQuoteRegions(
                            $loggedInUser);

                        tokenWord::htmlGenerator::generateQuoteListPage(
                            $loggedInUser, @quoteList );
                    }
                }
                else {
                    tokenWord::htmlGenerator::generateFailedPurchasePage(
                        $loggedInUser, $docOwner, $docID, $amount );
                }
            }
            else {
                tokenWord::htmlGenerator::generateErrorPage( $loggedInUser,
                    "document does not exist" );
            }
        }
        elsif ( $action eq "search" ) {
            my $searchTermString = $cgiQuery->param("terms") || '';

            my $startTime = Time::HiRes::time();

            my @terms = split( /\s+/, $searchTermString );
            my @matchingDocs =
              tokenWord::indexSearch::searchIndex( 100, @terms );

            my $endTime = Time::HiRes::time();
            my $netTime = $endTime - $startTime;

            my $timeString;
            if ( $netTime < 1 ) {
                $netTime = $netTime * 1000;
                $timeString = sprintf( "%.2f milliseconds", $netTime );
            }
            else {
                $timeString = sprintf( "%.2f seconds", $netTime );
            }

            my $docCount = tokenWord::indexSearch::getIndexedDocCount();

            tokenWord::htmlGenerator::generateSearchResultsPage(
                $loggedInUser, $searchTermString, $docCount,
                $timeString,   @matchingDocs
            );
        }
        elsif ( $action eq "deposit" ) {

            my $tokenCount = $cgiQuery->param("tokenCount") || '';

            #untaint
            ($tokenCount) = ( $tokenCount =~ /(\d+)/ );

            my $dollarAmount = $tokenCount / 1000000;

            my $netDollarPayment =
              ( $dollarAmount + $paypalFee ) / ( 1.0 - $paypalPercent );

            # round up to nearest whole cent value
            $netDollarPayment = ( $netDollarPayment * 100 ) + 1;
            $netDollarPayment = int($netDollarPayment);
            $netDollarPayment = $netDollarPayment / 100.0;

            my $paypalEmail =
              tokenWord::userManager::getPaypalEmail($loggedInUser);

            tokenWord::htmlGenerator::generateDepositConfirmPage(
                $loggedInUser,     $tokenCount, $dollarAmount,
                $netDollarPayment, $paypalEmail
            );
        }
        elsif ( $action eq "withdraw" ) {

            my $tokenCount = $cgiQuery->param("tokenCount") || '';

            #untaint
            ($tokenCount) = ( $tokenCount =~ /(\d+)/ );

            my $dollarAmount = $tokenCount / 1000000;

            my $netDollarRefund = $dollarAmount;

            # round downto nearest whole cent value
            $netDollarRefund = ( $netDollarRefund * 100 );
            $netDollarRefund = int($netDollarRefund);
            $netDollarRefund = $netDollarRefund / 100.0;

            my $paypalEmail =
              tokenWord::userManager::getPaypalEmail($loggedInUser);

            tokenWord::htmlGenerator::generateWithdrawConfirmPage(
                $loggedInUser,    $tokenCount, $dollarAmount,
                $netDollarRefund, $paypalEmail
            );
        }
        elsif ( $action eq "confirmedWithdraw" ) {

            my $tokenCount = $cgiQuery->param("tokenCount") || '';

            #untaint
            ($tokenCount) = ( $tokenCount =~ /(\d+)/ );

            my $dollarAmount = $tokenCount / 1000000;

            my $netDollarRefund = $dollarAmount;

            # round downto nearest whole cent value
            $netDollarRefund = ( $netDollarRefund * 100 );
            $netDollarRefund = int($netDollarRefund);
            $netDollarRefund = $netDollarRefund / 100.0;

            my $paypalEmail =
              tokenWord::userManager::getPaypalEmail($loggedInUser);

            my $success =
              tokenWord::userManager::withdrawTokens( $loggedInUser,
                $tokenCount );

            if ($success) {
                bypass_addToFile( "$dataDirectory/accounting/pendingPayments",
                        "$loggedInUser  $paypalEmail"
                      . "  $tokenCount  $netDollarRefund" );
                showMainPage();
            }
            else {
                tokenWord::htmlGenerator::generateFailedWithdrawPage(
                    $loggedInUser);
            }
        }
        else {
            # show main page
            showMainPage();
        }
    }
}

sub showMainPage {

    if ( doesFileExist("$dataDirectory/users/jcr13/text/documents/2") ) {

        #first, purchase the document
        tokenWord::userWorkspace::purchaseDocument( $loggedInUser, "jcr13", 2 );
        my $text = tokenWord::documentManager::renderDocumentText( "jcr13", 2 );

        tokenWord::htmlGenerator::generateDocPage( $loggedInUser,
            "jcr13", 2, $text, 0 );
    }
    else {
        tokenWord::htmlGenerator::generateMainPage($loggedInUser);
    }
}

sub setupDataDirectory {
    if ( not -e "$dataDirectory" ) {

        bypass_makeDirectory( "$dataDirectory", oct("0777") );

        makeDirectory( "$dataDirectory/users", oct("0777") );

        makeDirectory( "$dataDirectory/topDocuments", oct("0777") );

        makeDirectory( "$dataDirectory/index", oct("0777") );

        writeFile( "$dataDirectory/topDocuments/mostQuoted", "" );
        writeFile( "$dataDirectory/topDocuments/mostRecent", "" );

        writeFile( "$dataDirectory/index/docCount", "0" );

        # these must be real directories
        bypass_makeDirectory( "$dataDirectory/temp",       oct("0777") );
        bypass_makeDirectory( "$dataDirectory/accounting", oct("0777") );

        bypass_writeFile( "$dataDirectory/admin.pass", "changeme" );
    }
}
