package tokenWord::htmlGenerator;

#
# Modification History
#
# 2003-January-8   Jason Rohrer
# Created.
#
# 2003-January-14   Jason Rohrer
# Added missing comments.
# Added support for most recent and most quoted lists.
#
# 2003-January-15   Jason Rohrer
# Added support for deposit page.
# Added support for withdraw page.
# Added support for paypal instant payment notification.
#
# 2003-January-16   Jason Rohrer
# Added support for trial balances.
# Added a failed withdraw page.
# Added document preview.
# Improved layout of most- lists.
# Added support for error page.
# Added a feedback form.
# Added support for document highlights.
# Added display of search results.
# Added a spell checker.
# Changed to highlight-only spell checking display.
# Enabled highlights in links on quote clipboard.
#
# 2003-January-18   Jason Rohrer
# Added display of quote count in search results list.
# Added highlight of search words.
#


use tokenWord::common;
use tokenWord::userManager;
use tokenWord::chunkManager;



##
# Generates a generic page header with no control bars.
#
# @param0 the title of the page.
##
sub generateHeader {
    ( my $title ) = @_;

    my $headerText = readFileValue( "$htmlDirectory/header.html" );

    $headerText =~ s/<!--#TITLE-->/$title/;
    
    print $headerText;
}



##
# Generates a generic page footer with no control bars.
##
sub generateFooter {

    my $footerText = readFileValue( "$htmlDirectory/footer.html" );

    print $footerText;
}




##
# Generates a full page header for a page with control bars.
#
# @param0 the title of the page.
##
sub generateFullHeader {
    ( my $title ) = @_;

    generateHeader( $title );

    my $headerText = readFileValue( "$htmlDirectory/fullHeader.html" );
    
    print $headerText;
}



##
# Generates a full page footer for a page with control bars.
#
# @param0 the currently logged-in user.
##
sub generateFullFooter {
    ( my $loggedInUser ) = @_;
    
    generateFooter();

    my $balance = tokenWord::userManager::getBalance( $loggedInUser );
    my $trialBalance = 
      tokenWord::userManager::getTrialBalance( $loggedInUser );

    
    
    my $footerText = readFileValue( "$htmlDirectory/fullFooter.html" );
    
    $footerText =~ s/<!--#USER-->/$loggedInUser/;
    $footerText =~ s/<!--#TOKEN_BALANCE-->/$balance/;
    $footerText =~ s/<!--#TRIAL_TOKEN_BALANCE-->/$trialBalance/;

    # generate most quoted list
    my @mostQuoted = tokenWord::documentManager::getMostQuotedDocuments();
    
    my @mostQuotedStrings = ();
    
    # push table header
    push( @mostQuotedStrings, "<TABLE BORDER=0>\n" );
    
    foreach $quoted ( @mostQuoted ) {
        ( my $doc, $count ) = split( /\|/, $quoted );
        my @docRegions = extractRegionComponents( $doc );
        my $docOwner = $docRegions[0];
        my $docID = $docRegions[1];

        my $docTitle = tokenWord::documentManager::getDocTitle( $docOwner,
                                                                $docID );
        if( length( $docTitle ) > 20 ) {
            $docTitle = substr( $docTitle, 0, 17 );
            $docTitle = "$docTitle...";
        }
        my $quotedString =
            "<TR><TD>$docOwner\'s</TD>".
            "<TD><A HREF=\"tokenWord.pl?action=showDocument".
            "&docOwner=$docOwner".
            "&docID=$docID\">".
            "$docTitle</A></TD>".
            "<TD>[$count]</TD></TR>\n";
        push( @mostQuotedStrings, $quotedString );
    }

    if( scalar( @mostQuoted ) == 0 ) {
        push( @mostQuotedStrings, "<TR><TD>none</TD></TR>" );
    }

    # push table footer
    push( @mostQuotedStrings, "</TABLE>\n" );
    
    my $mostQuotedList = join( "", @mostQuotedStrings );
    
    $footerText =~ s/<!--#MOST_QUOTED_DOCUMENT_LIST-->/$mostQuotedList/;


    # generate most recent list
    my @mostRecent = tokenWord::documentManager::getMostRecentDocuments();
    
    my @mostRecentStrings = ();
    
    # push table header
    push( @mostRecentStrings, "<TABLE BORDER=0>\n" );
    
    foreach $doc ( @mostRecent ) {
        my @docRegions = extractRegionComponents( $doc );
        my $docOwner = $docRegions[0];
        my $docID = $docRegions[1];

        my $docTitle = tokenWord::documentManager::getDocTitle( $docOwner,
                                                                $docID );
        if( length( $docTitle ) > 20 ) {
            $docTitle = substr( $docTitle, 0, 17 );
            $docTitle = "$docTitle...";
        }
        my $recentString =
            "<TR><TD>$docOwner\'s</TD>".
            "<TD><A HREF=\"tokenWord.pl?action=showDocument".
            "&docOwner=$docOwner".
            "&docID=$docID\">".
            "$docTitle</A></TD></TR>\n";
        push( @mostRecentStrings, $recentString );
    }

    if( scalar( @mostRecent ) == 0 ) {
        push( @mostRecentStrings, "<TR><TD>none</TD></TR>" );
    }

    # push table footer
    push( @mostRecentStrings, "</TABLE>\n" );
    
    my $mostRecentList = join( "", @mostRecentStrings );
    
    $footerText =~ s/<!--#MOST_RECENT_DOCUMENT_LIST-->/$mostRecentList/;





    print $footerText;
}



