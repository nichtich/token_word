package tokenWord::htmlGenerator;

#
# Modification History
#
# 2003-January-8   Jason Rohrer
# Created.
#


use tokenWord::common;
use tokenWord::userManager;
use tokenWord::chunkManager;



sub generateHeader {
    ( my $title ) = @_;

    my $headerText = readFileValue( "$htmlDirectory/header.html" );

    $headerText =~ s/<!--#TITLE-->/$title/;
    
    print $headerText;
}



sub generateFooter {

    my $footerText = readFileValue( "$htmlDirectory/footer.html" );

    print $footerText;
}




sub generateFullHeader {
    ( my $title ) = @_;

    generateHeader( $title );

    my $headerText = readFileValue( "$htmlDirectory/fullHeader.html" );
    
    print $headerText;
}



sub generateFullFooter {
    ( my $loggedInUser ) = @_;
    
    generateFooter();

    my $balance = tokenWord::userManager::getBalance( $loggedInUser );

    
    my $footerText = readFileValue( "$htmlDirectory/fullFooter.html" );
    
    $footerText =~ s/<!--#USER-->/$loggedInUser/;
    $footerText =~ s/<!--#TOKEN_BALANCE-->/$balance/;

    print $footerText;
}



sub generateLoginForm {
    ( my $message ) = @_;
 
    generateHeader( "login" );

    my $formText = readFileValue( "$htmlDirectory/loginForm.html" );

    $formText =~ s/<!--#MESSAGE-->/$message/;
    
    print $formText;


    generateFooter();
}



sub generateCreateUserForm {
    ( my $message ) = @_;
 
    generateHeader( "create new user" );

    my $formText = readFileValue( "$htmlDirectory/createUserForm.html" );

    $formText =~ s/<!--#MESSAGE-->/$message/;
    
    print $formText;


    generateFooter();
}



sub generateMainPage {
    ( my $user ) = @_;
 
    generateFullHeader( "main page" );

    my $pageText = readFileValue( "$htmlDirectory/mainPage.html" );

    $pageText =~ s/<!--#USER-->/$user/;
    
    print $pageText;


    generateFullFooter( $user );
}



sub generateCreateDocumentForm {
    ( my $user ) = @_;

    generateFullHeader( "create document" );

    my $formText = readFileValue( "$htmlDirectory/createDocumentForm.html" );
    
    print $formText;


    generateFullFooter( $user );
}


sub generateDocPage {
    ( my $user, my $docOwner, my $docID, my $docText, my $quoteFlag ) = @_;
    
    my @docElements = split( /\n\n/, $docText );

    my $docTitle = shift( @docElements );
    
    generateFullHeader( "document: $docTitle" );
    
    my $docDisplayText;
    
    if( not $quoteFlag ) {
        $docDisplayText = 
            readFileValue( "$htmlDirectory/documentDisplay.html" );
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

    generateFullFooter( $user );
}



sub generateDocQuotesPage {
    ( my $user, my $docOwner, my $docID, my @chunks ) = @_;
    

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

            my $fullText =
                "<FONT COLOR=$openBracketColor>[</FONT>".
                "<A HREF=\"tokenWord.pl?action=showDocument".
                "&docOwner=$quotedOwner".
                "&docID=$quotedID\">".
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
    generateDocPage( $user, $docOwner, $docID, $fullDocText, 1 );
}



sub generateQuoteListPage {
    ( my $user, my @quotes ) = @_;

    generateFullHeader( "quote list" );
    
    print "<CENTER><TABLE WIDTH=75% BORDER=0><TR><TD>\n";

    if( scalar( @quotes ) > 0 ) {
        print "<H1>Quotes:</H1>\n";
    
        print "<TABLE CELLPADDING=5 BORDER=1>\n";
        
        print "<TR><TD>quote number</TD><TD>quote</TD></TR>\n";

        my $quoteCounter = 0;
        foreach $quote ( @quotes ) {
            print "<TR><TD>&#60;q $quoteCounter&#62;</TD>";
            print "<TD>\n";

            my @quoteElements = split( /\n\n/, $quote );
            
            foreach $paragraph ( @quoteElements ) {
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
    
    generateFullFooter( $user );
}



sub generateExtractQuoteForm {
    ( my $user, my $docOwner, my $docID, my $docText ) = @_;

    generateFullHeader( "extract quote" );

    my $formText = readFileValue( "$htmlDirectory/extractQuoteForm.html" );

    $formText =~ s/<!--#DOC_OWNER-->/$docOwner/;
    $formText =~ s/<!--#DOC_ID-->/$docID/;
    $formText =~ s/<!--#DOC_TEXT-->/$docText/;
    
    print $formText;


    generateFullFooter( $user );
}



# end of package
1;