##
# Generates the login form.
#
# @param0 a message to display in the form.
##
sub generateLoginForm {
    ( my $message ) = @_;
 
    generateHeader( "login" );

    my $formText = readFileValue( "$htmlDirectory/loginForm.html" );

    $formText =~ s/<!--#MESSAGE-->/$message/;
    
    print $formText;


    generateFooter();
}



##
# Generates a form for creating a new user.
#
# @param0 a message to display in the form.
##
sub generateCreateUserForm {
    ( my $message ) = @_;
 
    generateHeader( "create new user" );

    my $formText = readFileValue( "$htmlDirectory/createUserForm.html" );

    $formText =~ s/<!--#MESSAGE-->/$message/;
    
    print $formText;


    generateFooter();
}



##
# Generates the feedback form.
#
# @param0 the currently logged-in user.
##
sub generateFeedbackForm {
    ( my $loggedInUser ) = @_;
 
    generateFullHeader( "feedback" );

    my $formText = readFileValue( "$htmlDirectory/feedbackForm.html" );
    
    print $formText;


    generateFullFooter( $loggedInUser );
}



##
# Generates a generic main page.
#
# @param0 the currently logged-in user.
##
sub generateMainPage {
    ( my $loggedInUser ) = @_;
 
    generateFullHeader( "main page" );

    my $pageText = readFileValue( "$htmlDirectory/mainPage.html" );

    $pageText =~ s/<!--#USER-->/$loggedInUser/;
    
    print $pageText;


    generateFullFooter( $loggedInUser );
}



##
# Generates a failed purchase page.
#
# @param0 the currently logged-in user.
# @param1 the owner of the document being purchased.
# @param2 the ID of the document being purchased.
# @param3 the amount necessary for the purchase.
##
sub generateFailedPurchasePage {
    ( my $loggedInUser, my $docOwner, my $docID, my $amount ) = @_;
    
    my $docTitle = tokenWord::documentManager::getDocTitle( $docOwner,
                                                            $docID );

    generateFullHeader( "document purchase failed" );

    my $pageText = readFileValue( "$htmlDirectory/failedPurchase.html" );

    $pageText =~ s/<!--#DOC_OWNER-->/$docOwner/g;
    $pageText =~ s/<!--#DOC_ID-->/$docID/g;
    $pageText =~ s/<!--#DOC_TITLE-->/$docTitle/g;
    $pageText =~ s/<!--#AMOUNT_NEEDED-->/$amount/g;
    
    print $pageText;


    generateFullFooter( $loggedInUser );
}



##
# Generates a form for creating a document.
#
# @param0 the currently logged-in user.
# @param1 1 to show a document preview, or 0 otherwise.
# @param2 the preview rendered text for this document.
# @param3 the abstract document representation to fill
#   the creation text box with.
# @param4 1 to check the spellCheck checkbox by default, or 0 to uncheck it.
##
sub generateCreateDocumentForm {
    ( my $loggedInUser,
      my $showPreview, my $docTextPreview, 
      my $abstractDocPrefill,
      my $spellCheckOn ) = @_;

    generateFullHeader( "create document" );

    my $formText = readFileValue( "$htmlDirectory/createDocumentForm.html" );
    
    if( not $showPreview ) {

        $formText =~ s/<!--#ABSTRACT_DOC_PREFILL-->//g;
        
    }
    else {
        my $previewBlockText = 
            readFileValue( "$htmlDirectory/documentPreview.html" );
        
        my @docElements = split( /\n\n/, $docTextPreview );
        
        my $docTitlePreview = shift( @docElements );

        $previewBlockText =~ s/<!--#DOC_TITLE-->/$docTitlePreview/g;
        $previewBlockText =~ s/<!--#DOC_OWNER-->/$loggedInUser/g;

        my @bodyTextElements = ();

        foreach $paragraph ( @docElements ) {
            push( @bodyTextElements, "$paragraph<BR><BR>\n" );
        }
    
        my $bodyText = join( "", @bodyTextElements );

        $previewBlockText =~ s/<!--#DOC_BODY-->/$bodyText/;

        
        # insert the preview block into the form
        $formText =~ s/<!--#DOCUMENT_PREVIEW-->/$previewBlockText/;
        
        # fill in the text area
        $formText =~ s/<!--#ABSTRACT_DOC_PREFILL-->/$abstractDocPrefill/;

    }
    
    if( $spellCheckOn ) {
        $formText =~ s/<!--#SPELLCHECK_ON-->/CHECKED/;
    }
    else {
        $formText =~ s/<!--#SPELLCHECK_ON-->//;
    }

    print $formText;


    generateFullFooter( $loggedInUser );
}




##
# Generates a page displaying a document.
#
# @param0 the currently logged-in user.
# @param1 the owner of the document to display.
# @param2 the ID of the document to display.
# @param3 the text to display.
# @param4 1 to display the document in quote mode, 0 to display
#   it in non-quote mode, 2 to display in region highlighted mode,
#   and 3 to display it in word highlighted mode.
##
sub generateDocPage {
    ( my $loggedInUser, my $docOwner, my $docID, 
      my $docText, my $modeFlag ) = @_;
    
    my @docElements = split( /\n\n/, $docText );

    my $docTitle = shift( @docElements );
    
    generateFullHeader( "document: $docTitle" );
    
    my $docDisplayText;
    
    if( $modeFlag == 0 ) {
        $docDisplayText = 
            readFileValue( "$htmlDirectory/documentDisplay.html" );
    }
    elsif( $modeFlag == 2 ) {
        $docDisplayText = 
            readFileValue( "$htmlDirectory/highlightDocumentDisplay.html" );
    }
    elsif( $modeFlag == 3 ) {
        $docDisplayText = 
            readFileValue( 
                    "$htmlDirectory/wordHighlightDocumentDisplay.html" );
    }
    else {
        $docDisplayText = 
            readFileValue( "$htmlDirectory/quoteDocumentDisplay.html" );
    }

    $docDisplayText =~ s/<!--#DOC_TITLE-->/$docTitle/g;
    $docDisplayText =~ s/<!--#DOC_OWNER-->/$docOwner/g;
    $docDisplayText =~ s/<!--#DOC_ID-->/$docID/g;

    my @bodyTextElements = ();

    foreach $paragraph ( @docElements ) {
        push( @bodyTextElements, "$paragraph<BR><BR>\n" );
    }
    
    my $bodyText = join( "", @bodyTextElements );

    $docDisplayText =~ s/<!--#DOC_BODY-->/$bodyText/;

    print $docDisplayText;

    generateFullFooter( $loggedInUser );
}



##
# Generates a page displaying a document in quote display mode.
#
# @param0 the currently logged-in user.
# @param1 the owner of the document to display.
# @param2 the ID of the document to display.
# @param4 an array of chunk regions in the document.
##
sub generateDocQuotesPage {
    ( my $loggedInUser, my $docOwner, my $docID, my @chunks ) = @_;
    

    # build text for this document with links for each quote

    my @textChunks = ();

    my $openBracketColor = "#00AF00";
    my $closeBracketColor = "#FF0000";

    foreach $chunk ( @chunks ) {
        
        my @chunkElements = 
            tokenWord::common::extractRegionComponents( $chunk );
        my $text = 
            tokenWord::chunkManager::getRegionText( @chunkElements );
                
        if( $chunk =~ /.*;.*/ ) {            
            # a chunk that quotes another doc
            # make a link around the chunk
            
            my $quotedOwner = $chunkElements[4];
            my $quotedID = $chunkElements[5];
            my $quotedOffset = $chunkElements[6];
            my $quotedLength = $chunkElements[3];

            my $fullText =
                "<FONT COLOR=$openBracketColor>[</FONT>".
                "<A HREF=\"tokenWord.pl?action=showDocument".
                "&docOwner=$quotedOwner".
                "&docID=$quotedID".
                "&highlightOffset=$quotedOffset".
                "&highlightLength=$quotedLength\">".
                "<FONT COLOR=#000000>$text</FONT></A>".
                "<FONT COLOR=$closeBracketColor>]</FONT>";
            
            push( @textChunks, $fullText ); 

        }
        else {
            # a pure chunk
            push( @textChunks, $text );
        }
        
    }
    
    my $fullDocText = join( "", @textChunks );

    # pass to doc display function for formatting
    generateDocPage( $loggedInUser, $docOwner, $docID, $fullDocText, 1 );
}



##
# Generates a page displaying a document in highlight  mode.
#
# @param0 the currently logged-in user.
# @param1 the owner of the document to display.
# @param2 the ID of the document to display.
# @param3 the text to display.
# @param4 the offset of the highlight.
# @param5 the length of the highlight. 
##
sub generateDocHighlightPage {
    ( my $loggedInUser, my $docOwner, my $docID, my $docText,
      my $highlightOffset, my $highlightLength ) = @_;
    

    my $textBeforeHighlight = substr( $docText, 0, $highlightOffset );
    my $textInHighlight = substr( $docText, $highlightOffset, 
                                  $highlightLength );
    my $textAfterHighlight = substr( $docText, 
                                     $highlightOffset + $highlightLength );
    
    
    my $highlightColor= "#FF0000";

    my @textParts = ( $textBeforeHighlight,
                      "<FONT COLOR=$highlightColor>",
                      $textInHighlight,
                      "</FONT>",
                      $textAfterHighlight );
    
    my $fullDocText = join( "", @textParts );


    # pass to doc display function for formatting
    generateDocPage( $loggedInUser, $docOwner, $docID, $fullDocText, 2 );
}



##
# Generates user quote list.
#
# @param0 the currently logged-in user.
# @param1 an array of quote regions to display.
##
sub generateQuoteListPage {
    ( my $loggedInUser, my @quotes ) = @_;

    generateFullHeader( "quote list" );
    
    print "<CENTER><TABLE WIDTH=75% BORDER=0><TR><TD>\n";

    if( scalar( @quotes ) > 0 ) {
        print "<H1>quotes:</H1>\n";
    
        print "<TABLE CELLPADDING=5 BORDER=1>\n";
        
        print "<TR><TD>quote number</TD><TD>quote</TD></TR>\n";

        my $quoteCounter = 0;
        foreach $quote ( @quotes ) {
            print "<TR><TD VALIGN=TOP>&#60;q $quoteCounter&#62;</TD>";
            print "<TD>\n";
            
            my @components = extractRegionComponents( $quote );
            my $docOwner = $components[0];
            my $docID =  $components[1];
            my $offset =  $components[2];
            my $length = $components[3];
            my $docTitle = tokenWord::documentManager::getDocTitle( $docOwner,
                                                                    $docID );

            print "from $docOwner\'s ";
            print "<A HREF=\"tokenWord.pl?action=showDocument";
            print "&docOwner=$docOwner&docID=$docID";
            print "&highlightOffset=$offset&highlightLength=$length";
            print "\">$docTitle</A>:<BR><BR>";

            my $quoteText = tokenWord::quoteClipboard::renderQuoteText( 
                                                              $loggedInUser,
                                                              $quoteCounter );
            
            my @quoteParagraphs = split( /\n\n/, $quoteText );
            
            foreach $paragraph ( @quoteParagraphs ) {
                print "$paragraph<BR><BR>\n";
            }
            
            

            print "</TD></TR>\n";
            
            $quoteCounter += 1;
        }
    
        print "</TABLE>\n";
        
    }
    else {
        print "no quotes present\n";
    }
    print "</TD></TR></TABLE></CENTER>\n";
    
    generateFullFooter( $loggedInUser );
}



##
# Generates a list of documents quoting a document.
#
# @param0 the currently logged-in user.
# @param1 the owner of the quoted document.
# @param2 the ID of the quoted document.
# @param3 an array of regions of the quoting documents.
##
sub generateQuotingDocumentListPage {
    ( my $loggedInUser, my $docOwner, my $docID, my @quotingDocs ) = @_;
    
    generateFullHeader( "quoting documents" );
    
    my $docTitle = tokenWord::documentManager::getDocTitle( $docOwner,
                                                            $docID );
    
    my @quoteListParts = ();
    
    # add the head of the list
    push( @quoteListParts, "<TABLE BORDER=0>" );

    foreach $quotingDoc ( @quotingDocs ) {
        my @components = 
            tokenWord::common::extractRegionComponents( $quotingDoc );
        
        my $owner = $components[0];
        my $id = $components[1];
        my $quoteLength = $components[3];

        my $title = tokenWord::documentManager::getDocTitle( $owner, $id );
        
        push( @quoteListParts, "<TR><TD>$owner\'s</TD><TD><A HREF=\"tokenWord.pl?action=showDocument&docOwner=$owner&docID=$id\">$title</A></TD><TD>[$quoteLength characters quoted]</TD></TR>\n" );
    }
    
    if( scalar( @quotingDocs ) == 0 ) {
        push( @quoteListParts, "<TR><TD>none</TD></TR>\n" );
    }

    # add the foot of the list
    push( @quoteListParts, "</TABLE>" );


    my $quoteList = join( "", @quoteListParts );


    my $pageText = readFileValue( "$htmlDirectory/quotingDocumentList.html" );

    $pageText =~ s/<!--#DOC_OWNER-->/$docOwner/g;
    $pageText =~ s/<!--#DOC_ID-->/$docID/g;
    $pageText =~ s/<!--#DOC_TITLE-->/$docTitle/g;
    $pageText =~ s/<!--#QUOTING_DOCUMENTS-->/$quoteList/g;
    
    print $pageText;
    

    generateFullFooter( $loggedInUser );
}



##
# Generates a form for extracting a quote.
#
# @param0 the currently logged-in user.
# @param1 the owner of the document to extract the quote from.
# @param2 the ID of the document to extract the quote from.
# @param3 the text of the document to extract the quote from.
# @param4 a status message to display
##
sub generateExtractQuoteForm {
    ( my $loggedInUser, my $docOwner, 
      my $docID, my $docText, my $message ) = @_;

    generateFullHeader( "extract quote" );

    my $formText = readFileValue( "$htmlDirectory/extractQuoteForm.html" );

    $formText =~ s/<!--#DOC_OWNER-->/$docOwner/;
    $formText =~ s/<!--#DOC_ID-->/$docID/;
    $formText =~ s/<!--#DOC_TEXT-->/$docText/;
    $formText =~ s/<!--#MESSAGE-->/$message/;
    
    print $formText;


    generateFullFooter( $loggedInUser );
}



##
# Generates a page of search results.
#
# @param0 the currently logged-in user.
# @param1 the search term string.
# @param2 the number of documents searched.
# @param3 the search time as a formatted string.
# @param4 the list of < user, docID > result strings.
##
sub generateSearchResultsPage {
    ( my $loggedInUser, my $searchTerms, my $docCount, my $searchTime, 
      my @results ) = @_;
 
    generateFullHeader( "search results: $searchTerms" );

    my $pageText = readFileValue( "$htmlDirectory/searchResults.html" );

    $pageText =~ s/<!--#SEARCH_TERMS-->/$searchTerms/;
    $pageText =~ s/<!--#DOC_COUNT-->/$docCount/;
    $pageText =~ s/<!--#SEARCH_TIME-->/$searchTime/;
    
    my @terms = split( /\s+/, $searchTerms );
    my $urlSafeTerms = join( "+", @terms );


    my @resultListParts = ();
    
    # add the head of the list
    push( @resultListParts, "<TABLE BORDER=0>" );

    foreach $result ( @results ) {
        my @components = 
            tokenWord::common::extractRegionComponents( $result );
        
        my $owner = $components[0];
        my $id = $components[1];

        my $title = tokenWord::documentManager::getDocTitle( $owner, $id );
        
        my $quoteCount = 
          tokenWord::documentManager::getQuoteCount( $owner, $id );

        push( @resultListParts, 
              "<TR><TD>$owner\'s</TD><TD><A HREF=\"tokenWord.pl?".
              "action=showDocument&docOwner=$owner&docID=$id".
              "&highlightWords=$urlSafeTerms\">".
              "$title</A></TD><TD>[$quoteCount]</TD></TR>\n" );
    }
    
    if( scalar( @results ) == 0 ) {
        push( @resultListParts, "<TR><TD>none</TD></TR>\n" );
    }

    # add the foot of the list
    push( @resultListParts, "</TABLE>" );


    my $resultList = join( "", @resultListParts );

    $pageText =~ s/<!--#RESULTS_LIST-->/$resultList/;

    print $pageText;


    generateFullFooter( $loggedInUser );
}



##
# Generates a page confirming a deposit action.
#
# @param0 the currently logged-in user.
# @param1 the token count to deposit.
# @param2 the dollar amount of the deposit.
# @param3 the net dollar payment, including fees.
# @param4 the paypal email to use.
##
sub generateDepositConfirmPage {          
    ( my $loggedInUser,
      my $tokenCount,
      my $dollarAmount,
      my $netDollarPayment,
      my $paypalEmail ) = @_;
    
    generateFullHeader( "confirm token deposit" );

    my $pageText = readFileValue( "$htmlDirectory/depositConfirm.html" );

    $pageText =~ s/<!--#DEPOSIT_TOKENS-->/$tokenCount/g;
    $pageText =~ s/<!--#DEPOSIT_DOLLARS-->/$dollarAmount/g;
    $pageText =~ s/<!--#PAYPAL_EMAIL-->/$paypalEmail/g;
    $pageText =~ s/<!--#NET_PAYMENT_DOLLARS-->/$netDollarPayment/g;
    $pageText =~ s/<!--#USERNAME-->/$loggedInUser/g;
    
    print $pageText;


    generateFullFooter( $loggedInUser );

}



##
# Generates a page confirming a withdraw action.
#
# @param0 the currently logged-in user.
# @param1 the token count to witdraw.
# @param2 the dollar amount of the witdrawl.
# @param3 the net dollar refund, including fees.
# @param4 the paypal email to use.
##
sub generateWithdrawConfirmPage {          
    ( my $loggedInUser,
      my $tokenCount,
      my $dollarAmount,
      my $netDollarRefund,
      my $paypalEmail ) = @_;
    
    generateFullHeader( "confirm token withdrawl" );

    my $pageText = readFileValue( "$htmlDirectory/withdrawConfirm.html" );

    $pageText =~ s/<!--#WITHDRAW_TOKENS-->/$tokenCount/g;
    $pageText =~ s/<!--#WITHDRAW_DOLLARS-->/$dollarAmount/g;
    $pageText =~ s/<!--#PAYPAL_EMAIL-->/$paypalEmail/g;
    $pageText =~ s/<!--#NET_REFUND_DOLLARS-->/$netDollarRefund/g;
    
    print $pageText;


    generateFullFooter( $loggedInUser );

}




##
# Generates a failed withdraw page.
#
# @param0 the currently logged-in user.
##
sub generateFailedWithdrawPage {
    ( my $loggedInUser ) = @_;
    
    generateFullHeader( "withdrawl failed" );

    my $pageText = readFileValue( "$htmlDirectory/failedWithdraw.html" );

    print $pageText;


    generateFullFooter( $loggedInUser );
}



##
# Generates an error page.
#
# @param0 the currently logged-in user.
# @param1 the error message to display 
##
sub generateErrorPage {
    ( my $loggedInUser, my $message ) = @_;
    
    generateFullHeader( "error" );

    print "<CENTER>$message</CENTER>";

    generateFullFooter( $loggedInUser );
}



# end of package
1;
